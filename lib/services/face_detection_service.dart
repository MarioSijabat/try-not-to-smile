// lib/services/face_detection_service.dart
//
// Service inferensi MobileNet smile detection.
// Model: mobilenet_quantized_dynamic.tflite
// Input : [1, 224, 224, 3] Float32 — Z-Score normalized (baked in model)
// Output: [1, 1]            Float32 — sigmoid binary
//
// Model input should strictly be raw RGB [0-255] as Z-score is inside the graph.

import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tasmile/utils/debug_image_saver.dart';

class SmileDetectionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  String modelInfo = 'Belum diinisialisasi';

  // Throttle: hanya proses 1 frame per 200ms
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _inputSize = 224;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      
      // Mengaktifkan Hardware Delegate (NNAPI) di Android
      // [!] SEMENTARA DI-DISABLE KARENA BUG OS LAMA [!]
      // Banyak device Vivo / MediaTek lama memiliki driver NNAPI yang nge-bug 
      // saat mengeksekusi TFLite dengan Dynamic Range Quantization,
      // sehingga semua layer di-bypass jadi nol dan output konstan "0.130".
      // if (Platform.isAndroid) {
      //   options.useNnApiForAndroid = true;
      // }

      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_quantized_dynamic.tflite',
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
    if (now.difference(_lastInference).inMilliseconds < 200) return null;
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

      // 1. Terima hasil dari Isolate (Float32List flat 150528 elemen + JPEG bytes)
      final _IsolateResult result = await compute(_preprocessInIsolate, msg);
      final Float32List flatInput = result.float32List;

      // ── Guard: cegah crash jika interpreter di-dispose saat isolate berjalan ──
      if (!_isInitialized || _interpreter == null) return null;

      // ── [DEBUG] Simpan gambar 224×224 ke Galeri (hanya 1 kali per sesi) ──
      // saveDebugJpegBytesToGallery(result.debugJpegBytes); // Disabled as requested
      // ── [END DEBUG] — hapus blok di atas setelah debug selesai ──────────

      // 2. Diagnostic: pastikan rentang nilai sesuai MobileNet [-1, 1]
      final int centerIdx = (224 * 112 + 112) * 3;
      debugPrint(
        '[SmileDetection] 🔬 FlatInput[0..4]='
        '[${flatInput[0].toStringAsFixed(4)}, '
        '${flatInput[1].toStringAsFixed(4)}, '
        '${flatInput[2].toStringAsFixed(4)}, '
        '${flatInput[3].toStringAsFixed(4)}, '
        '${flatInput[4].toStringAsFixed(4)}] '
        'center=${flatInput[centerIdx].toStringAsFixed(4)}',
      );

      // 3. Tulis data ke input tensor via setTo() — menulis raw bytes TANPA
      //    mengubah shape tensor. interpreter.run() tidak bisa dipakai karena
      //    dia menyimpulkan shape dari Float32List (1D [150528] bukan [1,224,224,3]).
      final inputTensor = _interpreter!.getInputTensor(0);
      inputTensor.setTo(flatInput.buffer.asUint8List(
        flatInput.offsetInBytes,
        flatInput.lengthInBytes,
      ));

      // 4. Cache outputTensor SEBELUM invoke (mencegah null pointer race condition)
      final outputTensor = _interpreter!.getOutputTensor(0);

      // 5. Jalankan inferensi
      _interpreter!.invoke();

      // 6. Baca output SETELAH invoke
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

/// Fungsi Top-level untuk Preprocessing di Background Isolate.
/// Konversi YUV420 → crop wajah → RGB → resize 224×224 → Z-Score normalization.
/// Output: _IsolateResult berisi Float32List + JPEG bytes debug.
_IsolateResult _preprocessInIsolate(_IsolateData msg) {
  // 1. Ekstrak YUV mentah menjadi img.Image secara utuh (Tanpa rotasi/crop dulu)
  // Ini mencegah error gambar bergaris (scrambled) akibat stride mismatch
  img.Image rawImage = img.Image(width: msg.imgW, height: msg.imgH);
  
  for (int y = 0; y < msg.imgH; y++) {
    for (int x = 0; x < msg.imgW; x++) {
      final yIdx = y * msg.yRowStride + x;
      final yVal = msg.yBytes[yIdx];

      int r = yVal, g = yVal, b = yVal;

      if (msg.uBytes != null && msg.vBytes != null) {
        final uvIdx = (y ~/ 2) * msg.uvRowStride + (x ~/ 2) * msg.uvPixelStride;
        final uVal = msg.uBytes![uvIdx] - 128;
        final vVal = msg.vBytes![uvIdx] - 128;

        r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        g = (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
        b = (yVal + 1.772 * uVal).round().clamp(0, 255);
      }
      rawImage.setPixelRgb(x, y, r, g, b);
    }
  }

  // 2. Putar gambar agar tegak lurus
  img.Image rotatedImage;
  if (msg.sensorOrientation == 90) {
    rotatedImage = img.copyRotate(rawImage, angle: 90);
  } else if (msg.sensorOrientation == 270) {
    rotatedImage = img.copyRotate(rawImage, angle: -90);
  } else if (msg.sensorOrientation == 180) {
    rotatedImage = img.copyRotate(rawImage, angle: 180);
  } else {
    rotatedImage = rawImage;
  }

  // 3. Lakukan Cropping Wajah dengan library bawaan (Lebih aman)
  // Pastikan koordinat tidak out of bounds
  int cropX = msg.left.toInt().clamp(0, rotatedImage.width - 1);
  int cropY = msg.top.toInt().clamp(0, rotatedImage.height - 1);
  int cropW = (msg.right - msg.left).toInt().clamp(1, rotatedImage.width - cropX);
  int cropH = (msg.bottom - msg.top).toInt().clamp(1, rotatedImage.height - cropY);

  img.Image croppedImage = img.copyCrop(
    rotatedImage,
    x: cropX,
    y: cropY,
    width: cropW,
    height: cropH,
  );

  // 4. Resize ke 224x224
  img.Image resizedImage = img.copyResize(
    croppedImage,
    width: 224,
    height: 224,
    interpolation: img.Interpolation.linear,
  );

  // 5. Z-Score Normalization & Konversi ke Flat Float32List
  final Float32List float32list = Float32List(224 * 224 * 3);
  int bufferIndex = 0;

  // ── Input ke TFLite: RAW PIXELS [0 - 255] dalam bentuk Float32 ──
  // Z-Score sudah tertanam (baked in) di dalam graph model TFLite itu sendiri.
  // Melakukan double normalization akan merusak tensor 
  // (contoh: jadi konstan 0.05).

  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = resizedImage.getPixel(x, y);

      float32list[bufferIndex++] = pixel.r.toDouble();
      float32list[bufferIndex++] = pixel.g.toDouble();
      float32list[bufferIndex++] = pixel.b.toDouble();
    }
  }

  // [DEBUG] Encode resizedImage → JPEG bytes di Isolate (pure Dart, aman)
  // Bytes ini akan dikirim ke Main Thread untuk disimpan ke Galeri.
  final Uint8List jpegBytes = Uint8List.fromList(
    img.encodeJpg(resizedImage, quality: 95),
  );

  return _IsolateResult(float32List: float32list, debugJpegBytes: jpegBytes);
}