// lib/screens/video_play_screen.dart
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoPlayScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayScreen({required this.videoUrl, required this.title, Key? key}) : super(key: key);

  @override
  _VideoPlayScreenState createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
        );
      });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _chewieController != null && _videoController!.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : CircularProgressIndicator(),
      ),
    );
  }
}
