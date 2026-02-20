// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a video request to `video_submissions` collection.
  Future<void> submitVideo(
    String userUid,
    String username,
    String originalLink,
    String category,
  ) async {
    final payload = {
      'submitted_by_uid': userUid,
      'submitted_by_username': username,
      'original_link': originalLink,
      'category_suggestion': category,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'processed_at': null,
    };

    await _db.collection('video_submissions').add(payload);
  }
}