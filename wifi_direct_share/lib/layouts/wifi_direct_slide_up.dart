import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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
    return Container(
      child: Center(
        child: Column(
          children: [
            Center(
              widthFactor: double.infinity,
              heightFactor: 10,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                width: 40,
                height: 6,
              ),
            ),
            Expanded(
              child: ListView.separated(
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
                      title: Text(
                          (context.read<Map<String, dynamic>>()["SharedFiles"]
                                  [index] as SharedMediaFile)
                              .path
                              .split("/")
                              .last),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return Divider(color: Colors.grey[800]);
                  },
                  itemCount: context
                      .read<Map<String, dynamic>>()["SharedFiles"]
                      .length),
            ),
          ],
        ),
      ),
    );
  }
}
