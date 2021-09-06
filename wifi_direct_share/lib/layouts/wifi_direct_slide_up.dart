import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class WifiDirectSlideUpPanel extends StatefulWidget {
  WifiDirectSlideUpPanel({Key? key}) : super(key: key);

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
          children: <Widget>[
            Text("Shared files:", style: textStyleBold),
            Text(context
                .read<Map<String, dynamic>>()["SharedFiles"]
                .map((f) => f.path)
                .join(",")),
            SizedBox(height: 100),
            Text("Shared urls/text:", style: textStyleBold),
            Text(context.read<Map<String, dynamic>>()["SharedText"])
          ],
        ),
      ),
    );
  }
}
