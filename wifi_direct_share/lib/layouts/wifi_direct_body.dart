import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_p2p/flutter_p2p.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_p2p/gen/protos/protos.pb.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wifi_direct_share/data_classes/discovering_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:wifi_direct_share/data_classes/media-file.dart';
import 'package:wifi_direct_share/data_classes/media-transaction.dart';
import 'package:wifi_direct_share/globals.dart';

class WifiDirectBody extends StatefulWidget {
  WifiDirectBody({Key? key}) : super(key: key);

  @override
  _WifiDirectBodyState createState() => _WifiDirectBodyState();
}

class _WifiDirectBodyState extends State<WifiDirectBody>
    with WidgetsBindingObserver {
  //peers
  List<WifiP2pDevice> _peers = [];

  // connected device
  WifiP2pDevice? _connectedDevice;
  WifiP2pDevice? _tempConnectedDevice;

  //connect to a peer
  bool _isConnected = false;
  bool _isHost = false;
  String _deviceAddress = "";

  //sockets
  P2pSocket? _socket;

  bool _registered = false;
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      _registered = true;
      _register();
    }
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
              leading: _getDeviceIcon(_peers[index]),
              title: Text(
                _peers[index].deviceName,
                style: _connectedDevice != null &&
                        _connectedDevice!.deviceAddress ==
                            _peers[index].deviceAddress
                    ? TextStyle(color: Colors.blue[400], fontSize: 18)
                    : Theme.of(context).textTheme.bodyText2,
              ),
              subtitle: _connectedDevice != null &&
                      _connectedDevice!.deviceAddress ==
                          _peers[index].deviceAddress
                  ? Text(
                      "Tap here to disconnect",
                      style: Theme.of(context).textTheme.subtitle1,
                    )
                  : null,
              onTap: () async {
                if (_connectedDevice != null &&
                    _connectedDevice!.deviceAddress ==
                        _peers[index].deviceAddress) {
                  bool result = await _disconnect();
                  if (result) {
                    _connectedDevice = null;
                  }
                  // bool result = await FlutterP2p.cancelConnect(_peers[index]);
                  // if (result) {
                  //   setState(() {
                  //     _connectedDevice = null;
                  //   });
                  // }
                } else {
                  bool result = await FlutterP2p.connect(_peers[index]);
                  if (result) {
                    setState(() {
                      _tempConnectedDevice = _peers[index];
                    });
                  }
                }
              },
            );
          },
          separatorBuilder: (context, index) {
            return Divider(color: Colors.grey[800]);
          },
          itemCount: _peers.length),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Icon? _getDeviceIcon(WifiP2pDevice device) {
    if (device.primaryDeviceType.startsWith("7-")) {
      if (device.primaryDeviceType.endsWith("-0")) {
        return const Icon(
          Icons.laptop,
          color: Colors.white,
        );
      } else if (device.primaryDeviceType.endsWith("-1")) {
        return const Icon(
          Icons.tv,
          color: Colors.white,
        );
      }
    } else if (device.primaryDeviceType.startsWith("10-")) {
      return const Icon(
        Icons.phone_android,
        color: Colors.white,
      );
    }
    return const Icon(
      Icons.device_unknown,
      color: Colors.white,
    );
  }

  FutureOr<bool> _checkPermission() async {
    // return true;
    if (!await FlutterP2p.isLocationPermissionGranted()) {
      await FlutterP2p.requestLocationPermission();
      return false;
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop handling events when the app doesn't run to prevent battery draining

    if (state == AppLifecycleState.resumed) {
      _register();
    } else if (state == AppLifecycleState.paused) {
      _unregister();
    }
  }

  List<StreamSubscription> _subscriptions = [];

  void _register() async {
    if (!await _checkPermission()) {
      return;
    }
    _subscriptions.add(FlutterP2p.wifiEvents.stateChange.listen((change) {
      print(change);
    }));

    _subscriptions
        .add(FlutterP2p.wifiEvents.connectionChange.listen((change) async {
      if (change.networkInfo.detailedState.name == "CONNECTED") {
        setState(() {
          _isConnected = change.networkInfo.isConnected;
          _isHost = change.wifiP2pInfo.isGroupOwner;
          _deviceAddress = change.wifiP2pInfo.groupOwnerAddress;
          _connectedDevice = _tempConnectedDevice;
          _tempConnectedDevice = null;
        });
        if (context.read<Map<String, dynamic>>()["SharedFiles"].length > 0) {
          // await _connectToPort();

          List<MediaFile> toSend = await _getMediaFiles(
              (context.read<Map<String, dynamic>>()["SharedFiles"]
                  as List<SharedMediaFile>));
          MediaTransaction transaction = new MediaTransaction(toSend);
          await _openPortAndSend(transaction);
        } else {
          _connectToPort();
        }
      } else if (change.networkInfo.detailedState.name == "DISCONNECTED") {
        setState(() {
          _connectedDevice = null;

          _isConnected = false;
          _isHost = false;
          _deviceAddress = "";
        });
      }
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      print(change.status.name == "CONNECTED");
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.peersChange.listen((change) {
      setState(() {
        _peers = change.devices;
        context.read<DiscoveringChangeNotifier>().value = false;
        bool elementConnected = false;
        _peers.forEach((element) {
          if (element.status.name == "CONNECTED") {
            _connectedDevice = element;
            elementConnected = true;
          }
        });
        if (!elementConnected && _connectedDevice != null) {
          _connectedDevice = null;

          _isConnected = false;
          _isHost = false;
          _deviceAddress = "";
        }
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      setState(() {
        if (!change.isDiscovering)
          context.read<DiscoveringChangeNotifier>().value = false;
      });
    }));

    FlutterP2p
        .register(); // Register to the native events which are send to the streams above
    _discover();
  }

  void _unregister() {
    _subscriptions.forEach(
        (subscription) => subscription.cancel()); // Cancel subscriptions
    FlutterP2p.unregister(); // Unregister from native events
  }

  Future _discover() async {
    context.read<DiscoveringChangeNotifier>().value = true;
    await FlutterP2p.discoverDevices();
  }

  Future<bool> _disconnect() async {
    return await FlutterP2p.removeGroup();
  }

  Future _openPortAndSend(MediaTransaction file) async {
    var socket = await FlutterP2p.openHostPort(PORT);
    setState(() {
      _socket = socket;
    });

    await _socket!.write(Uint8List.fromList(file.toJson().codeUnits));
    // socket.inputStream.listen((data) {
    //   var msg = String.fromCharCodes(data.data);
    //   buffer += msg;

    //   if (data.dataAvailable == 0) {
    //     Fluttertoast.showToast(msg: "Data Received: $buffer");
    //     buffer = "";
    //   }
    // });

    // Write data to the client using the _socket.write(UInt8List) or `_socket.writeString("Hello")` method

    print("_openPort done");

    // accept a connection on the created socket
    // await FlutterP2p.acceptPort(PORT);
    print("_accept done");
  }

  _connectToPort() async {
    var socket = await FlutterP2p.connectToHost(
      _deviceAddress, // see above `Connect to a device`
      PORT,
      timeout: 100000, // timeout in milliseconds (default 500)
    );

    setState(() {
      _socket = socket;
    });

    Uint8List? buffer;
    MediaTransaction? transaction;
    socket.inputStream.listen((data) {
      if (buffer == null)
        buffer = Uint8List.fromList(data.data);
      else {
        buffer!.addAll(data.data);
      }

      if (data.dataAvailable == 0) {
        transaction = MediaTransaction.fromUint8List(buffer!);
        buffer = null;
      }
    });

    print(transaction!);

    // Write data to the host using the _socket.write(UInt8List) or `_socket.writeString("Hello")` method

    print("_connectToPort done");
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
}
