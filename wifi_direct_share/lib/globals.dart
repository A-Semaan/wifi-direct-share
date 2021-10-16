import 'package:flutter/widgets.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_direct_share/data_classes/discovering_change_notifier.dart';

//variables
enum DeviceType { receiver, sender }
const int PORT = 5042;
NearbyService? nearbyService = NearbyService();
DeviceType deviceType = DeviceType.receiver;
const int PACKET_FRAGMENT = 2048;
String internalStorageDownloadsFolderPath = "";

bool _isDiscovering = false;

SharedPreferences? sharedPreferences;
final GlobalKey globalKey = new GlobalKey();

//functions
discover(BuildContext context) async {
  context.read<DiscoveringChangeNotifier>().value = true;
  if (deviceType == DeviceType.receiver) {
    await nearbyService!.stopAdvertisingPeer();
    // await nearbyService!.stopBrowsingForPeers();
    await Future.delayed(Duration(microseconds: 200));
    nearbyService!.startAdvertisingPeer();
    // nearbyService!.startBrowsingForPeers();
  } else {
    await nearbyService!.stopBrowsingForPeers();
    await Future.delayed(Duration(microseconds: 200));
    nearbyService!.startBrowsingForPeers();
  }
  _isDiscovering = true;
  Future.delayed(Duration(seconds: 7), () {
    context.read<DiscoveringChangeNotifier>().value = false;
    _isDiscovering = false;
  });
}

stopDiscover(BuildContext context) async {
  if (_isDiscovering) {
    context.read<DiscoveringChangeNotifier>().value = false;
    if (deviceType == DeviceType.receiver) {
      await nearbyService!.stopAdvertisingPeer();
      await nearbyService!.stopBrowsingForPeers();
    } else {
      await nearbyService!.stopBrowsingForPeers();
    }
    _isDiscovering = false;
  }
}
