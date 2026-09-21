

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:path_provider/path_provider.dart';
class VideoThumbnailGenerator extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailGenerator({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailGenerator> createState() => _VideoThumbnailGeneratorState();
}

class _VideoThumbnailGeneratorState extends State<VideoThumbnailGenerator> {
  final ValueNotifier<String?> _thumbnailPathNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        quality: 75,
      );
      if (mounted) {
        _thumbnailPathNotifier.value = thumbnailPath.path;
      }
    } catch (e) {
      print('Failed to generate thumbnail: $e');
      if (mounted) {
        _thumbnailPathNotifier.value = ""; // Empty string indicates error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _thumbnailPathNotifier,
      builder: (context, thumbnailPath, child) {
        if (thumbnailPath == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (thumbnailPath.isEmpty) {
          return const Center(child: Icon(Icons.videocam_off, color: Colors.grey, size: 50));
        }
        return Image.file(File(thumbnailPath), fit: BoxFit.cover);
      },
    );
  }
}