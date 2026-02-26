// lib/screens/swipeable_challenge_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/active_video_model.dart';
import '../services/face_detection_service.dart';

class SwipeableChallengeScreen extends StatefulWidget {
  final List<ActiveVideoModel> videos;

  const SwipeableChallengeScreen({required this.videos, Key? key})
      : super(key: key);

  @override
  _SwipeableChallengeScreenState createState() =>
      _SwipeableChallengeScreenState();
}

class _SwipeableChallengeScreenState extends State<SwipeableChallengeScreen> {
  // ── Camera & face detection (shared across pages) ─────────────────────────
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  FaceDetector? _faceDetector;
  bool _isCameraInitialized = false;

  // ── MobileNet ────────────────────────────────────────────────────────────
  final SmileDetectionService _smileService = SmileDetectionService();
  bool _isModelReady = false;

  // ── Per-video controllers ─────────────────────────────────────────────────
  final Map<int, VideoPlayerController> _videoControllers = {};
  int _currentIndex = 0;

  // ── Challenge state (resets per video) ───────────────────────────────────
  bool _isSmiling = false;
  int _smileCount = 0;
  bool _challengeFailed = false;
  bool _processingFace = false;
  bool _isTFLiteProcessing = false;

  late PageController _pageController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initCamera();
    _initFaceDetector();
    _initMobileNet();
    _initVideoAt(0);
  }

  Future<void> _initMobileNet() async {
    await _smileService.initialize();
    if (mounted) setState(() => _isModelReady = _smileService.isInitialized);
  }

  // ── Camera ────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _errorMessage = 'Izin kamera diperlukan untuk challenge');
        return;
      }
      _cameras = await availableCameras();
      final front = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      setState(() => _errorMessage = 'Error kamera: $e');
    }
  }

  void _initFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        minFaceSize: 0.1,
      ),
    );
  }

  // Error state per video index
  final Map<int, String> _videoErrors = {};

  // ── Video management ──────────────────────────────────────────────────────
  Future<void> _initVideoAt(int index) async {
    if (index < 0 || index >= widget.videos.length) return;
    if (_videoControllers.containsKey(index)) return;

    final video = widget.videos[index];
    if (video.videoUrl == null || video.videoUrl!.isEmpty) {
      if (mounted) setState(() => _videoErrors[index] = 'URL video tidak tersedia');
      return;
    }

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl!));

      // Timeout 20 detik — jika network lambat / URL expired, tidak stuck selamanya
      await ctrl.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          ctrl.dispose();
          throw Exception('Timeout: video terlalu lama dimuat. Periksa koneksi internet.');
        },
      );

      _videoControllers[index] = ctrl;

      if (index == _currentIndex && mounted) {
        ctrl.play();
        setState(() {});
      } else if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[SwipeableChallenge] Video $index load error: $e');
      if (mounted) {
        setState(() => _videoErrors[index] = e.toString());
      }
    }
  }

  void _onPageChanged(int index) {
    // Pause previous
    _videoControllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
      _smileCount = 0;
      _isSmiling = false;
      _challengeFailed = false;
    });

    // Resume image stream if it was stopped
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isStreamingImages) {
      _cameraController!.startImageStream(_processCameraImage);
    }

    // Play new video (seek to start)
    final ctrl = _videoControllers[index];
    if (ctrl != null && ctrl.value.isInitialized) {
      ctrl.seekTo(Duration.zero);
      ctrl.play();
    } else {
      _initVideoAt(index);
    }

    // Pre-load next
    _initVideoAt(index + 1);

    // Dispose far-away controllers to save memory
    for (final k in _videoControllers.keys.toList()) {
      if ((k - index).abs() > 1) {
        _videoControllers[k]?.dispose();
        _videoControllers.remove(k);
      }
    }
  }

  // ── Face detection ────────────────────────────────────────────────────────
  void _processCameraImage(CameraImage image) async {
    if (_faceDetector == null || !_isModelReady || _challengeFailed || _processingFace) return;
    _processingFace = true;

    try {
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      final inputImage = _buildInputImage(image, camera);
      if (inputImage == null) {
        _processingFace = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) return;

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

              if (isCurrentlySmiling && !_isSmiling && !_challengeFailed) {
                setState(() {
                  _isSmiling = true;
                  _smileCount++;
                  _challengeFailed = true;
                });
                HapticFeedback.lightImpact();
                _videoControllers[_currentIndex]?.pause();
                _cameraController?.stopImageStream();
                _showFailDialog();
              } else if (!isCurrentlySmiling && _isSmiling) {
                setState(() => _isSmiling = false);
              }
            }
          }).catchError((e) {
            debugPrint('[SwipeableChallenge] TFLite error: $e');
          }).whenComplete(() {
            _isTFLiteProcessing = false;
          });
        }
      } else {
        if (_isSmiling && mounted) {
          setState(() => _isSmiling = false);
        }
      }
    } catch (_) {
    } finally {
      _processingFace = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, CameraDescription cam) {
    try {
      final width  = image.width;
      final height = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes.length > 1 ? image.planes[1] : null;
      final vPlane = image.planes.length > 2 ? image.planes[2] : null;

      final nv21 = Uint8List(width * height + (width * height) ~/ 2);

      for (int row = 0; row < height; row++) {
        final srcStart = row * yPlane.bytesPerRow;
        final dstStart = row * width;
        nv21.setRange(dstStart, dstStart + width, yPlane.bytes, srcStart);
      }

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

      final rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
      if (rotation == null) return null;

      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
    } catch (e) {
      debugPrint('[SwipeableChallenge] buildInputImage error: $e');
      return null;
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

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showFailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.sentiment_very_dissatisfied,
            size: 56, color: Colors.redAccent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kamu Senyum! 😄',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Smile count: $_smileCount',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _challengeFailed = false;
                _isSmiling = false;
              });
              _cameraController?.startImageStream(_processCameraImage);
              _videoControllers[_currentIndex]?.seekTo(Duration.zero);
              _videoControllers[_currentIndex]?.play();
            },
            child: const Text('Coba Lagi',
                style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.emoji_events, size: 56, color: Colors.amber),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Berhasil! 🎉',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Kamu berhasil tidak tersenyum!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _pageController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    for (final c in _videoControllers.values) c.dispose();
    _faceDetector?.close();
    _smileService.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('Challenge'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen swipeable video pages ────────────────────────────
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final ctrl = _videoControllers[index];
              final error = _videoErrors[index];

              // Tampilkan error jika video gagal dimuat
              if (error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 56, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text(
                          'Video gagal dimuat',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.contains('Timeout') ? 'Koneksi terlalu lambat.\nCoba gunakan WiFi.' : 'Periksa koneksi internet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          label: const Text('Coba Lagi', style: TextStyle(color: Colors.orange)),
                          onPressed: () {
                            if (mounted) setState(() => _videoErrors.remove(index));
                            _initVideoAt(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (ctrl == null || !ctrl.value.isInitialized) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 12),
                      Text('Memuat video...',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              }
              return _VideoPage(
                controller: ctrl,
                video: widget.videos[index],
                onVideoEnd: _showSuccessDialog,
              );
            },
          ),

          // ── Camera preview (top-right) ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                    color: _isSmiling ? Colors.redAccent : Colors.white,
                    width: 2.5),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _isSmiling
                        ? Colors.red.withOpacity(0.5)
                        : Colors.black38,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _isCameraInitialized
                    ? CameraPreview(_cameraController!)
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
              ),
            ),
          ),

          // ── Smile counter (top-left) ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSmiling ? Icons.tag_faces : Icons.mood,
                    color: _isSmiling ? Colors.redAccent : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Smile: $_smileCount',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // ── Video counter & swipe hint (bottom center) ──────────────────
          if (widget.videos.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.keyboard_arrow_up,
                      color: Colors.white38, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentIndex + 1} / ${widget.videos.length} video',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Single Video Page ─────────────────────────────────────────────────────────
class _VideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final ActiveVideoModel video;
  final VoidCallback onVideoEnd;

  const _VideoPage({
    required this.controller,
    required this.video,
    required this.onVideoEnd,
  });

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  bool _endCalled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideoState);
  }

  void _onVideoState() {
    if (!mounted) return;
    setState(() {});

    // Detect video end
    final ctrl = widget.controller;
    if (!_endCalled &&
        ctrl.value.position >= ctrl.value.duration &&
        ctrl.value.duration > Duration.zero) {
      _endCalled = true;
      widget.onVideoEnd();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onVideoState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Video fullscreen ─────────────────────────────────────────────
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width,
            height: ctrl.value.size.height,
            child: VideoPlayer(ctrl),
          ),
        ),

        // ── Bottom gradient ──────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 180,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // ── Video title & credit ─────────────────────────────────────────
        Positioned(
          left: 16,
          right: 16,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.video.title ?? 'Untitled',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              if (widget.video.creditUsername != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@${widget.video.creditUsername}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ),

        // ── Progress bar ─────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressIndicator(
            ctrl,
            allowScrubbing: false,
            colors: const VideoProgressColors(
              playedColor: Colors.orange,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white12,
            ),
          ),
        ),
      ],
    );
  }
}
