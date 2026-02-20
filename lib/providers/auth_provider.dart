// lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart'; // Pastikan path ini benar

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // State Variables
  User? _user;
  UserModel? _userModel;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error; // Tambahan variabel untuk menyimpan pesan error

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error; // Getter error
  String get role => _userModel?.role ?? 'guest';

  // Stream Auth Changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Constructor
  AuthProvider() {
    _initializeUser();
    
    // Listen to Firebase Auth changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      _isLoggedIn = user != null;
      
      if (user != null) {
        // Jika user login, ambil data tambahan dari Firestore
        try {
          _userModel = await _authService.getUserData(user.uid);
        } catch (e) {
          debugPrint("Error getting user data: $e");
          _userModel = null;
        }
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Initial Load Check
  Future<void> _initializeUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      _isLoggedIn = true;
      try {
        _userModel = await _authService.getUserData(currentUser.uid);
      } catch (e) {
        debugPrint("Init user data error: $e");
      }
      notifyListeners();
    }
  }

  // --- ACTIONS ---

  // Register
  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.registerWithEmailAndPassword(email, password, username);
      
      // Tunggu sebentar untuk propagasi data (opsional, tapi aman)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Force update state lokal jika perlu
      _user = _authService.currentUser;
      if (_user != null) {
        _userModel = await _authService.getUserData(_user!.uid);
        _isLoggedIn = true;
      }
    } catch (e) {
      _error = e.toString();
      rethrow; // Lempar error agar bisa ditangkap UI (SnackBar)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login (Sesuai request Anda)
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _authService.signInWithEmailAndPassword(email, password);
      
      // Tunggu sebentar untuk data user terload dari Firestore
      // Ini membantu mencegah error null pada 'role' saat redirect cepat
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      _error = e.toString();
      rethrow; // Biarkan UI handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
      _isLoggedIn = false;
      _error = null;
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      notifyListeners();
    }
  }
}