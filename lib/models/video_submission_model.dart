// lib/models/video_submission_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VideoSubmissionModel {
  final String? id;
  final String? submittedByUid;
  final String? submittedByUsername;
  final String? originalLink;
  final String? categorySuggestion;
  final String? status;
  final Timestamp? createdAt;
  final Timestamp? processedAt;

  VideoSubmissionModel({
    this.id,
    this.submittedByUid,
    this.submittedByUsername,
    this.originalLink,
    this.categorySuggestion,
    this.status,
    this.createdAt,
    this.processedAt,
  });

  // From Firestore document
  factory VideoSubmissionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return VideoSubmissionModel(
      id: doc.id,
      submittedByUid: data?['submitted_by_uid'] as String?,
      submittedByUsername: data?['submitted_by_username'] as String?,
      originalLink: data?['original_link'] as String?,
      categorySuggestion: data?['category_suggestion'] as String?,
      status: data?['status'] as String?,
      createdAt: data?['created_at'] as Timestamp?,
      processedAt: data?['processed_at'] as Timestamp?,
    );
  }

  // To JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'submitted_by_uid': submittedByUid,
      'submitted_by_username': submittedByUsername,
      'original_link': originalLink,
      'category_suggestion': categorySuggestion,
      'status': status,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'processed_at': processedAt,
    };
  }

  // Copy with
  VideoSubmissionModel copyWith({
    String? id,
    String? submittedByUid,
    String? submittedByUsername,
    String? originalLink,
    String? categorySuggestion,
    String? status,
    Timestamp? createdAt,
    Timestamp? processedAt,
  }) {
    return VideoSubmissionModel(
      id: id ?? this.id,
      submittedByUid: submittedByUid ?? this.submittedByUid,
      submittedByUsername: submittedByUsername ?? this.submittedByUsername,
      originalLink: originalLink ?? this.originalLink,
      categorySuggestion: categorySuggestion ?? this.categorySuggestion,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}