import 'dart:io';
import 'dart:typed_data';

import 'package:file_icon/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:provider/provider.dart';

class FilesSeparatedList extends StatefulWidget {
  final dynamic data;
  final ScrollController controller;

  FilesSeparatedList({required this.data, required this.controller, Key? key})
      : super(key: key);

  @override
  _FilesSeparatedListState createState() => _FilesSeparatedListState();
}

class _FilesSeparatedListState extends State<FilesSeparatedList> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        padding: EdgeInsets.only(bottom: 10),
        controller: widget.controller,
        itemBuilder: (context, index) {
          return ListTile(
            leading: SizedBox(
              width: 30,
              height: 30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _getIconFor(File(widget.data[index].path)),
              ),
            ),
            trailing: widget.data is List<SharedMediaFile>
                ? IconButton(
                    onPressed: () {
                      context
                          .read<Map<String, dynamic>>()["SharedFiles"]
                          .removeAt(index);
                    },
                    icon: Icon(
                      Icons.delete,
                      color: Colors.grey[600],
                    ))
                : null,
            title: Text(widget.data[index].path.split("/").last),
            onTap: () {
              OpenFile.open(widget.data[index].path);
            },
          );
        },
        separatorBuilder: (context, index) {
          return Divider(color: Colors.grey[800]);
        },
        itemCount: widget.data.length);
  }

  dynamic _getIconFor(dynamic file) {
    if (file is File || file is SharedMediaFile) {
      String? mime = lookupMimeType(file.path);
      if (mime!.startsWith("image")) {
        return Image.file(File(file.path));
      } else if (mime.startsWith("video")) {
        return FutureBuilder(
            future: VideoThumbnail.thumbnailData(
              video: file.path,
              imageFormat: ImageFormat.JPEG,
              maxWidth:
                  128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("error");
              } else if (!snapshot.hasData &&
                  snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                return Image.memory(snapshot.data as Uint8List);
              } else {
                return Icon(Icons.insert_drive_file_rounded);
              }
            });
      } else {
        return Container(
            height: 32,
            width: 32,
            color: Colors.grey[800],
            child: Center(child: FileIcon(file.path)));
      }
    } else {
      return Icon(Icons.insert_drive_file_rounded);
    }
  }
}
