import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_p2p/flutter_p2p.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_p2p/gen/protos/protos.pb.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WifiDirectBody extends StatefulWidget {
  WifiDirectBody({Key? key}) : super(key: key);

  @override
  _WifiDirectBodyState createState() => _WifiDirectBodyState();
}

class _WifiDirectBodyState extends State<WifiDirectBody>
    with WidgetsBindingObserver {
  //peers
  List<WifiP2pDevice> _peers = [];

  //connect to a peer
  bool _isConnected = false;
  bool _isHost = false;
  String _deviceAddress = "";

  //sockets
  P2pSocket? _socket;

  bool _isDiscovering = false;
  @override
  void initState() {
    _register();
    WidgetsBinding.instance!.addObserver(this);
    _runDiscoverLoop();
    super.initState();
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
        child: Column(children: [
          Visibility(
              visible: _isDiscovering, child: CircularProgressIndicator()),
          ListView.separated(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_peers[index].deviceName),
                );
              },
              separatorBuilder: (context, index) {
                return Divider(color: Colors.grey[800]);
              },
              itemCount: _peers.length),
        ]));
  }

  void _runDiscoverLoop() async {
    do {
      setState(() {
        _isDiscovering = true;
      });
      await _discover();
      setState(() {
        _isDiscovering = false;
      });
      sleep(Duration(seconds: 5));
    } while (true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  FutureOr<bool> _checkPermission() async {
    return true;
    // if (!await FlutterP2p.isLocationPermissionGranted()) {
    //   await FlutterP2p.requestLocationPermission();
    //   return false;
    // }
    // return true;
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
      // Handle wifi state change
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.connectionChange.listen((change) {
      setState(() {
        _isConnected = change.networkInfo.isConnected;
        _isHost = change.wifiP2pInfo.isGroupOwner;
        _deviceAddress = change.wifiP2pInfo.groupOwnerAddress;
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      // Handle changes of this device
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.peersChange.listen((change) {
      setState(() {
        _peers = change.devices;
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      // Handle discovery state changes
    }));

    FlutterP2p
        .register(); // Register to the native events which are send to the streams above
  }

  void _unregister() {
    _subscriptions.forEach(
        (subscription) => subscription.cancel()); // Cancel subscriptions
    FlutterP2p.unregister(); // Unregister from native events
  }

  Future _discover() async {
    await FlutterP2p.discoverDevices();
  }

  void _disconnect() async {
    FlutterP2p.removeGroup();
  }

  void _openPortAndAccept(int port) async {
    var socket = await FlutterP2p.openHostPort(port);
    setState(() {
      _socket = socket;
    });

    var buffer = "";
    socket.inputStream.listen((data) {
      var msg = String.fromCharCodes(data.data);
      buffer += msg;

      if (data.dataAvailable == 0) {
        Fluttertoast.showToast(msg: "Data Received: $buffer");
        buffer = "";
      }
    });

    // Write data to the client using the _socket.write(UInt8List) or `_socket.writeString("Hello")` method

    print("_openPort done");

    // accept a connection on the created socket
    await FlutterP2p.acceptPort(port);
    print("_accept done");
  }
}
