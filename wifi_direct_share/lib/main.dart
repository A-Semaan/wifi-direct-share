// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_p2p/flutter_p2p.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:wifi_direct_share/data_classes/discovering_change_notifier.dart';
import 'package:wifi_direct_share/globals.dart';
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
            textTheme: TextTheme(
                bodyText1: TextStyle(color: Colors.white),
                bodyText2: TextStyle(color: Colors.white, fontSize: 18),
                headline6: TextStyle(color: Colors.white),
                subtitle1: TextStyle(color: Colors.grey[300], fontSize: 13)),
            accentColor: Colors.black,
            backgroundColor: Colors.black,
            appBarTheme: AppBarTheme(
              brightness: Brightness.dark,
            )),
        home: MultiProvider(
          providers: [
            Provider<Map<String, dynamic>>(create: (_) => providerData),
            ChangeNotifierProvider<DiscoveringChangeNotifier>(
                create: (_) => new DiscoveringChangeNotifier())
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
                        _discover();
                        context.read<DiscoveringChangeNotifier>().value = true;
                      },
                      child: Text("Scan")),
                ],
              ),
              body: SlidingUpPanel(
                backdropTapClosesPanel: true,
                backdropColor: Colors.grey[850],
                minHeight: 60,
                backdropEnabled: true,
                backdropOpacity: 0.4,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                border: Border.all(
                  color: Colors.grey[850],
                ),
                color: Color.fromRGBO(20, 20, 20, 1.0),
                panelBuilder: (ScrollController controller) {
                  return WifiDirectSlideUpPanel(
                    controller: controller,
                  );
                },
                body: WifiDirectBody(),
              ),
            );
          },
        ));
  }

  Future _discover() async {
    await FlutterP2p.discoverDevices();
  }
}
