import 'dart:async';
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

  List<Device> devices = [];
  List<Device> connectedDevices = [];
  late StreamSubscription? subscription;
  late StreamSubscription? receivedDataSubscription;

  bool isInit = false;

  //connect to a peer
  bool _isConnected = false;
  bool _isHost = false;
  String _deviceAddress = "";

  bool _registered = false;

  Device? _tempConnectedDevice;
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
              leading: _getDeviceIcon(devices[index]),
              title: Text(
                devices[index].deviceName,
                style: connectedDevices.length > 0 &&
                        connectedDevices.contains(devices[index])
                    ? TextStyle(color: Colors.blue[400], fontSize: 18)
                    : Theme.of(context).textTheme.bodyText2,
              ),
              subtitle: connectedDevices.length > 0 &&
                      connectedDevices.contains(devices[index])
                  ? Text(
                      "Tap here to disconnect",
                      style: Theme.of(context).textTheme.subtitle1,
                    )
                  : null,
              onTap: () async {
                Device device = devices[index];
                switch (device.state) {
                  case SessionState.notConnected:
                    nearbyService!.invitePeer(
                      deviceID: device.deviceId,
                      deviceName: device.deviceName,
                    );
                    MediaTransaction transaction = MediaTransaction(
                        await _getMediaFiles(context
                            .read<Map<String, dynamic>>()["SharedFiles"]));
                    _sendData(device, transaction);
                    break;
                  case SessionState.connected:
                    nearbyService!.disconnectPeer(deviceID: device.deviceId);
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

    receivedDataSubscription =
        nearbyService!.dataReceivedSubscription(callback: (data) {
      data["message"] = jsonDecode(data["message"]);
      if (tempFileNameBeingReceived == "") {
        tempFileNameBeingReceived = data["message"]["fileID"];
      }
      if (data["message"]["fileID"] == tempFileNameBeingReceived) {
        List<int> dataInts =
            (jsonDecode(data["message"]["data"]) as List).cast<int>();
        tempBufferToWriteOn.addAll(dataInts);
        print("dataReceivedSubscription: ${jsonEncode(data["message"])}");
      } else {
        if (tempBufferToWriteOn.length > 0) {
          File file = File(internalStorageDownloadsFolderPath +
              "/" +
              tempFileNameBeingReceived);
          file.createSync();
          file.writeAsBytesSync(tempBufferToWriteOn);
          
        }
        tempFileNameBeingReceived = data["message"]["fileID"];
      }
      receptionCounter++;
      // showToast(jsonEncode(data),
      //     context: context,
      //     axis: Axis.horizontal,
      //     alignment: Alignment.center,
      //     position: StyledToastPosition.bottom);
    });
  }

  _sendData(Device device, MediaTransaction transaction) {
    transaction.data!.forEach((element) {
      int totalToSend = (element.size! / PACKET_FRAGMENT).ceil();
      List<List<int>> partitions =
          partition(element.file!, PACKET_FRAGMENT).toList();

      for (int i = 0; i < totalToSend; i++) {
        nearbyService!.sendMessage(
            device.deviceId,
            jsonEncode({
              "fileID": element.name!,
              "data": jsonEncode(partitions[i]),
            }));
      }
    });
  }
}
