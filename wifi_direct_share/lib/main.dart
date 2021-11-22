import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _initializeSharedPreferences(callback: _checkIfShouldDisplayInstructions);
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
            subtitle1: TextStyle(color: Colors.grey[300], fontSize: 13),
            headline1: TextStyle(
              color: Colors.grey[300],
              fontSize: 18,
            ),
            headline2: TextStyle(
              color: Colors.grey[300],
              fontSize: 17,
            ),
            headline3: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
            ),
            headline4: TextStyle(
              color: Colors.grey[300],
              fontSize: 15,
            ),
            headline5: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
            headline6: TextStyle(color: Colors.white),
          ),
          // colorScheme: ColorScheme(brightness: Brightness.dark,secondary: Colors.black),
          backgroundColor: Colors.black,
          dialogBackgroundColor: Colors.grey[900],
          canvasColor: Color.fromRGBO(20, 20, 20, 1.0),
          appBarTheme: AppBarTheme(
            color: Colors.black,
            systemOverlayStyle:
                SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          )),
      home: MultiProvider(
        key: globalKey,
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
                context.read<DiscoveringChangeNotifier>().value
                    ? TextButton(
                        onPressed: () {
                          stopDiscover(context);
                        },
                        child: Text("Stop"))
                    : TextButton(
                        onPressed: () {
                          discover(context);
                        },
                        child: Text("Scan")),
                PopupMenuButton<String>(
                  onSelected: (option) {
                    print("object");
                    switch (option) {
                      case "HowToUse":
                        _showHowToUseDialog(context);
                        break;
                      default:
                        break;
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(20.0),
                    ),
                  ),
                  color: Theme.of(context).dialogBackgroundColor,
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuItem<String>>[
                      PopupMenuItem<String>(
                        value: "HowToUse",
                        textStyle: Theme.of(context).textTheme.headline3,
                        child: Text(
                          "How to use",
                        ),
                      )
                    ];
                  },
                ),
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
                                style: Theme.of(context).textTheme.headline3,
                              );
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
                                style: Theme.of(context).textTheme.headline3,
                                textAlign: TextAlign.left,
                              );
                            } else {
                              return Text(
                                "Your phone is currently visible to nearby devices, and is in receiving mode",
                                style: Theme.of(context).textTheme.headline3,
                              );
                            }
                          })
                      : Text(
                          "Your phone is in sending mode, and is currently scanning for nearby devices",
                          style: Theme.of(context).textTheme.headline3,
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

  void _showHowToUseDialog(context) {
    bool _checked = false;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            title: Text(
              "How to use",
              style: Theme.of(context).textTheme.bodyText2,
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                      style: Theme.of(context).textTheme.headline5,
                      children: <TextSpan>[
                        TextSpan(
                          text: "If you are receiving:\n\n",
                          style: Theme.of(context).textTheme.headline3,
                        ),
                        TextSpan(
                            text:
                                "\t- Just open the app and wait for the sender to make his move :D\n\n\n"),
                        TextSpan(
                          text: "If you are sending:\n\n",
                          style: Theme.of(context).textTheme.headline3,
                        ),
                        TextSpan(
                            text: "\t- Click share and choose WiFi Direct from any app on your device.\n" +
                                "\t- Wait for nearby devices to show up on the screen.\n" +
                                "\t- Click on the device you desire to send the file(s) to\n" +
                                "\t- And finally wait for the files to transfer :D\n\n\n"),
                        TextSpan(
                            text: "Note: If the device you desire to send files to is not showing up in the list " +
                                "click the scan button on the device of the receiver AND on the device of the sender. " +
                                "If you still can't find the device, then unfortunately that device is not supported"),
                      ]),
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _checked = !_checked;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _checked,
                          shape: CircleBorder(),
                          fillColor: MaterialStateColor.resolveWith((states) {
                            if (!states.contains(MaterialState.selected)) {
                              return Colors.grey[300]!;
                            } else {
                              return Colors.blue[700]!;
                            }
                          }),
                          onChanged: (value) {
                            setState(() {
                              _checked = value!;
                            });
                          },
                        ),
                        Text(
                          "Do not show again",
                          style: Theme.of(context).textTheme.headline3,
                        )
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (_checked) {
                          sharedPreferences!.setBool("ShowInstructuion", true);
                        } else {
                          sharedPreferences!.setBool("ShowInstructuion", false);
                        }
                      },
                      child: Text("OK"))
                ],
              ),
            ],
          );
        });
  }

  _initializeSharedPreferences({Function? callback}) async {
    sharedPreferences = await SharedPreferences.getInstance();

    if (callback != null) {
      callback.call();
    }
  }

  _checkIfShouldDisplayInstructions() {
    if (!sharedPreferences!.containsKey("ShowInstructuion") ||
        !sharedPreferences!.getBool("ShowInstructuion")!) {
      _showHowToUseDialog(globalKey.currentContext!);
    }
  }
}
