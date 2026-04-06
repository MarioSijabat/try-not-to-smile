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
  bool _isTFLiteProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    // Cek permission kamera dulu
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Izin kamera diperlukan untuk challenge';
        });
      }
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
    // ML Kit hanya untuk deteksi posisi wajah (bounding box).
    // Smile detection sepenuhnya dilakukan oleh MobileNet.
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false, // tidak perlu smile prob dari ML Kit
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    // Inisialisasi MobileNet (paralel dengan kamera)
    await _smileService.initialize();

    if (mounted) {
      setState(() {
        _isModelReady = _smileService.isInitialized;
      });
    }
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

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
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

    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  /// Proses frame kamera: Hybrid ML Kit (deteksi wajah) + MobileNet (klasifikasi senyum)
  void _processCameraImage(CameraImage image) async {
    if (!_challengeActive || _isProcessing || !mounted) return;
    if (_faceDetector == null || !_isModelReady) return;

    _isProcessing = true;

    try {
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // ── Fix: Bangun bytes NV21 yang valid ──────────────────────────────
      // Hanya 2 plane yang dibutuhkan: Y + interleaved VU
      final inputImage = _buildInputImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Step 1: ML Kit — cek apakah ada wajah di frame
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      // Rule 1: Find largest face
      Face? largestFace;
      if (faces.isNotEmpty) {
        double maxArea = 0;
        for (final face in faces) {
          final box = face.boundingBox;
          final area = box.width * box.height;
          if (area > maxArea) {
            maxArea = area;
            largestFace = face;
          }
        }
      }

      // Rule 3: Trigger TFLite without blocking the next camera frame
      if (largestFace != null) {
        if (!_isTFLiteProcessing) {
          _isTFLiteProcessing = true;
          _smileService.detectSmile(
            image,
            largestFace.boundingBox,
            camera.sensorOrientation,
          ).then((result) {
            if (result != null && mounted) {
              final double smileScore = result['smileScore'] ?? 0.0;
              final isCurrentlySmiling = smileScore > 0.55;

              if (isCurrentlySmiling && !_isSmiling) {
                setState(() {
                  _isSmiling = true;
                  _smileCount++;
                });
                HapticFeedback.lightImpact();

                if (_challengeActive) {
                  _failChallenge();
                }
              } else if (!isCurrentlySmiling && _isSmiling) {
                setState(() {
                  _isSmiling = false;
                });
              }
            }
          }).catchError((e) {
            debugPrint('[ChallengeScreen] TFLite error: $e');
          }).whenComplete(() {
            _isTFLiteProcessing = false;
          });
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
      debugPrint('[ChallengeScreen] Frame error: $e');
    } finally {
      // Allow the next camera frame to be processed by ML Kit immediately
      _isProcessing = false;
    }
  }

  /// Konversi CameraImage (yuv_420_888) ke NV21 bersih tanpa stride padding.
  /// ML Kit butuh NV21 dengan bytesPerRow = width (tanpa padding).
  InputImage? _buildInputImage(CameraImage image, CameraDescription cam) {
    try {
      final width  = image.width;
      final height = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes.length > 1 ? image.planes[1] : null;
      final vPlane = image.planes.length > 2 ? image.planes[2] : null;

      // Buffer NV21: Y plane (w*h) + interleaved VU (w*h/2)
      final nv21 = Uint8List(width * height + (width * height) ~/ 2);

      // ── Salin Y plane (strip padding per baris) ────────────────────────
      for (int row = 0; row < height; row++) {
        final srcStart = row * yPlane.bytesPerRow;
        final dstStart = row * width;
        nv21.setRange(dstStart, dstStart + width, yPlane.bytes, srcStart);
      }

      // ── Interleave VU (NV21: V dulu, lalu U) ──────────────────────────
      int uvOffset = width * height;
      if (vPlane != null && uPlane != null) {
        final uvHeight = height ~/ 2;
        final uvWidth  = width  ~/ 2;
        final vStride  = vPlane.bytesPerRow;
        final uStride  = uPlane.bytesPerRow;
        final vPixel   = vPlane.bytesPerPixel ?? 1;
        final uPixel   = uPlane.bytesPerPixel ?? 1;

        for (int row = 0; row < uvHeight; row++) {
          for (int col = 0; col < uvWidth; col++) {
            final vIdx = row * vStride + col * vPixel;
            final uIdx = row * uStride + col * uPixel;
            nv21[uvOffset++] = vIdx < vPlane.bytes.length ? vPlane.bytes[vIdx] : 128;
            nv21[uvOffset++] = uIdx < uPlane.bytes.length ? uPlane.bytes[uIdx] : 128;
          }
        }
      }

      // Gunakan sensor orientation langsung (tanpa flip)
      final rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
      if (rotation == null) return null;

      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width, // NV21 bersih = width, tanpa padding
        ),
      );
    } catch (e) {
      debugPrint('[ChallengeScreen] buildInputImage error: $e');
      return null;
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/got_a_smile.jpeg',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _resetChallenge();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh, color: Colors.black, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Coba Lagi',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetChallenge() {
    setState(() {
      _challengeActive = true;
      _isSmiling = false;
      _smileCount = 0;
    });

    _videoController?.seekTo(Duration.zero);
    _videoController?.play();
    
    // Mulai lagi tangkapan frame kamera untuk diproses
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      _cameraController!.startImageStream(_processCameraImage);
    }
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