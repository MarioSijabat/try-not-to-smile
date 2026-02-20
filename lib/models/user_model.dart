// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? uid;
  final String? name;
  final String? email;
  final Timestamp? createdAt;
  final String? profileImageUrl;
  final int? totalScore;
  final int? challengesCompleted;
  final String? role; // Tambah role: 'guest', 'user', 'admin'

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.createdAt,
    this.profileImageUrl,
    this.totalScore,
    this.challengesCompleted,
    this.role = 'user', // Default 'user' untuk registered
  });

  // From Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserModel(
      uid: doc.id,
      name: data?['username'] as String? ?? data?['name'] as String?, // Support both
      email: data?['email'] as String?,
      createdAt: data?['created_at'] as Timestamp? ?? data?['createdAt'] as Timestamp?,
      profileImageUrl: data?['profileImageUrl'] as String?,
      totalScore: data?['totalScore'] as int?,
      challengesCompleted: data?['challengesCompleted'] as int?,
      role: data?['role'] as String? ?? 'user',
    );
  }

  // To JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid, // Tambah uid agar tersimpan
      'username': name, // Gunakan 'username' sesuai schema database
      'email': email,
      'created_at': createdAt ?? FieldValue.serverTimestamp(), // Gunakan server timestamp
      'last_login': FieldValue.serverTimestamp(), // Tambah last_login
      'profileImageUrl': profileImageUrl,
      'totalScore': totalScore ?? 0,
      'challengesCompleted': challengesCompleted ?? 0,
      'role': role ?? 'user',
    };
  }
}