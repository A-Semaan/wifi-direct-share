import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class WifiDIrectSlideUpPanel extends StatefulWidget {
  WifiDIrectSlideUpPanel({Key? key}) : super(key: key);

  @override
  _WifiDIrectSlideUpPanelState createState() => _WifiDIrectSlideUpPanelState();
}

class _WifiDIrectSlideUpPanelState extends State<WifiDIrectSlideUpPanel> {
  static const textStyleBold = const TextStyle(fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
