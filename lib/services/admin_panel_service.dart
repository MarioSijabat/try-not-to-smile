// lib/services/admin_panel_service.dart - FILE BARU!
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get submissions untuk inbox
  Stream<List<Map<String, dynamic>>> getVideoSubmissions() {
    return _db
        .collection('video_submissions')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data() != null)
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  ...data,
                  'id': doc.id,
                };
              })
              .toList(),
        );
  }

  // Get active videos untuk manager
  Stream<List<Map<String, dynamic>>> getActiveVideos() {
    return _db
        .collection('active_videos')
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data() != null)
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  ...data,
                  'docId': doc.id,
                };
              })
              .toList(),
        );
  }

  // Add video (setelah upload)
  Future<void> addActiveVideoComplete({
    required String title,
    required String videoUrl,
    required String creditUsername,
    required String publishedBy,
    String? thumbnailUrl,
    String? creditUid,
    List<String>? hashtags,
    int? durationSec,
  }) async {
    await _db.collection('active_videos').add({
      'title': title,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'credit_username': creditUsername,
      'credit_uid': creditUid,
      'hashtags': hashtags ?? [],
      'duration_sec': durationSec,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'published_by': publishedBy,
      'is_deleted': false,
      'deleted_at': null,
      'deleted_by': null,
      'expire_at': null,
    });
  }

  // Approve submission
  Future<void> approveSubmission(String submissionId) async {
    await _db.collection('video_submissions').doc(submissionId).update({
      'status': 'approved',
      'processed_at': FieldValue.serverTimestamp(),
    });
  }

  // Reject submission
  Future<void> rejectSubmission(String submissionId) async {
    await _db.collection('video_submissions').doc(submissionId).update({
      'status': 'rejected',
      'processed_at': FieldValue.serverTimestamp(),
    });
  }

  // Soft delete video
  Future<void> softDeleteVideo(String docId, String adminUid) async {
    await _db.collection('active_videos').doc(docId).update({
      'is_deleted': true,
      'deleted_at': FieldValue.serverTimestamp(),
      'deleted_by': adminUid,
      'expire_at': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
    });
  }
}