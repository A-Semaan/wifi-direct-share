import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

//variables
enum DeviceType { receiver, sender }
const int PORT = 5042;
NearbyService? nearbyService = NearbyService();
DeviceType deviceType = DeviceType.receiver;
const int PACKET_FRAGMENT = 2048;
String internalStorageDownloadsFolderPath = "";

//functions
discover() async {
  if (deviceType == DeviceType.receiver) {
    await nearbyService!.stopAdvertisingPeer();
    await nearbyService!.stopBrowsingForPeers();
    await Future.delayed(Duration(microseconds: 200));
    await nearbyService!.startAdvertisingPeer();
    await nearbyService!.startBrowsingForPeers();
  } else {
    await nearbyService!.stopBrowsingForPeers();
    await Future.delayed(Duration(microseconds: 200));
    await nearbyService!.startBrowsingForPeers();
  }
}
