// lib/screens/challenge_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Untuk HapticFeedback

class ChallengeScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const ChallengeScreen({
    required this.videoUrl,
    required this.videoTitle,
    Key? key,
  }) : super(key: key);

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  VideoPlayerController? _videoController;
  FaceDetector? _faceDetector;
  
  bool _isSmiling = false;
  int _smileCount = 0;
  bool _challengeActive = true;
  bool _isCameraInitialized = false;
  bool _isVideoInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    try {
      // Cek permission kamera
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Izin kamera diperlukan untuk challenge';
        });
        return;
      }

      await _initializeCamera();
      await _initializeVideo();
      _initializeFaceDetector();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    
    // Cari kamera depan
    final frontCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processCameraImage);
    
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController!.initialize();
    _videoController!.play();
    _videoController!.addListener(() {
      if (_videoController!.value.position == _videoController!.value.duration) {
        _endChallenge();
      }
    });
    
    setState(() {
      _isVideoInitialized = true;
    });
  }

  void _initializeFaceDetector() {
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableClassification: true,
        minFaceSize: 0.1,
      ),
    );
  }

  // Perbaikan: Cara konversi CameraImage ke InputImage yang benar untuk versi terbaru
  void _processCameraImage(CameraImage image) async {
    if (!_challengeActive || _faceDetector == null) return;

    try {
      // Konversi CameraImage ke InputImage
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Dapatkan kamera yang digunakan
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      
      // Buat InputImage dengan cara yang benar
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: _getRotation(camera.sensorOrientation),
          format: InputImageFormat.nv21, // Format default untuk camera
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector!.processImage(inputImage);
      
      if (faces.isNotEmpty) {
        final Face face = faces.first;
        
        // Deteksi senyum
        final smilingProb = face.smilingProbability ?? 0.0;
        final isCurrentlySmiling = smilingProb > 0.7;
        
        if (isCurrentlySmiling && !_isSmiling) {
          setState(() {
            _isSmiling = true;
            _smileCount++;
          });
          
          HapticFeedback.lightImpact();
          
          if (_challengeActive) {
            _failChallenge();
          }
        } else if (!isCurrentlySmiling) {
          _isSmiling = false;
        }
      }
    } catch (e) {
      print('Error processing camera image: $e');
    }
  }

  // Helper untuk konversi rotasi
  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _failChallenge() {
    setState(() {
      _challengeActive = false;
    });
    
    _videoController?.pause();
    _cameraController?.stopImageStream();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(Icons.sentiment_very_dissatisfied, size: 50, color: Colors.red),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Challenge Gagal!', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Anda tersenyum!'),
            Text('Smile count: $_smileCount', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _endChallenge() {
    if (!_challengeActive) return;
    
    setState(() {
      _challengeActive = false;
    });
    
    _cameraController?.stopImageStream();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(Icons.emoji_events, size: 50, color: Colors.amber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Challenge Berhasil!', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Anda berhasil tidak tersenyum!'),
            Text('Total smile detected: $_smileCount', 
              style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _videoController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Challenge')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || !_isVideoInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Mempersiapkan challenge...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Video player
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          
          if (!_challengeActive)
            Container(color: Colors.black54),
          
          // Camera preview
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          
          // Info
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSmiling ? Icons.tag_faces : Icons.mood,
                    color: _isSmiling ? Colors.red : Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Smile: $_smileCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Progress
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _videoController!.value.position.inMilliseconds /
                     _videoController!.value.duration.inMilliseconds,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isSmiling ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}