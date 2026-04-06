// lib/services/face_detection_service.dart
//
// Service inferensi smile detection.
// Model AKTIF: model_mobilenet_quantized_dynamic.tflite
// ⚠️  MODE BENCHMARK — throttle dinonaktifkan untuk pengambilan data skripsi
// Input : [1, 224, 224, 3] Float32
// Output: [1, 1]            Float32 — sigmoid binary
//
// Model input should strictly be raw RGB [0-255] as Z-score is inside the graph.




import 'dart:ui' show Rect;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
// image package removed — preprocessing now uses direct YUV sampling
import 'package:tflite_flutter/tflite_flutter.dart';


class SmileDetectionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  String modelInfo = 'Belum diinisialisasi';

  // Throttle (Pembatas FPS)
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  
  // =========================================================================
  // ⚡ PENGATURAN MODE PENGUJIAN SKRIPSI (PILIH SALAH SATU)
  // =========================================================================
  
  // [1] MODE BENCHMARK (Uncapped FPS murni, tanpa di rem - UNTUK AMBIL DATA SKRIPSI)
  static const int _throttleMs = 0; 

  // [2] MODE PRODUKSI / RILIS APLIKASI (Capped di 12.5 FPS agar HP tetap dingin)
  // static const int _throttleMs = 80;
  // =========================================================================



  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // Threads=4: manfaatkan lebih banyak core CPU untuk invoke() lebih cepat.
      // CPH2375 (MediaTek/Snapdragon) biasanya punya 8 core.
      final options = InterpreterOptions()..threads = 4;
      
      // Mengaktifkan Hardware Delegate (NNAPI) di Android
      // [!] SEMENTARA DI-DISABLE KARENA BUG OS LAMA [!]
      // Banyak device Vivo / MediaTek lama memiliki driver NNAPI yang nge-bug 
      // saat mengeksekusi TFLite dengan Dynamic Range Quantization,
      // sehingga semua layer di-bypass jadi nol dan output konstan "0.130".
      // if (Platform.isAndroid) {
      //   options.useNnApiForAndroid = true;
      // }

      _interpreter = await Interpreter.fromAsset(
        'assets/model_mobilenet_quantized_dynamic.tflite',
        options: options,
      );
      _isInitialized = true;

      final inT  = _interpreter!.getInputTensor(0);
      final outT = _interpreter!.getOutputTensor(0);
      modelInfo = 'IN:${inT.shape} ${inT.type} | OUT:${outT.shape} ${outT.type}';
      debugPrint('[SmileDetectionService] ✅ Model loaded. $modelInfo');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[SmileDetectionService] ❌ Failed to load model: $e');
    }
  }

  /// Deteksi senyum dari frame kamera pada region wajah [faceBounds].
  /// Model output: [1, 1] sigmoid — satu nilai float antara 0.0 (tidak senyum) hingga 1.0 (senyum).
  /// Return Map {'smileScore': double} atau null jika throttled/error.
  Future<Map<String, double>?> detectSmile(
    CameraImage image,
    Rect faceBounds,
    int sensorOrientation,
  ) async {
    if (!_isInitialized || _interpreter == null) return null;

    final now = DateTime.now();
    // Bypass throttle sama sekali jika _throttleMs di-set ke 0 (Mode Benchmark)
    if (_throttleMs > 0 && now.difference(_lastInference).inMilliseconds < _throttleMs) {
      return null;
    }
    _lastInference = now;

    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes.length > 1 ? image.planes[1] : null;
      final vPlane = image.planes.length > 2 ? image.planes[2] : null;
      
      final msg = _IsolateData(
        imgW: image.width,
        imgH: image.height,
        left: faceBounds.left,
        top: faceBounds.top,
        right: faceBounds.right,
        bottom: faceBounds.bottom,
        sensorOrientation: sensorOrientation,
        yBytes: yPlane.bytes,
        uBytes: uPlane?.bytes,
        vBytes: vPlane?.bytes,
        yRowStride: yPlane.bytesPerRow,
        uvRowStride: uPlane?.bytesPerRow ?? 0,
        uvPixelStride: uPlane?.bytesPerPixel ?? 1,
      );

      // 1. Preprocessing di Isolate (YUV→RGB, crop, resize 224×224)
      final tPreStart = DateTime.now().millisecondsSinceEpoch;
      final _IsolateResult result = await compute(_preprocessInIsolate, msg);
      final Float32List flatInput = result.float32List;
      final tPreDone = DateTime.now().millisecondsSinceEpoch;

      // ── Guard: cegah crash jika interpreter di-dispose saat isolate berjalan ──
      if (!_isInitialized || _interpreter == null) return null;

      // 2. Tulis data ke input tensor
      final inputTensor = _interpreter!.getInputTensor(0);
      
      // ── MENCEGAH CRASH (SIGSEGV): Periksa kecocokan ukuran memori ──
      int expectedElements = 1;
      for (var s in inputTensor.shape) {
        if (s > 0) expectedElements *= s;
      }
      
      if (flatInput.length != expectedElements) {
        debugPrint(
          '[SmileDetection] ❌ CRASH DENCEGAH: Ukuran model tidak cocok!\n'
          'Model minta: $expectedElements angka float (Shape: ${inputTensor.shape})\n'
          'Tapi kita beri: ${flatInput.length} angka float (224x224x3).'
        );
        return null;
      }

      inputTensor.setTo(flatInput.buffer.asUint8List(
        flatInput.offsetInBytes,
        flatInput.lengthInBytes,
      ));

      // 4. Jalankan TFLite inferensi — ukur waktu murni invoke()
      final tInferStart = DateTime.now().millisecondsSinceEpoch;
      Timeline.startSync('TFLite_Invoke_Model');
      _interpreter!.invoke();
      Timeline.finishSync();
      final tInferDone = DateTime.now().millisecondsSinceEpoch;
      
      // 3. Ambil outputTensor HARUS SETELAH invoke 
      // (Mencegah Null Pointer C++ jika model melakukan re-alokasi tensor dinamis)
      final outputTensor = _interpreter!.getOutputTensor(0);

      // ── Log breakdown waktu TFLite secara detail ──────────────────────
      final preMs   = tPreDone - tPreStart;
      final inferMs = tInferDone - tInferStart;
      final totalMs = tInferDone - tPreStart;
      debugPrint(
        '[TFLITE_PERF] Preprocess:${preMs}ms | Invoke:${inferMs}ms | Total:${totalMs}ms',
      );

      // 5. Baca output SETELAH invoke
      final outputData = outputTensor.data.buffer.asFloat32List();
      final double rawOutput = outputData[0];

      // Gunakan rawOutput langsung sebagai smileScore, tidak di-flip
      final double smileScore = rawOutput.clamp(0.0, 1.0);

      debugPrint(
        '[SmileDetection] 🧠 rawOutput=${rawOutput.toStringAsFixed(4)} '
        'smileScore=${smileScore.toStringAsFixed(4)}',
      );

      return {'smileScore': smileScore};
    } catch (e, st) {
      debugPrint('[SmileDetection] ❌ Error: $e\n$st');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

// Data holder untuk dikirim ke Isolate
class _IsolateData {
  final int imgW;
  final int imgH;
  final double left, top, right, bottom;
  final int sensorOrientation;
  final Uint8List yBytes;
  final Uint8List? uBytes;
  final Uint8List? vBytes;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;

  _IsolateData({
    required this.imgW,
    required this.imgH,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.sensorOrientation,
    required this.yBytes,
    this.uBytes,
    this.vBytes,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });
}

/// Hasil dari Background Isolate: float32 input tensor + JPEG bytes untuk debug.
class _IsolateResult {
  final Float32List float32List;
  final Uint8List debugJpegBytes;

  _IsolateResult({required this.float32List, required this.debugJpegBytes});
}

/// Preprocessing OPTIMIZED — direct 224×224 YUV sampling.
///
/// Pendekatan lama: konversi full frame (e.g. 640×480 = 307,200 px) ke img.Image
///   → rotate → crop face → resize 224×224  → ~250ms
///
/// Pendekatan baru: hitung koordinat tepat di YUV buffer asli untuk masing-masing
///   dari 224×224 = 50,176 titik output menggunakan inverse coordinate transform.
///   → tidak ada alokasi img.Image, tidak ada proses pixel tidak diperlukan
///   → estimasi 4–6× lebih cepat.
///
/// Koordinat wajah (left,top,right,bottom) dari ML Kit ada di ruang gambar
/// yang SUDAH dirotasi (display-orientation). Kita inverse transform balik ke
/// koordinat original YUV buffer.
_IsolateResult _preprocessInIsolate(_IsolateData msg) {
  Timeline.startSync('Preprocess_YUV_to_RGB_Isolate');
  final int imgW = msg.imgW;   // lebar frame kamera asli (kolom YUV)
  final int imgH = msg.imgH;   // tinggi frame kamera asli (baris YUV)
  final int so   = msg.sensorOrientation;

  // Dimensi gambar yang sudah dirotasi (coordinate space ML Kit face bbox)
  final int rotW = (so == 90 || so == 270) ? imgH : imgW;
  final int rotH = (so == 90 || so == 270) ? imgW : imgH;

  // Clamp face bounding box ke batas gambar yang valid
  final double fL = msg.left.clamp(0.0, rotW - 1.0);
  final double fT = msg.top.clamp(0.0, rotH - 1.0);
  final double fR = msg.right.clamp(fL + 1.0, rotW.toDouble());
  final double fB = msg.bottom.clamp(fT + 1.0, rotH.toDouble());

  // Step size per pixel output 224×224
  final double stepX = (fR - fL) / 224.0;
  final double stepY = (fB - fT) / 224.0;

  final Float32List outBuf = Float32List(224 * 224 * 3);
  int outIdx = 0;

  final bool hasChroma = msg.uBytes != null && msg.vBytes != null;

  // ── Inverse coordinate transforms ─────────────────────────────────────
  // Untuk rotasi 90° CW  (angle=90):  new(rx,ry) = orig(ry, imgH-1-rx)
  //   → inverse: orig_col=ry, orig_row=imgH-1-rx
  // Untuk rotasi 270° CW (angle=-90): new(rx,ry) = orig(imgW-1-ry, rx)
  //   → inverse: orig_col=imgW-1-ry, orig_row=rx
  // Untuk rotasi 180°   (angle=180):  new(rx,ry) = orig(imgW-1-rx, imgH-1-ry)
  //   → inverse: orig_col=imgW-1-rx, orig_row=imgH-1-ry
  // Untuk 0°                          orig_col=rx, orig_row=ry

  for (int py = 0; py < 224; py++) {
    final double ry = fT + (py + 0.5) * stepY; // baris dalam rotated frame

    for (int px = 0; px < 224; px++) {
      final double rx = fL + (px + 0.5) * stepX; // kolom dalam rotated frame

      // Transformasi ke koordinat original YUV
      int ox, oy; // ox=kolom, oy=baris dalam original frame
      switch (so) {
        case 90:
          ox = ry.round().clamp(0, imgW - 1);
          oy = (imgH - 1.0 - rx).round().clamp(0, imgH - 1);
          break;
        case 270:
          ox = (imgW - 1.0 - ry).round().clamp(0, imgW - 1);
          oy = rx.round().clamp(0, imgH - 1);
          break;
        case 180:
          ox = (imgW - 1.0 - rx).round().clamp(0, imgW - 1);
          oy = (imgH - 1.0 - ry).round().clamp(0, imgH - 1);
          break;
        default: // 0°
          ox = rx.round().clamp(0, imgW - 1);
          oy = ry.round().clamp(0, imgH - 1);
          break;
      }

      // ── Baca YUV dan konversi ke RGB ────────────────────────────────
      final int yIdx = oy * msg.yRowStride + ox;
      final int yVal = yIdx < msg.yBytes.length ? msg.yBytes[yIdx] : 0;
      int r = yVal, g = yVal, b = yVal;

      if (hasChroma) {
        final int uvIdx =
            (oy >> 1) * msg.uvRowStride + (ox >> 1) * msg.uvPixelStride;
        if (uvIdx < msg.uBytes!.length && uvIdx < msg.vBytes!.length) {
          final int u = msg.uBytes![uvIdx] - 128;
          final int v = msg.vBytes![uvIdx] - 128;
          // BT.601 integer YUV→RGB (<<10 scaling: 1.402→1436, 0.344→352,
          //                          0.714→731, 1.772→1815)
          r = (yVal + ((1436 * v) >> 10)).clamp(0, 255);
          g = (yVal - ((352  * u) >> 10) - ((731 * v) >> 10)).clamp(0, 255);
          b = (yVal + ((1815 * u) >> 10)).clamp(0, 255);
        }
      }

      // ── Tulis ke output buffer (raw pixels, Z-score baked in model) ─
      outBuf[outIdx++] = r.toDouble();
      outBuf[outIdx++] = g.toDouble();
      outBuf[outIdx++] = b.toDouble();
    }
  }

  Timeline.finishSync();
  return _IsolateResult(float32List: outBuf, debugJpegBytes: Uint8List(0));
}