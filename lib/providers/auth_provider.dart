// lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Asumsi Anda punya AuthService, buat jika belum

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoggedIn = false;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  // Constructor: Cek user saat init
  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoggedIn = user != null;
      notifyListeners();
    });
  }

  // Register
  Future<void> register(String username, String email, String password) async {
    try {
      await _authService.registerWithEmailAndPassword(email, password);
      // Update profile dengan username jika perlu (Firebase Auth punya displayName)
      await _authService.updateUserProfile(username);
      // Simpan ke Firestore users collection via FirestoreService jika perlu
      notifyListeners();
    } catch (e) {
      throw e; // Handle error di UI
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }
}
