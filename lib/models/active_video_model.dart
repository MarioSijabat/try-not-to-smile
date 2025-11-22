// lib/models/active_video_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveVideoModel {
  final String? docId;
  final String? title;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? creditUsername;
  final String? creditUid;
  final List<String>? hashtags;
  final int? durationSec;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? publishedBy;
  final bool? isDeleted;
  final Timestamp? deletedAt;
  final String? deletedBy;
  final Timestamp? expireAt;

  ActiveVideoModel({
    this.docId,
    this.title,
    this.videoUrl,
    this.thumbnailUrl,
    this.creditUsername,
    this.creditUid,
    this.hashtags,
    this.durationSec,
    this.createdAt,
    this.updatedAt,
    this.publishedBy,
    this.isDeleted,
    this.deletedAt,
    this.deletedBy,
    this.expireAt,
  });

  // From JSON (Firestore data)
  factory ActiveVideoModel.fromJson(Map<String, dynamic> json) {
    return ActiveVideoModel(
      docId: json['doc_id'] as String?,
      title: json['title'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      creditUsername: json['credit_username'] as String?,
      creditUid: json['credit_uid'] as String?,
      hashtags: (json['hashtags'] as List<dynamic>?)?.cast<String>(),
      durationSec: json['duration_sec'] as int?,
      createdAt: json['created_at'] as Timestamp?,
      updatedAt: json['updated_at'] as Timestamp?,
      publishedBy: json['published_by'] as String?,
      isDeleted: json['is_deleted'] as bool?,
      deletedAt: json['deleted_at'] as Timestamp?,
      deletedBy: json['deleted_by'] as String?,
      expireAt: json['expire_at'] as Timestamp?,
    );
  }

  // To JSON (untuk simpan ke Firestore jika perlu)
  Map<String, dynamic> toJson() {
    return {
      'doc_id': docId,
      'title': title,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'credit_username': creditUsername,
      'credit_uid': creditUid,
      'hashtags': hashtags,
      'duration_sec': durationSec,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'published_by': publishedBy,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt,
      'deleted_by': deletedBy,
      'expire_at': expireAt,
    };
  }
}
