import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:quiver/iterables.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wifi_direct_share/data_classes/discovering_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:wifi_direct_share/data_classes/media-file.dart';
import 'package:wifi_direct_share/data_classes/media-transaction.dart';
import 'package:wifi_direct_share/data_classes/percentage_of_io.dart';
import 'package:wifi_direct_share/data_classes/refresh_function.dart';
import 'package:wifi_direct_share/data_classes/show_io_percentage.dart';
import 'package:wifi_direct_share/globals.dart';
import 'package:device_info/device_info.dart';

class WifiDirectBody extends StatefulWidget {
  WifiDirectBody({Key? key}) : super(key: key);

  @override
  _WifiDirectBodyState createState() => _WifiDirectBodyState();
}

class _WifiDirectBodyState extends State<WifiDirectBody> {
  int receptionCounter = 0;

  List<int> tempBufferToWriteOn = <int>[];
  String tempFileNameBeingReceived = "";

  HashSet<Device> devices = HashSet<Device>(equals: (device1, device2) {
    return device1.deviceId == device2;
  });
  HashSet<Device> connectedDevices =
      HashSet<Device>(equals: (device1, device2) {
    return device1.deviceId == device2;
  });
  late StreamSubscription? subscription;
  late StreamSubscription? receivedDataSubscription;

  bool isInit = false;

  //connect to a peer
  bool _isConnected = false;
  bool _isHost = false;
  String _deviceAddress = "";

  bool _registered = false;

  Device? _tempConnectedDevice;

  // reception Data
  int totalBytesToReceive = 0;
  int totalBytesReceived = 0;

  //awaiting send
  MediaTransaction? transactionAwaitingSend;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Color.fromRGBO(20, 20, 20, 1.0),
          border: Border.all(
            color: Colors.grey[850]!,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: ListView.separated(
          itemBuilder: (context, index) {
            return ListTile(
              leading: _getDeviceIcon(devices.elementAt(index)),
              title: Text(
                devices.elementAt(index).deviceName,
                style: connectedDevices.length > 0 &&
                        connectedDevices.contains(devices.elementAt(index))
                    ? TextStyle(color: Colors.blue[400], fontSize: 18)
                    : Theme.of(context).textTheme.bodyText2,
              ),
              subtitle: connectedDevices.length > 0 &&
                      connectedDevices.contains(devices.elementAt(index))
                  ? Text(
                      "Tap here to disconnect",
                      style: Theme.of(context).textTheme.subtitle1,
                    )
                  : null,
              onTap: () async {
                Device device = devices.elementAt(index);
                switch (device.state) {
                  case SessionState.notConnected:
                    nearbyService!.invitePeer(
                      deviceID: device.deviceId,
                      deviceName: device.deviceName,
                    );
                    MediaTransaction transaction = MediaTransaction(
                        await _getMediaFiles(context
                            .read<Map<String, dynamic>>()["SharedFiles"]));
                    _requestSend(device, transaction);
                    break;
                  case SessionState.connected:
                    nearbyService!.disconnectPeer(deviceID: device.deviceId);
                    context.read<PercentageOfIO>().value = 0.0;
                    context.read<ShowPercentageOfIO>().value = false;
                    break;
                  case SessionState.connecting:
                    break;
                }
              },
            );
          },
          separatorBuilder: (context, index) {
            return Divider(color: Colors.grey[800]);
          },
          itemCount: devices.length),
    );
  }

  @override
  void dispose() {
    subscription!.cancel();
    receivedDataSubscription!.cancel();
    nearbyService!.stopBrowsingForPeers();
    nearbyService!.stopAdvertisingPeer();
    super.dispose();
  }

  String getStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return "disconnected";
      case SessionState.connecting:
        return "waiting";
      default:
        return "connected";
    }
  }

  Icon? _getDeviceIcon(Device device) {
    return const Icon(
      Icons.phone_android,
      color: Colors.white,
    );
  }

  Future<List<MediaFile>> _getMediaFiles(List<SharedMediaFile> list) async {
    List<MediaFile> toReturn = <MediaFile>[];
    list.forEach((element) {
      toReturn.add(MediaFile(
          element.path.split("/").last,
          element.path.substring(element.path.lastIndexOf(".") + 1),
          File(element.path).lengthSync(),
          File(element.path).readAsBytesSync()));
    });
    return toReturn;
  }

  void init() async {
    String devInfo = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService!.init(
        serviceType: 'mpconn',
        deviceName: devInfo,
        strategy: Strategy.Wi_Fi_P2P,
        callback: (isRunning) async {
          if (isRunning) {
            discover();
          }
        });
    subscription =
        nearbyService!.stateChangedSubscription(callback: (devicesList) {
      devicesList.forEach((element) {
        print(
            " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

        if (Platform.isAndroid) {
          if (element.state == SessionState.connected) {
            nearbyService!.stopBrowsingForPeers();
          } else {
            nearbyService!.startBrowsingForPeers();
          }
        }
      });

      setState(() {
        devices.clear();
        devices.addAll(devicesList);
        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());
      });
    });

    receivedDataSubscription = nearbyService!
        .dataReceivedSubscription(callback: dataReceivedSubscriptionCallback);
  }

  dataReceivedSubscriptionCallback(data) async {
    data["message"] = jsonDecode(data["message"]);

    if (data["message"]["type"].contains("TRANSACTION_ACCEPTED")) {
      //accepted and sending to two
      _sendData(data["deviceId"], transactionAwaitingSend!);
    } else if (data["message"]["type"].contains("TRANSACTION_HEADER")) {
      //receiving request from one, accepting
      context.read<PercentageOfIO>().value = 0.0;
      context.read<ShowPercentageOfIO>().value = true;
      totalBytesToReceive = data["message"]["totalBytes"];
      (context.read<Map<String, dynamic>>()["ReceivedFiles"] as List<File>)
          .clear();
      nearbyService!.sendMessage(
          data["deviceId"],
          jsonEncode({
            "type": "TRANSACTION_ACCEPTED",
          }));
    } else if (data["message"]["type"].contains("PACKET")) {
      //receiving data from one
      if (data["message"]["status"].contains("BEGIN") ||
          data["message"]["status"].contains("MID")) {
        if (data["message"]["status"].contains("BEGIN")) {
          tempFileNameBeingReceived = data["message"]["fileID"];
        }
        List<int> dataInts =
            (jsonDecode(data["message"]["data"]) as List).cast<int>();
        totalBytesReceived += dataInts.length;
        context.read<PercentageOfIO>().value =
            totalBytesReceived / totalBytesToReceive;
        tempBufferToWriteOn.addAll(dataInts);
        // print("dataReceivedSubscription: ${jsonEncode(data['message'])}");
      }
      if (data["message"]["status"].contains("END")) {
        if (tempBufferToWriteOn.length > 0) {
          try {
            File file = File(internalStorageDownloadsFolderPath +
                "/" +
                tempFileNameBeingReceived);
            if (!(await file.exists())) {
              await file.create();
            }
            await file.writeAsBytes(
              tempBufferToWriteOn,
              mode: FileMode.writeOnly,
            );
            (context.read<Map<String, dynamic>>()["ReceivedFiles"]
                    as List<File>)
                .add(file);
            context.read<RefreshFunction>().func!();
            tempBufferToWriteOn.clear();
          } catch (ex) {
            print(ex);
          } finally {
            receivedDataSubscription!.cancel();
            receivedDataSubscription = nearbyService!.dataReceivedSubscription(
                callback: dataReceivedSubscriptionCallback);
          }
        }
      }
    } else if (data["message"]["type"].contains("TRANSACTION_TRAILER")) {
      //receiving data from one
      totalBytesToReceive = 0;
      totalBytesReceived = 0;
      // context.read<ShowPercentageOfIO>().value = false;
      // context.read<PercentageOfIO>().value = 0.0;
    }
  }

  _requestSend(Device device, MediaTransaction transaction) {
    int totalBytes = 0;
    transaction.data!.forEach((element) {
      totalBytes += element.file!.length;
    });

    transactionAwaitingSend = transaction;

    nearbyService!.sendMessage(
        device.deviceId,
        jsonEncode({
          "type": "TRANSACTION_HEADER",
          "totalFiles": transaction.data!.length,
          "totalBytes": totalBytes,
        }));
  }

  _sendData(String deviceId, MediaTransaction transaction) {
    context.read<ShowPercentageOfIO>().value = true;
    context.read<PercentageOfIO>().value = 0;
    int totalBytes = 0;
    transaction.data!.forEach((element) {
      totalBytes += element.file!.length;
    });
    int totalBeingSent = 0;

    // await Future.delayed(Duration(milliseconds: 200));

    transaction.data!.forEach((element) {
      int totalPacketsToSend = (element.size! / PACKET_FRAGMENT).ceil();
      List<List<int>> partitions =
          partition(element.file!, PACKET_FRAGMENT).toList();

      for (int i = 0; i < totalPacketsToSend; i++) {
        String status = "";
        if (totalPacketsToSend == 1) {
          status = "BEGIN|END";
        } else if (i == 0) {
          status = "BEGIN";
        } else if (i == totalPacketsToSend - 1) {
          status = "MID|END";
        } else {
          status = "MID";
        }
        dynamic data = jsonEncode(partitions[i]);
        totalBeingSent += partitions[i].length;

        nearbyService!.sendMessage(
            deviceId,
            jsonEncode({
              "type": "PACKET",
              "sequenceIndex": "$i / $totalPacketsToSend",
              "fileID": element.name!,
              "status": status,
              "data": data,
            }));
      }
      context.read<PercentageOfIO>().value = totalBeingSent / totalBytes;
    });
    // await Future.delayed(Duration(milliseconds: 200));
    nearbyService!.sendMessage(
        deviceId,
        jsonEncode({
          "type": "TRANSACTION_TRAILER",
          "status": "END",
        }));
  }
}
