import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:open_file/open_file.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wifi_direct_share/data_classes/percentage_of_io.dart';
import 'package:wifi_direct_share/data_classes/refresh_function.dart';
import 'package:wifi_direct_share/data_classes/show_io_percentage.dart';
import 'package:wifi_direct_share/globals.dart';

class WifiDirectSlideUpPanel extends StatefulWidget {
  ScrollController? controller;

  WifiDirectSlideUpPanel({Key? key, this.controller}) : super(key: key);

  @override
  _WifiDirectSlideUpPanelState createState() => _WifiDirectSlideUpPanelState();
}

class _WifiDirectSlideUpPanelState extends State<WifiDirectSlideUpPanel> {
  static const textStyleBold = const TextStyle(fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    context.read<RefreshFunction>().func = () {
      setState(() {});
    };
    return Container(
      child: Center(
        child: Column(
          children: [
            Center(
              widthFactor: double.infinity,
              heightFactor: 1.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 20,
                    width: 70,
                    child: deviceType == DeviceType.sender
                        ? Visibility(
                            visible: context
                                    .read<Map<String, dynamic>>()["SharedFiles"]
                                    .length !=
                                0,
                            child: Text(
                              context
                                      .read<Map<String, dynamic>>()[
                                          "SharedFiles"]
                                      .length
                                      .toString() +
                                  " items",
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          )
                        : Visibility(
                            visible: context
                                    .read<Map<String, dynamic>>()[
                                        "ReceivedFiles"]
                                    .length !=
                                0,
                            child: Text(
                              context
                                      .read<Map<String, dynamic>>()[
                                          "ReceivedFiles"]
                                      .length
                                      .toString() +
                                  " items",
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    width: 40,
                    height: 6,
                  ),
                  Container(
                    height: 32,
                    width: 70,
                    child: Visibility(
                      visible: context.watch<ShowPercentageOfIO>().value,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: CircularPercentIndicator(
                        progressColor: Colors.green[400],
                        radius: 32,
                        lineWidth: 3,
                        // animation: true,
                        percent: context.watch<PercentageOfIO>().value,
                        center: Text(
                          (context.watch<PercentageOfIO>().value * 100)
                              .floor()
                              .toString(),
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: deviceType == DeviceType.sender
                  ? ListView.separated(
                      padding: EdgeInsets.only(bottom: 10),
                      controller: widget.controller,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File((context.read<Map<String, dynamic>>()[
                                      "SharedFiles"][index] as SharedMediaFile)
                                  .path),
                            ),
                          ),
                          trailing: IconButton(
                              onPressed: () {
                                context
                                    .read<Map<String, dynamic>>()["SharedFiles"]
                                    .removeAt(index);
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.grey[600],
                              )),
                          title: Text((context.read<Map<String, dynamic>>()[
                                  "SharedFiles"][index] as SharedMediaFile)
                              .path
                              .split("/")
                              .last),
                          onTap: () {
                            OpenFile.open((context.read<Map<String, dynamic>>()[
                                    "SharedFiles"][index] as SharedMediaFile)
                                .path);
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(color: Colors.grey[800]);
                      },
                      itemCount: context
                          .read<Map<String, dynamic>>()["SharedFiles"]
                          .length)
                  : ListView.separated(
                      padding: EdgeInsets.only(bottom: 10),
                      controller: widget.controller,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File((context.read<Map<String, dynamic>>()[
                                      "ReceivedFiles"][index] as File)
                                  .path),
                            ),
                          ),
                          title: Text((context.read<Map<String, dynamic>>()[
                                  "ReceivedFiles"][index] as File)
                              .path
                              .split("/")
                              .last),
                          onTap: () {
                            OpenFile.open((context.read<Map<String, dynamic>>()[
                                    "ReceivedFiles"][index] as File)
                                .path);
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(color: Colors.grey[800]);
                      },
                      itemCount: context
                          .read<Map<String, dynamic>>()["ReceivedFiles"]
                          .length),
            ),
          ],
        ),
      ),
    );
  }
}
