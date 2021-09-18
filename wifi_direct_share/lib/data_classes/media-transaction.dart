import 'dart:convert';
import 'dart:typed_data';

import 'package:wifi_direct_share/data_classes/media-file.dart';

class MediaTransaction {
  List<MediaFile>? data;

  MediaTransaction(this.data);

  MediaTransaction.fromUint8List(Uint8List list) {
    String s = String.fromCharCodes(list);

    data = jsonDecode(s);
  }

  String toJson() {
    // return "[" +data!.map((e) => e.toJson()).join(",")+ "]";
    return jsonEncode(data!);
  }
}
