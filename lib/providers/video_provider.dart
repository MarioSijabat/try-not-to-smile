// lib/providers/video_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/active_video_model.dart';
import '../services/admin_panel_service.dart';

class VideoProvider extends ChangeNotifier {
  final AdminPanelService _service = AdminPanelService();
  List<ActiveVideoModel> videos = [];
  bool isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  VideoProvider() {
    _sub = _service.getActiveVideos().listen((list) {
      videos = list.map((m) {
        return ActiveVideoModel(
          docId: (m['docId'] ?? m['doc_id'])?.toString(),
          title: m['title'] as String?,
          videoUrl: m['video_url'] as String?,
          thumbnailUrl: m['thumbnail_url'] as String?,
          creditUsername: m['credit_username'] as String?,
          creditUid: m['credit_uid'] as String?,
          hashtags: (m['hashtags'] as List<dynamic>?)?.cast<String>(),
          durationSec: m['duration_sec'] as int?,
          createdAt: m['created_at'] as Timestamp?,
          updatedAt: m['updated_at'] as Timestamp?,
          publishedBy: m['published_by'] as String?,
          isDeleted: m['is_deleted'] as bool?,
          deletedAt: m['deleted_at'] as Timestamp?,
          deletedBy: m['deleted_by'] as String?,
          expireAt: m['expire_at'] as Timestamp?,
        );
      }).toList();
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
