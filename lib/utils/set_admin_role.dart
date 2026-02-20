// lib/utils/set_admin_role.dart
// Script utility untuk set user role menjadi admin
// Run dengan: flutter run -t lib/utils/set_admin_role.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  print('🔧 Admin Role Setup Utility\n');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  // ⚠️ GANTI EMAIL INI DENGAN EMAIL USER YANG INGIN DIJADIKAN ADMIN
  const String targetEmail = 'tobok@test.com'; // Ganti dengan email admin Anda
  
  print('🔍 Mencari user dengan email: $targetEmail\n');
  
  try {
    // Cari user berdasarkan email
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: targetEmail)
        .limit(1)
        .get();
    
    if (userQuery.docs.isEmpty) {
      print('❌ ERROR: User dengan email $targetEmail tidak ditemukan!');
      print('\nPastikan:');
      print('   1. User sudah register di aplikasi');
      print('   2. Email sudah benar (case sensitive)');
      print('\nCara alternatif:');
      print('   1. Buka Firebase Console > Firestore');
      print('   2. Collection "users"');
      print('   3. Cari document dengan email tersebut');
      print('   4. Edit field "role" menjadi "admin"');
      return;
    }
    
    final targetUserId = userQuery.docs.first.id;
    final userData = userQuery.docs.first.data();
    print('✓ User ditemukan!');
    print('  UID: $targetUserId');
    print('  Email: ${userData['email']}');
    print('  Username: ${userData['username']}');
    print('  Current Role: ${userData['role'] ?? 'user'}\n');
    
    print('📝 Mengubah role menjadi admin...\n');
    
    // Set atau update user document dengan role admin
    await firestore.collection('users').doc(targetUserId).set({
      'role': 'admin',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge agar tidak overwrite field lain
    
    print('✅ SUCCESS! User $targetEmail sekarang adalah ADMIN');
    print('   Silakan logout dan login kembali untuk mengakses Admin Panel\n');
    
    // Verify
    final doc = await firestore.collection('users').doc(targetUserId).get();
    if (doc.exists) {
      print('📋 Updated user data:');
      final data = doc.data();
      print('  Email: ${data?['email']}');
      print('  Role: ${data?['role']}');
      print('  Updated: ${data?['updated_at']}');
    }
    
  } catch (e) {
    print('❌ ERROR: $e');
  }
  
  print('\n✨ Script selesai.');
}
