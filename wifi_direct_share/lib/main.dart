// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:wifi_direct_share/layouts/wifi_direct_body.dart';
import 'package:wifi_direct_share/layouts/wifi_direct_slide_up.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription _intentDataStreamSubscription;
  Map<String, dynamic> providerData = {
    "SharedFiles": <SharedMediaFile>[],
    "SharedText": "",
  };

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        print("Shared:" +
            (providerData["SharedFiles"].map((f) => f.path)?.join(",") ?? ""));
        providerData["SharedFiles"] = value;
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        providerData["SharedFiles"] = value ?? <SharedMediaFile>[];
      });
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        providerData["SharedText"] = value ?? "";
      });
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      setState(() {
        providerData["SharedText"] = value ?? "";
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            primaryColor: Colors.black,
            fontFamily: "Roboto",
            accentColor: Colors.black,
            backgroundColor: Colors.black,
            appBarTheme: AppBarTheme(
              brightness: Brightness.dark,
            )),
        home: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Wi-Fi Direct'),
            automaticallyImplyLeading: false,
          ),
          body: MultiProvider(
              providers: [
                Provider<Map<String, dynamic>>(create: (_) => providerData),
              ],
              child: SlidingUpPanel(
                panel: WifiDIrectSlideUpPanel(),
                body: WifiDirectBody(),
              )),
        ));
  }
}
