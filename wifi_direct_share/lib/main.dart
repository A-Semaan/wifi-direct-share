import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:wifi_direct_share/data_classes/discovering_change_notifier.dart';
import 'package:wifi_direct_share/data_classes/percentage_of_io.dart';
import 'package:wifi_direct_share/data_classes/refresh_function.dart';
import 'package:wifi_direct_share/data_classes/show_io_percentage.dart';
import 'package:wifi_direct_share/globals.dart';
import 'package:wifi_direct_share/layouts/wifi_direct_body.dart';
import 'package:wifi_direct_share/layouts/wifi_direct_slide_up.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _intentDataStreamSubscription;
  Map<String, dynamic> providerData = {
    "SharedFiles": <SharedMediaFile>[],
    "ReceivedFiles": <File>[],
    "SharedText": "",
  };

  @override
  void initState() {
    super.initState();
    _getInternalDownloadsFolderPath();
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        print("Shared:" +
            (providerData["SharedFiles"].map((f) => f.path)?.join(",") ?? ""));
        providerData["SharedFiles"] = value;
        if (value.length > 0) {
          deviceType = DeviceType.sender;
        }
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        providerData["SharedFiles"] = value;
        if (value.length > 0) {
          deviceType = DeviceType.sender;
        }
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.black,
          fontFamily: "Roboto",
          textTheme: TextTheme(
              bodyText1: TextStyle(color: Colors.white),
              bodyText2: TextStyle(color: Colors.white, fontSize: 18),
              headline6: TextStyle(color: Colors.white),
              subtitle1: TextStyle(color: Colors.grey[300], fontSize: 13)),
          // colorScheme: ColorScheme(brightness: Brightness.dark,secondary: Colors.black),
          backgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            color: Colors.black,
            systemOverlayStyle:
                SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          )),
      home: MultiProvider(
        providers: [
          Provider<Map<String, dynamic>>(create: (_) => providerData),
          ChangeNotifierProvider<DiscoveringChangeNotifier>(
              create: (_) => new DiscoveringChangeNotifier()),
          ChangeNotifierProvider<PercentageOfIO>(
            create: (_) => PercentageOfIO(0),
          ),
          ChangeNotifierProvider<ShowPercentageOfIO>(
            create: (_) => ShowPercentageOfIO(false),
          ),
          Provider<RefreshFunction>(
            create: (_) => RefreshFunction(),
          ),
        ],
        builder: (BuildContext context, widget) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text('Wi-Fi Direct'),
              automaticallyImplyLeading: false,
              actions: [
                Container(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  width: 25,
                  child: Visibility(
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    visible: context.watch<DiscoveringChangeNotifier>().value,
                    child: CircularProgressIndicator(
                      color: Colors.lightBlue,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                TextButton(
                    onPressed: () {
                      discover();
                      context.read<DiscoveringChangeNotifier>().value = true;
                    },
                    child: Text("Scan")),
              ],
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 20.0, bottom: 20.0, left: 20, right: 20),
                  child: deviceType == DeviceType.receiver
                      ? FutureBuilder(
                          future: DeviceInfoPlugin().androidInfo,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                  "Your phone is currently visible to nearby devices, and is in receiving mode",
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 16,
                                  ));
                            } else if (!snapshot.hasData &&
                                snapshot.connectionState !=
                                    ConnectionState.done) {
                              return SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasData) {
                              AndroidDeviceInfo deviceInfo =
                                  snapshot.data as AndroidDeviceInfo;
                              return Text(
                                "Your phone is currently visible to nearby devices, and is in receiving mode.\n\n" +
                                    "Your device is discoverable under the name ${deviceInfo.model}",
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.left,
                              );
                            } else {
                              return Text(
                                  "Your phone is currently visible to nearby devices, and is in receiving mode",
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 16,
                                  ));
                            }
                          })
                      : Container(
                          height: 0,
                        ),
                ),
                Expanded(
                  child: SlidingUpPanel(
                    backdropTapClosesPanel: true,
                    backdropColor: Colors.grey[850]!,
                    minHeight: 60,
                    backdropEnabled: true,
                    backdropOpacity: 0.4,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20)),
                    border: Border.all(
                      color: Colors.grey[850]!,
                    ),
                    color: Color.fromRGBO(20, 20, 20, 1.0),
                    panelBuilder: (ScrollController controller) {
                      return WifiDirectSlideUpPanel(
                        controller: controller,
                      );
                    },
                    body: WifiDirectBody(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // FutureBuilder(
      //   future: [Permission.locationWhenInUse, Permission.storage].request(),
      //   builder: (context,
      //       AsyncSnapshot<Map<Permission, PermissionStatus>> snapshot) {
      //     if (snapshot.hasError) {
      //       return Scaffold(
      //         backgroundColor: Colors.black,
      //         body: Center(
      //           child: Padding(
      //             padding: const EdgeInsets.all(8.0),
      //             child: Text(
      //               "An error has occured while requesting Storage permission",
      //               textAlign: TextAlign.center,
      //             ),
      //           ),
      //         ),
      //       );
      //     } else if (!snapshot.hasData ||
      //         snapshot.connectionState != ConnectionState.done) {
      //       return Scaffold(
      //         backgroundColor: Colors.black,
      //         body: Center(
      //           child: SizedBox(
      //             width: 40,
      //             height: 40,
      //             child: CircularProgressIndicator(),
      //           ),
      //         ),
      //       );
      //     } else if (snapshot.hasData) {
      //       if ((snapshot.data![Permission.storage] as PermissionStatus)
      //           .isGranted) {
      //         return MultiProvider(
      //           providers: [
      //             Provider<Map<String, dynamic>>(create: (_) => providerData),
      //             ChangeNotifierProvider<DiscoveringChangeNotifier>(
      //                 create: (_) => new DiscoveringChangeNotifier()),
      //             ChangeNotifierProvider<PercentageOfIO>(
      //               create: (_) => PercentageOfIO(0),
      //             ),
      //             ChangeNotifierProvider<ShowPercentageOfIO>(
      //               create: (_) => ShowPercentageOfIO(false),
      //             ),
      //             Provider<RefreshFunction>(
      //               create: (_) => RefreshFunction(),
      //             ),
      //           ],
      //           builder: (BuildContext context, widget) {
      //             return Scaffold(
      //               backgroundColor: Colors.black,
      //               appBar: AppBar(
      //                 title: const Text('Wi-Fi Direct'),
      //                 automaticallyImplyLeading: false,
      //                 actions: [
      //                   Container(
      //                     padding: EdgeInsets.only(top: 15, bottom: 15),
      //                     width: 25,
      //                     child: Visibility(
      //                       maintainSize: true,
      //                       maintainAnimation: true,
      //                       maintainState: true,
      //                       visible: context
      //                           .watch<DiscoveringChangeNotifier>()
      //                           .value,
      //                       child: CircularProgressIndicator(
      //                         color: Colors.lightBlue,
      //                         strokeWidth: 2,
      //                       ),
      //                     ),
      //                   ),
      //                   TextButton(
      //                       onPressed: () {
      //                         discover();
      //                         context
      //                             .read<DiscoveringChangeNotifier>()
      //                             .value = true;
      //                       },
      //                       child: Text("Scan")),
      //                 ],
      //               ),
      //               body: SlidingUpPanel(
      //                 backdropTapClosesPanel: true,
      //                 backdropColor: Colors.grey[850]!,
      //                 minHeight: 60,
      //                 backdropEnabled: true,
      //                 backdropOpacity: 0.4,
      //                 borderRadius: BorderRadius.only(
      //                     topLeft: Radius.circular(20),
      //                     topRight: Radius.circular(20)),
      //                 border: Border.all(
      //                   color: Colors.grey[850]!,
      //                 ),
      //                 color: Color.fromRGBO(20, 20, 20, 1.0),
      //                 panelBuilder: (ScrollController controller) {
      //                   return WifiDirectSlideUpPanel(
      //                     controller: controller,
      //                   );
      //                 },
      //                 body: WifiDirectBody(),
      //               ),
      //             );
      //           },
      //         );
      //       } else {
      //         return Scaffold(
      //           backgroundColor: Colors.black,
      //           body: Center(
      //             child: Padding(
      //               padding: const EdgeInsets.all(8.0),
      //               child: Column(
      //                 mainAxisSize: MainAxisSize.min,
      //                 children: [
      //                   Text(
      //                       "This app needs Storage permission in order for it to run",
      //                       textAlign: TextAlign.center),
      //                   TextButton(
      //                       onPressed: () async {
      //                         openAppSettings();
      //                         await Future.delayed(
      //                             Duration(milliseconds: 100));
      //                         setState(() {});
      //                       },
      //                       child: Text("Grant storage permission")),
      //                 ],
      //               ),
      //             ),
      //           ),
      //         );
      //       }
      //     } else {
      //       return Scaffold(
      //         backgroundColor: Colors.black,
      //         body: Center(
      //           child: Padding(
      //             padding: const EdgeInsets.all(8.0),
      //             child: Text("unknown state", textAlign: TextAlign.center),
      //           ),
      //         ),
      //       );
      //     }
      //   },
      // )
    );
  }

  _getInternalDownloadsFolderPath() async {
    if (internalStorageDownloadsFolderPath != "") {
      return;
    }
    Directory? dir = await getExternalStorageDirectory();
    internalStorageDownloadsFolderPath =
        dir!.path.substring(0, dir.path.indexOf("0") + 2) + "Download";
  }
}
