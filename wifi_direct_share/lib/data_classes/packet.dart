class Packet {
  String? type;
  String? sequenceIndex;
  String? fileID;
  String? status;
  String? data;
  String? totalFiles;
  String? totalBytes;

  Packet(
      {this.type,
      this.sequenceIndex,
      this.fileID,
      this.status,
      this.data,
      this.totalFiles,
      this.totalBytes});
}
