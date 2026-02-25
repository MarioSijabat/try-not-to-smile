// lib/screens/challenge_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../services/face_detection_service.dart';

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

  // ML Kit — untuk deteksi keberadaan wajah
  FaceDetector? _faceDetector;

  // MobileNet — untuk klasifikasi senyum
  final SmileDetectionService _smileService = SmileDetectionService();

  bool _isSmiling = false;
  int _smileCount = 0;
  bool _challengeActive = true;
  bool _isCameraInitialized = false;
  bool _isVideoInitialized = false;
  bool _isModelReady = false;
  String? _errorMessage;

  // Throttle: jaga agar inferensi tidak terlalu sering
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    // Cek permission kamera dulu
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _errorMessage = 'Izin kamera diperlukan untuk challenge';
      });
      return;
    }

    // Jalankan semua inisialisasi secara paralel — masing-masing update state sendiri
    // sehingga video langsung muncul tanpa menunggu kamera/model siap
    _initializeCamera().catchError((e) {
      debugPrint('[ChallengeScreen] Camera init error: $e');
    });
    _initializeVideo().catchError((e) {
      if (mounted) setState(() => _errorMessage = 'Gagal memuat video: $e');
    });
    _initializeDetectors().catchError((e) {
      debugPrint('[ChallengeScreen] Detector init error: $e');
    });
  }

  Future<void> _initializeDetectors() async {
    // ML Kit face detector (ringan, hanya cek ada tidaknya wajah)
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false, // Nonaktifkan — kita pakai MobileNet
        minFaceSize: 0.15,
      ),
    );

    // MobileNet model
    await _smileService.initialize();

    setState(() {
      _isModelReady = _smileService.isInitialized;
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

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
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    await _videoController!.initialize();
    _videoController!.play();
    _videoController!.addListener(() {
      if (mounted &&
          _videoController!.value.isInitialized &&
          _videoController!.value.position >= _videoController!.value.duration) {
        _endChallenge();
      }
    });

    setState(() {
      _isVideoInitialized = true;
    });
  }

  /// Proses frame kamera: Hybrid ML Kit (deteksi wajah) + MobileNet (klasifikasi senyum)
  void _processCameraImage(CameraImage image) async {
    if (!_challengeActive || _isProcessing) return;
    if (_faceDetector == null || !_isModelReady) return;

    _isProcessing = true;

    try {
      // Step 1: ML Kit — cek apakah ada wajah di frame
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getRotation(camera.sensorOrientation),
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      // Jika ada wajah terdeteksi ML Kit → jalankan MobileNet
      if (faces.isNotEmpty) {
        final smileProb = await _smileService.detectSmile(image);

        // smileProb -1.0 berarti error model, skip frame ini
        if (smileProb >= 0.0) {
          final isCurrentlySmiling = smileProb > 0.72;

          if (isCurrentlySmiling && !_isSmiling) {
            if (mounted) {
              setState(() {
                _isSmiling = true;
                _smileCount++;
              });
            }
            HapticFeedback.lightImpact();

            if (_challengeActive) {
              _failChallenge();
            }
          } else if (!isCurrentlySmiling && _isSmiling) {
            if (mounted) {
              setState(() {
                _isSmiling = false;
              });
            }
          }
        }
      } else {
        // Tidak ada wajah — reset state senyum
        if (_isSmiling && mounted) {
          setState(() {
            _isSmiling = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }

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
    if (!_challengeActive) return;
    setState(() {
      _challengeActive = false;
    });

    _videoController?.pause();
    _cameraController?.stopImageStream();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.sentiment_very_dissatisfied, size: 50, color: Colors.red),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Challenge Gagal!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Anda tersenyum!'),
            Text(
              'Smile count: $_smileCount',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
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
        title: const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Challenge Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Anda berhasil tidak tersenyum!'),
            Text(
              'Total smile detected: $_smileCount',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
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
    _smileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || !_isVideoInitialized) {
      return const Scaffold(
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
          // Video player fullscreen
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

          if (!_challengeActive) Container(color: Colors.black54),

          // Camera preview (pojok kanan atas)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isSmiling ? Colors.red : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
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

          // Status bar (pojok kiri atas)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Indikator model status
                  Icon(
                    _isModelReady ? Icons.psychology : Icons.psychology_outlined,
                    color: _isModelReady ? Colors.greenAccent : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isSmiling ? Icons.tag_faces : Icons.mood,
                    color: _isSmiling ? Colors.red : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Smile: $_smileCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress bar video (bawah)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _videoController!.value.duration.inMilliseconds > 0
                  ? _videoController!.value.position.inMilliseconds /
                      _videoController!.value.duration.inMilliseconds
                  : 0.0,
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