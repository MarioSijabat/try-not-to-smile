import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasmile/models/active_video_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Contoh: Get active videos (filter is_deleted false)
  Stream<List<ActiveVideoModel>> getActiveVideos() {
    return _db
        .collection('active_videos')
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActiveVideoModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<void> submitVideo(
    String uid,
    String username,
    String link,
    String category,
  ) async {
    await _db.collection('video_submissions').add({
      'submitted_by_uid': uid,
      'submitted_by_username': username,
      'original_link': link,
      'category_suggestion': category,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'processed_at': null,
    });
  }

  // Tambah methods lain: addUser, submitVideo, etc.
}
