import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quiver/iterables.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';
import 'package:wifi_direct_share/data_classes/media_file.dart';
import 'package:wifi_direct_share/data_classes/media_transaction.dart';
import 'package:wifi_direct_share/data_classes/packet.dart';
import 'package:wifi_direct_share/data_classes/packet_enums.dart';
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
    return device1.deviceId == device2.deviceId;
  });
  HashSet<Device> connectedDevices =
      HashSet<Device>(equals: (device1, device2) {
    return device1.deviceId == device2.deviceId;
  });
  late StreamSubscription? subscription;
  late StreamSubscription? receivedDataSubscription;

  bool isInit = false;

  //connect to a peer
  bool _isConnected = false;
  bool _isHost = false;
  String _deviceAddress = "";

  bool _registered = false;

  // reception Data
  int totalBytesToReceive = 0;
  int totalBytesReceived = 0;

  //awaiting send
  MediaTransaction? _transactionAwaitingSend;
  int? _transactionCurrentSendingIndex;
  List<List<int>>? _partitionsCurrentlySending;
  int? _totalPacketsToSend;
  MediaFile? _fileCurrentlySending;

  Device? _tempConnectedDevice;
  bool _triggerSend = false;

  int _totalBytesBeingSent = 0;
  int _totalBytesToSend = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
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
                        connectedDevices
                            .map((e) => e.deviceId)
                            .contains(devices.elementAt(index).deviceId)
                    ? TextStyle(color: Colors.blue[400], fontSize: 18)
                    : Theme.of(context).textTheme.bodyText2,
              ),
              subtitle: connectedDevices.length > 0 &&
                      connectedDevices
                          .map((e) => e.deviceId)
                          .contains(devices.elementAt(index).deviceId)
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
                    _transactionAwaitingSend = transaction;
                    _tempConnectedDevice = device;
                    _triggerSend = true;
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
            discover(context);
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
      triggerSenRequest();
    });

    receivedDataSubscription = nearbyService!
        .dataReceivedSubscription(callback: dataReceivedSubscriptionCallback);
  }

  triggerSenRequest() {
    if (_triggerSend &&
        _tempConnectedDevice != null &&
        _transactionAwaitingSend != null &&
        _transactionAwaitingSend!.data!.length > 0) {
      _triggerSend = false;
      Future.delayed(Duration(seconds: 2), () {
        _requestSend(_tempConnectedDevice!);
      });
    }
  }

  dataReceivedSubscriptionCallback(data) async {
    Packet packet = Packet.fromJson(jsonDecode(data["message"]));

    if (packet.type == PacketType.TRANSACTION_ACCEPTED) {
      //accepted and sending to two
      _sendData(data["deviceId"], _transactionAwaitingSend!);
    } else if (packet.type == PacketType.NEXT_FILE) {
      await Future.delayed(Duration(milliseconds: 500));
      _sendNextFile(data["deviceId"]);
    } else if (packet.type == PacketType.NEXT_PACKET) {
      await Future.delayed(Duration(milliseconds: 100));
      _sendNextPacket(data["deviceId"]);
    } else if (packet.type == PacketType.TRANSACTION_HEADER) {
      if (await Permission.storage.request().isGranted) {
        //receiving request from one, accepting
        context.read<PercentageOfIO>().value = 0.0;
        context.read<ShowPercentageOfIO>().value = true;
        totalBytesToReceive = packet.totalBytes!;
        (context.read<Map<String, dynamic>>()["ReceivedFiles"] as List<File>)
            .clear();
        nearbyService!.sendMessage(data["deviceId"],
            Packet(type: PacketType.TRANSACTION_ACCEPTED).toJson());
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.black,
                actions: [
                  TextButton(
                      onPressed: () {
                        openAppSettings();
                        Navigator.of(context).pop();
                      },
                      child: Text("OK"))
                ],
                content: Text(
                    "This app needs storage access in order to receive files.\nPlease enable them in settings"),
              );
            });
      }
    } else if (packet.type == PacketType.PACKET) {
      //receiving data from one
      if (packet.status!.contains(PacketStatus.BEGIN) ||
          packet.status!.contains(PacketStatus.MID)) {
        if (packet.status!.contains(PacketStatus.BEGIN)) {
          tempFileNameBeingReceived = packet.fileID!;
        }
        List<int> dataInts = (jsonDecode(packet.data!) as List).cast<int>();
        totalBytesReceived += dataInts.length;
        context.read<PercentageOfIO>().value =
            totalBytesReceived / totalBytesToReceive;
        tempBufferToWriteOn.addAll(dataInts);
        // print("dataReceivedSubscription: ${jsonEncode(data['message'])}");
        nearbyService!.sendMessage(
            data["deviceId"], Packet(type: PacketType.NEXT_PACKET).toJson());
      }
      if (packet.status!.contains(PacketStatus.END)) {
        bool weirdAndroidException = false;
        if (tempBufferToWriteOn.length > 0) {
          try {
            do {
              String fileName = internalStorageDownloadsFolderPath +
                  "/" +
                  tempFileNameBeingReceived;
              if (weirdAndroidException) {
                int extensionIndex = tempFileNameBeingReceived.lastIndexOf(".");
                String newFileName =
                    tempFileNameBeingReceived.substring(0, extensionIndex) +
                        "_${DateTime.now().microsecond}" +
                        tempFileNameBeingReceived.substring(extensionIndex);
                fileName =
                    internalStorageDownloadsFolderPath + "/" + newFileName;
                weirdAndroidException = false;
              }
              File file = File(fileName);
              if (await file.exists()) {
                int addition = 0;
                int extensionIndex = -1;
                do {
                  addition++;
                  extensionIndex = tempFileNameBeingReceived.lastIndexOf(".");
                  String? newFileName;
                  if (extensionIndex == -1) {
                    newFileName = tempFileNameBeingReceived + " ($addition)";
                  } else {
                    newFileName =
                        tempFileNameBeingReceived.substring(0, extensionIndex) +
                            " ($addition)" +
                            tempFileNameBeingReceived.substring(extensionIndex);
                  }
                  file = File(
                      internalStorageDownloadsFolderPath + "/" + newFileName);
                } while (await file.exists());
              } else {
                try {
                  await file.create();
                } catch (ex) {
                  if (ex is FileSystemException &&
                      ex.osError!.errorCode == 17) {
                    weirdAndroidException = true;
                    continue;
                  }
                }
              }
              try {
                await file.writeAsBytes(
                  tempBufferToWriteOn,
                  mode: FileMode.writeOnly,
                );
              } catch (ex) {
                if (ex is FileSystemException && ex.osError!.errorCode == 17) {
                  weirdAndroidException = true;
                  continue;
                }
              }
              (context.read<Map<String, dynamic>>()["ReceivedFiles"]
                      as List<File>)
                  .add(file);
              context.read<RefreshFunction>().func!();
              tempBufferToWriteOn.clear();
            } while (weirdAndroidException);
          } catch (ex) {
            print(ex);
          } finally {
            await receivedDataSubscription!.cancel();
            receivedDataSubscription = nearbyService!.dataReceivedSubscription(
                callback: dataReceivedSubscriptionCallback);
            await Future.delayed(Duration(milliseconds: 500));
            nearbyService!.sendMessage(
                data["deviceId"], Packet(type: PacketType.NEXT_FILE).toJson());
          }
        }
      }
    } else if (packet.type == PacketType.TRANSACTION_TRAILER) {
      //receiving data from one
      totalBytesToReceive = 0;
      totalBytesReceived = 0;
      // context.read<ShowPercentageOfIO>().value = false;
      // context.read<PercentageOfIO>().value = 0.0;
    }
  }

  void _requestSend(Device device) {
    int totalBytes = 0;
    _transactionAwaitingSend!.data!.forEach((element) {
      totalBytes += element.file!.length;
    });

    nearbyService!.sendMessage(
        device.deviceId,
        Packet(
                type: PacketType.TRANSACTION_HEADER,
                totalFiles: _transactionAwaitingSend!.data!.length,
                totalBytes: totalBytes)
            .toJson());
  }

  _sendNextPacket(String deviceId) {
    if (_partitionsCurrentlySending != null ||
        _transactionAwaitingSend != null) {
      if (_partitionsCurrentlySending!.length > 0) {
        int currentSendingIndex =
            _totalPacketsToSend! - _partitionsCurrentlySending!.length;
        List<PacketStatus> status = [];
        if (_totalPacketsToSend == 1) {
          status.add(PacketStatus.BEGIN);
          status.add(PacketStatus.END);
        } else if (currentSendingIndex == 0) {
          status.add(PacketStatus.BEGIN);
        } else if (currentSendingIndex == _totalPacketsToSend! - 1) {
          status.add(PacketStatus.MID);
          status.add(PacketStatus.END);
        } else {
          status.add(PacketStatus.MID);
        }
        dynamic data = jsonEncode(_partitionsCurrentlySending![0]);
        _totalBytesBeingSent += _partitionsCurrentlySending![0].length;

        _partitionsCurrentlySending!.removeAt(0);

        nearbyService!.sendMessage(
            deviceId,
            Packet(
              type: PacketType.PACKET,
              sequenceIndex:
                  "${currentSendingIndex + 1} / ${_totalPacketsToSend!}",
              fileID: _fileCurrentlySending!.name!,
              status: status,
              data: data,
            ).toJson());
        context.read<PercentageOfIO>().value =
            _totalBytesBeingSent / _totalBytesToSend;
      }
    }
  }

  _sendNextFile(String deviceId) {
    if (_transactionAwaitingSend == null) {
      return;
    }
    if (_transactionAwaitingSend!.data!.length == 0) {
      _transactionAwaitingSend!.data!.forEach((element) {});
      nearbyService!.sendMessage(
          deviceId,
          Packet(
              type: PacketType.TRANSACTION_TRAILER,
              status: [PacketStatus.END]).toJson());
      _transactionAwaitingSend = null;
      receivedDataSubscription!.cancel();
      receivedDataSubscription = nearbyService!
          .dataReceivedSubscription(callback: dataReceivedSubscriptionCallback);
      return;
    }
    _fileCurrentlySending = _transactionAwaitingSend!.data![0];
    _transactionAwaitingSend!.data!.removeAt(0);
    _totalPacketsToSend =
        (_fileCurrentlySending!.size! / PACKET_FRAGMENT).ceil();
    _partitionsCurrentlySending =
        partition(_fileCurrentlySending!.file!, PACKET_FRAGMENT).toList();

    _sendNextPacket(deviceId);
  }

  _sendData(String deviceId, MediaTransaction transaction) async {
    _transactionCurrentSendingIndex = 0;
    context.read<ShowPercentageOfIO>().value = true;
    context.read<PercentageOfIO>().value = 0;

    transaction.data!.forEach((element) {
      _totalBytesToSend += element.file!.length;
    });

    // await Future.delayed(Duration(milliseconds: 200));
    _sendNextFile(deviceId);
  }
}
