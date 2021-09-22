import 'dart:io';
import 'dart:typed_data';

import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wifi_direct_share/data_classes/percentage_of_io.dart';
import 'package:wifi_direct_share/data_classes/refresh_function.dart';
import 'package:wifi_direct_share/data_classes/show_io_percentage.dart';
import 'package:wifi_direct_share/fragments/files_separated_list.dart';
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
                    ? FilesSeparatedList(
                        data:
                            context.read<Map<String, dynamic>>()["SharedFiles"],
                        controller: widget.controller!)
                    : FilesSeparatedList(
                        data: context
                            .read<Map<String, dynamic>>()["ReceivedFiles"],
                        controller: widget.controller!)),
          ],
        ),
      ),
    );
  }
}
