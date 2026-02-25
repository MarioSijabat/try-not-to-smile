// lib/screens/smile_test_screen.dart
// Layar demo untuk testing deteksi senyum secara real-time
// Tidak memerlukan video dari Firebase Storage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/face_detection_service.dart';
import '../widgets/face_detector_painter.dart';

class SmileTestScreen extends StatefulWidget {
  const SmileTestScreen({Key? key}) : super(key: key);

  @override
  State<SmileTestScreen> createState() => _SmileTestScreenState();
}

class _SmileTestScreenState extends State<SmileTestScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  List<CameraDescription>? _cameras;
  FaceDetector? _mlkitDetector;
  final SmileDetectionService _mobileNet = SmileDetectionService();

  bool _isCameraReady = false;
  bool _isModelReady = false;
  bool _isProcessing = false;
  bool _isTFLiteProcessing = false;

  // Skor deteksi — hanya dari MobileNet
  double _mbSmileScore = 0.0;
  bool   _faceDetected = false;
  String _debugInfo = 'Menunggu frame...';

  List<Face> _faces = [];
  Size? _imageSize;
  InputImageRotation? _rotation;

  // Animasi
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const double _smileThreshold = 0.65;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    // ML Kit hanya untuk deteksi posisi wajah (bounding box).
    // Smile detection sepenuhnya dilakukan oleh MobileNet.
    _mlkitDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,  // tidak perlu smile prob dari ML Kit
        minFaceSize: 0.05,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    // Inisialisasi MobileNet (paralel dengan kamera)
    _mobileNet.initialize().then((_) {
      if (mounted) setState(() => _isModelReady = _mobileNet.isInitialized);
    });

    // Inisialisasi kamera
    _cameras = await availableCameras();
    final front = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    _camera = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _camera!.initialize();
    await _camera!.startImageStream(_onFrame);
    if (mounted) setState(() => _isCameraReady = true);
  }

  void _onFrame(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    try {
      final cam = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // ── Fix: Bangun bytes NV21 yang valid ──────────────────────────────
      // Hanya 2 plane yang dibutuhkan: Y + interleaved VU
      final inputImage = _buildInputImage(image, cam);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // ML Kit: deteksi wajah saja (hanya untuk bounding box)
      final faces = await _mlkitDetector!.processImage(inputImage);

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

      // Rule 2: Immediately update UI state for the bounding box
      if (mounted) {
        setState(() {
          _faceDetected = largestFace != null;
          _faces = largestFace != null ? [largestFace] : [];
          if (inputImage.metadata != null) {
            _imageSize = inputImage.metadata!.size;
            _rotation = inputImage.metadata!.rotation;
          }
        });
      }

      // Rule 3: Trigger TFLite without blocking the next camera frame
      if (largestFace != null && _isModelReady && !_isTFLiteProcessing) {
        _isTFLiteProcessing = true;
        _mobileNet.detectSmile(
          image,
          largestFace.boundingBox,
          cam.sensorOrientation,
        ).then((result) {
          if (result != null && mounted) {
            setState(() {
              _mbSmileScore = result['smileScore'] ?? 0.0;
            });
            if (_mbSmileScore > _smileThreshold) HapticFeedback.lightImpact();
          }
        }).catchError((e) {
          debugPrint('[SmileTest] TFLite error: $e');
        }).whenComplete(() {
          _isTFLiteProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('[SmileTest] Frame error: $e');
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
      final rotation =
          InputImageRotationValue.fromRawValue(cam.sensorOrientation);
      if (rotation == null) return null;

      final dbg = 'NV21 ${width}x$height rot:$rotation\n${nv21.length}B (was ${(() {
        int total = 0;
        for (final p in image.planes) total += p.bytes.length;
        return total;
      })()}B)';

      if (mounted) setState(() => _debugInfo = dbg);
      debugPrint('[SmileTest] $dbg');

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
      debugPrint('[SmileTest] InputImage build error: $e');
      return null;
    }
  }

  bool get _isSmiling => _mbSmileScore > _smileThreshold;

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _camera?.stopImageStream();
    _camera?.dispose();
    _mlkitDetector?.close();
    _mobileNet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SMILE DETECTOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  // Status model
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isModelReady ? Colors.greenAccent.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isModelReady ? Colors.greenAccent : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.psychology,
                          color: _isModelReady ? Colors.greenAccent : Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isModelReady ? 'Model OK' : 'Loading...',
                          style: TextStyle(
                            color: _isModelReady ? Colors.greenAccent : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Camera Preview ─────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) => Transform.scale(
                    scale: _isSmiling ? _pulseAnim.value : 1.0,
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: !_faceDetected
                            ? Colors.white24
                            : _isSmiling
                                ? Colors.redAccent
                                : Colors.greenAccent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSmiling
                              ? Colors.red.withOpacity(0.4)
                              : Colors.green.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: _isCameraReady
                          ? (_camera!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: 1 / _camera!.value.aspectRatio,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CameraPreview(_camera!),
                                      if (_faces.isNotEmpty && _imageSize != null && _rotation != null)
                                        CustomPaint(
                                          painter: FaceDetectorPainter(
                                            _faces,
                                            _imageSize!,
                                            _rotation!,
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : const SizedBox())
                          : const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.orange)),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Status Wajah ───────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_faceDetected
                    ? Colors.white10
                    : _isSmiling
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_faceDetected
                      ? Colors.white24
                      : _isSmiling
                          ? Colors.redAccent
                          : Colors.greenAccent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    !_faceDetected
                        ? '😶  Wajah tidak terdeteksi'
                        : _isSmiling
                            ? '😄  SENYUM TERDETEKSI!'
                            : '😐  Ekspresi netral',
                    style: TextStyle(
                      color: !_faceDetected
                          ? Colors.white54
                          : _isSmiling
                              ? Colors.redAccent
                              : Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Score Card ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ScoreCard(
                label: 'MobileNet Smile Score',
                subtitle: 'Model custom (sigmoid)',
                score: _mbSmileScore,
                color: Colors.orange,
                isReady: _isModelReady,
              ),
            ),

            const SizedBox(height: 12),

            // ── Threshold info ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Threshold senyum: ${(_smileThreshold * 100).toInt()}%',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            // Debug info
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _debugInfo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score Card Widget ─────────────────────────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final double score;
  final Color color;
  final bool isReady;

  const _ScoreCard({
    required this.label,
    required this.subtitle,
    required this.score,
    required this.color,
    this.isReady = true,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              if (!isReady)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5,
                      color: Colors.orange),
                ),
            ],
          ),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isReady ? '$pct%' : 'Loading...',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
