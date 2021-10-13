import 'dart:convert';

import 'package:wifi_direct_share/data_classes/packet_enums.dart';

class Packet {
  late PacketType type;
  String? sequenceIndex;
  String? fileID;
  List<PacketStatus>? status;
  String? data;
  int? totalFiles;
  int? totalBytes;

  Packet(
      {required this.type,
      this.sequenceIndex,
      this.fileID,
      this.status,
      this.data,
      this.totalFiles,
      this.totalBytes});
  Packet.fromJson(Map<String, dynamic> dataMap) {
    type = PacketTypeExtension.fromJson(dataMap["type"].toString());
    if (dataMap.containsKey("sequenceIndex")) {
      sequenceIndex = dataMap["sequenceIndex"];
    }
    if (dataMap.containsKey("fileID")) {
      fileID = dataMap["fileID"];
    }
    if (dataMap.containsKey("status")) {
      status = (jsonDecode(dataMap["status"]) as List)
          .cast<String>()
          .map<PacketStatus>((e) => PacketStatusExtension.fromJson(e))
          .toList();
    }
    if (dataMap.containsKey("data")) {
      data = dataMap["data"];
    }
    if (dataMap.containsKey("totalFiles")) {
      totalFiles = dataMap["totalFiles"];
    }
    if (dataMap.containsKey("totalBytes")) {
      totalBytes = dataMap["totalBytes"];
    }
  }

  String toJson() {
    Map<String, dynamic> dataToSend = {};

    dataToSend["type"] = type.toJson();
    if (sequenceIndex != null) {
      dataToSend["sequenceIndex"] = sequenceIndex;
    }
    if (fileID != null) {
      dataToSend["fileID"] = fileID;
    }
    if (status != null) {
      dataToSend["status"] =
          jsonEncode(status!.map<String>((e) => e.toJson()).toList());
    }
    if (data != null) {
      dataToSend["data"] = data;
    }
    if (totalFiles != null) {
      dataToSend["totalFiles"] = totalFiles;
    }
    if (totalBytes != null) {
      dataToSend["totalBytes"] = totalBytes;
    }

    return jsonEncode(dataToSend);
  }
}
