// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdminLogin;

  const LoginScreen({Key? key, this.isAdminLogin = false}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Validasi Form
    if (!_formKey.currentState!.validate()) return;

    // 2. Ambil Provider (listen: false untuk method action)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Eksekusi Login
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // 3. CHECK MOUNTED (Penting sebelum update UI setelah await)
      if (!mounted) return;

      // 4. Tampilkan Pesan Sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                widget.isAdminLogin
                    ? 'Login berhasil! Welcome Admin'
                    : 'Login berhasil! Selamat datang kembali',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 5. Redirect ke Main Menu dengan sedikit delay agar SnackBar terlihat
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return; // Check mounted lagi setelah delay
      Navigator.pushReplacementNamed(context, '/');

    } catch (e) {
      // 6. CHECK MOUNTED (Penting sebelum show error)
      if (!mounted) return;

      // 7. Tampilkan Pesan Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Login gagal: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    // Listen ke AuthProvider untuk update UI saat loading state berubah
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = widget.isAdminLogin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Login' : 'Login'),
        backgroundColor: isAdmin ? Colors.orange : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isAdmin) ...[
                  const Icon(Icons.admin_panel_settings, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Panel Access',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                ],
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
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _handleLogin, // Panggil fungsi _handleLogin
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdmin ? Colors.orange : Theme.of(context).primaryColor,
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
                              Text('Logging in...', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                if (!isAdmin) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}