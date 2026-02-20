// lib/services/video_storage_service.dart

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class VideoStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadVideo(Uint8List videoBytes, String fileName) async {
    try {
      print('🚀 Starting video upload...');
      print('📁 File: $fileName');
      print('📦 Size: ${videoBytes.length} bytes');
      
      // Validasi
      if (!fileName.toLowerCase().endsWith('.mp4')) {
        throw Exception('Hanya file MP4 yang diperbolehkan');
      }
      
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (videoBytes.length > maxSize) {
        throw Exception('File terlalu besar. Maksimal 10MB');
      }
      
      // Generate unique filename
      final uniqueId = _uuid.v4().substring(0, 8);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-]'), '_');
      final uniqueFileName = 'videos/admin_${timestamp}_${uniqueId}_$safeFileName';
      
      print('📌 Storage path: $uniqueFileName');
      
      // Create reference
      final storageRef = _storage.ref().child(uniqueFileName);
      
      // Metadata
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploaded_by': 'admin',
          'original_name': fileName,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload dengan retry logic
      try {
        final uploadTask = storageRef.putData(videoBytes, metadata);
        
        // Progress monitoring
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
        });
        
        await uploadTask;
        
      } catch (e) {
        print('❌ Upload failed: $e');
        rethrow;
      }
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      print('✅ Upload successful!');
      print('🔗 URL: $downloadUrl');
      
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error in uploadVideo: $e');
      rethrow;
    }
  }
}