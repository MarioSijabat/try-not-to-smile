// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Set displayName di Firebase Auth
    await userCredential.user!.updateDisplayName(name);
    await userCredential.user!.reload(); // Reload untuk update data

    // Simpan data user ke Firestore menggunakan UserModel
    UserModel user = UserModel(
      uid: userCredential.user!.uid,
      name: name,
      email: email,
      role: 'user', // Default role untuk registered user
    );
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Update last_login timestamp
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  Future<void> updateUserProfile(String username) async {
    await _auth.currentUser?.updateDisplayName(username);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
