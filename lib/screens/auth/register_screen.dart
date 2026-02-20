// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  // ✅ TAMBAH CONSTRUCTOR DENGAN const!
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Icon
              const Icon(
                Icons.person_add,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  if (value.length < 3) {
                    return 'Username minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != _passwordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              
              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await authProvider.register(
                                _usernameController.text.trim(),
                                _emailController.text.trim(),
                                _passwordController.text,
                              );
                              
                              if (!mounted) return;
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Registrasi berhasil! Selamat datang ${_usernameController.text}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              
                              // Show welcome dialog
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.celebration, color: Colors.orange, size: 32),
                                      const SizedBox(width: 12),
                                      const Text('Selamat Datang!'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Akun Anda berhasil dibuat!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Username: ${_usernameController.text}'),
                                      Text('Email: ${_emailController.text}'),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Anda sekarang dapat menggunakan semua fitur aplikasi Try Not To Smile!',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context); // Close dialog
                                        // Logout dulu, kemudian redirect ke login
                                        await authProvider.logout();
                                        if (mounted) {
                                          // ✅ GUNAKAN const LoginScreen()
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen(),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Mulai Bermain!'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              
                              setState(() {
                                _errorMessage = e.toString().replaceAll('Exception: ', '');
                              });
                              
                              // Show error snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('Registrasi gagal: ${e.toString()}'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Mendaftar...', style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login Link
              TextButton(
                onPressed: () {
                  // ✅ GUNAKAN const LoginScreen()
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}