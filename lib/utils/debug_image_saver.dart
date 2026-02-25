// lib/utils/debug_image_saver.dart
//
// Utility untuk menyimpan gambar debug (JPEG bytes 224x224) ke Galeri HP.
// Dirancang agar hanya menyimpan SATU gambar per sesi — mencegah spam galeri.
//
// PENGGUNAAN:
//   saveDebugJpegBytesToGallery(jpegBytes); // fire-and-forget
//   resetDebugImageSaverFlag();             // reset jika ingin simpan lagi

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

/// Flag global: pastikan hanya 1 gambar tersimpan per sesi app.
bool _hasSavedDebugImage = false;

/// Simpan [jpegBytes] (hasil img.encodeJpg dari resizedImage 224×224) ke Galeri.
///
/// ⚠️  HARUS dipanggil dari Main Thread — plugin `gal` tidak bisa diakses
///     dari Background Isolate. Encode JPEG di Isolate, kirim bytes-nya ke sini.
///
/// - Hanya akan menyimpan SATU kali selama sesi berlangsung.
/// - Gambar tersimpan di album [albumName] (default: "Debug ML").
Future<void> saveDebugJpegBytesToGallery(
  Uint8List jpegBytes, {
  String albumName = 'Debug ML',
}) async {
  // ── Guard: hanya simpan 1 kali per sesi ──────────────────────────────────
  if (_hasSavedDebugImage) return;
  _hasSavedDebugImage = true; // Set lebih dulu agar tidak ada race condition

  try {
    // ── 1. Cek & minta izin akses Galeri ─────────────────────────────────
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        debugPrint('[DebugSaver] ❌ Izin galeri ditolak. Gambar tidak disimpan.');
        _hasSavedDebugImage = false; // Reset agar bisa coba lagi
        return;
      }
    }

    // ── 2. Simpan JPEG bytes langsung ke Galeri via package `gal` ─────────
    await Gal.putImageBytes(jpegBytes, album: albumName);

    debugPrint('[DebugSaver] ✅ Gambar debug 224×224 tersimpan ke album "$albumName".');
  } catch (e) {
    debugPrint('[DebugSaver] ❌ Gagal menyimpan gambar: $e');
    _hasSavedDebugImage = false; // Reset agar bisa coba lagi jika error
  }
}

/// Reset flag — panggil ini jika ingin menyimpan gambar baru
/// (misalnya saat memulai sesi debug baru).
void resetDebugImageSaverFlag() {
  _hasSavedDebugImage = false;
  debugPrint('[DebugSaver] 🔄 Flag di-reset. Siap menyimpan gambar berikutnya.');
}
