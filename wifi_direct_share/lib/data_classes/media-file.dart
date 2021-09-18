import 'dart:convert';
import 'dart:typed_data';

class MediaFile {
  String? name;
  String? extension;
  int? size;
  Uint8List? file;

  MediaFile(this.name, this.extension, this.size, this.file);

  String toJson() {
    Map<String, dynamic> toReturn = Map<String, dynamic>();
    toReturn["name"] = name!;
    toReturn["extension"] = extension!;
    toReturn["size"] = size!;
    toReturn["file"] = file!;
    return jsonEncode(toReturn);
  }
}
