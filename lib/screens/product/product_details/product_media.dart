
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
class ProductMedia {
  final String type;
  final String url;
  final String? thumbnail;
  final bool isShort;

  ProductMedia({
    required this.type,
    required this.url,
    this.thumbnail,
    this.isShort=false
  });
}

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
    } catch(e) {
      print("Error generating thumbnail: $e");
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
        return Image.file(
          File(thumbnailPath),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
    );
  }
}
// Player screen for self-hosted videos.
class VideoScreen extends StatefulWidget {
  final String videoUrl;
  const VideoScreen({super.key, required this.videoUrl});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}
class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  @override
  void initState() {
    super.initState();
    initializePlayer();
  }
  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Color(0xff0078D7),
        handleColor: Color(0xff0078D7),
        bufferedColor: Color(0xffEFEFEF),
        backgroundColor: Colors.white,
      ),

      cupertinoProgressColors: ChewieProgressColors(
        playedColor: Color(0xff0078D7),
        handleColor: Color(0xff0078D7),
        bufferedColor: Color(0xffEFEFEF),
        backgroundColor: Colors.white,
      ),
    );
    if(mounted){
      _isLoadingNotifier.value = false;
    }
  }
  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoadingNotifier,
              builder: (context, isLoading, child) {
                return isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Chewie(controller: _chewieController);
              },
            ),
          ),
          Positioned(
            top: 40.0,
            left: 10.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
// Player screen for YouTube videos.
// class YoutubePlayerScreen extends StatefulWidget {
//   final String youtubeUrl;
//   const YoutubePlayerScreen({super.key, required this.youtubeUrl});
//   @override
//   _YoutubePlayerScreenState createState() => _YoutubePlayerScreenState();
// }
//
// class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
//   late YoutubePlayerController _controller;
//   bool _isShorts = false;
//
//   @override
//   void initState() {
//     super.initState();
//     final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
//     if (widget.youtubeUrl.contains('/shorts/')) {
//       _isShorts = true;
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.portraitUp,
//         DeviceOrientation.portraitDown,
//       ]);
//     }
//
//     if (videoId != null && videoId.isNotEmpty) {
//       _controller = YoutubePlayerController(
//         initialVideoId: videoId,
//         flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
//     if(videoId == null || videoId.isEmpty){
//       return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Invalid YouTube URL", style: TextStyle(color: Colors.white))));
//     }
//     return Scaffold(
//       backgroundColor: Colors.red,
//       body: Stack(
//         children: [
//           Center(
//             child: YoutubePlayer(
//               controller: _controller,
//               aspectRatio: _isShorts ? 9 / 16 : 16 / 9,
//               showVideoProgressIndicator: true,
//               progressColors: const ProgressBarColors(
//                 playedColor: Colors.white,
//                 handleColor: Colors.white,
//                 bufferedColor: Colors.white54,
//                 backgroundColor: Colors.white24,
//               ),
//             ),
//           ),
//           Positioned(
//             top: 40.0,
//             left: 10.0,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   @override
//   void dispose() {
//     _controller.dispose();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     super.dispose();
//   }
// }

// Player screen for YouTube videos.
class YoutubePlayerScreen extends StatefulWidget {
  final String youtubeUrl;
  const YoutubePlayerScreen({super.key, required this.youtubeUrl});
  @override
  _YoutubePlayerScreenState createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isShorts = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    if (widget.youtubeUrl.contains('/shorts/')) {
      _isShorts = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    if(videoId == null || videoId.isEmpty){
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Invalid YouTube URL", style: TextStyle(color: Colors.white))));
    }
    return Scaffold(
      backgroundColor: Colors.red, // Set the base color to red
      body: Stack(
        children: [
          Center(
            // Use a second Stack to layer a red Container behind the player
            child: Stack(
              alignment: Alignment.center,
              children: [
                // This Container acts as the direct background for the player
                Container(color: Colors.red),

                // The YouTube player sits on top of the red Container
                YoutubePlayer(
                  controller: _controller,
                  aspectRatio: _isShorts ? 9 / 16 : 16 / 9,
                  showVideoProgressIndicator: true,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.white,
                    handleColor: Colors.white,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40.0,
            left: 10.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}