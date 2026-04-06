// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/latarbelakang.mp4');
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.setVolume(0);
    _videoController.play();
    if (mounted) setState(() => _videoReady = true);
  }

  @override
  void dispose() {
    _videoController.dispose();
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
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video Background ────────────────────────────────────────────
          if (_videoReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            const SizedBox.expand(child: ColoredBox(color: Color(0xFF1A1A1A))),

          // ── Dark overlay ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),

          // ── Form Content ────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back button ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white30, width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Header ──────────────────────────────────────────
                    const Text(
                      'JOIN THE',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.0,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFF3B30), Color(0xFFFF2D78)],
                      ).createShader(bounds),
                      child: const Text(
                        'CHALLENGE! 🌈',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Buat akun dan mulai tantanganmu',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 40),

                    // ── Username ─────────────────────────────────────────
                    _buildLabel('Username'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _usernameController,
                      hintText: 'nama_kamu',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Username tidak boleh kosong';
                        if (v.length < 3) return 'Username minimal 3 karakter';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ── Email ────────────────────────────────────────────
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'contoh@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                        if (!v.contains('@') || !v.contains('.')) return 'Email tidak valid';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ── Password ─────────────────────────────────────────
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ── Confirm Password ─────────────────────────────────
                    _buildLabel('Konfirmasi Password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                        if (v != _passwordController.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),

                    // ── Error Message ────────────────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // ── Register Button ──────────────────────────────────
                    _GradientButton(
                      isLoading: authProvider.isLoading,
                      onTap: authProvider.isLoading
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

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Selamat datang, ${_usernameController.text}! 🎉',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => Dialog(
                                      backgroundColor: const Color(0xFF252525),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: Colors.white12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(28),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🎉', style: TextStyle(fontSize: 52)),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'AKUN DIBUAT!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                fontStyle: FontStyle.italic,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Username: ${_usernameController.text}',
                                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                                            ),
                                            Text(
                                              'Email: ${_emailController.text}',
                                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Siap hadapi tantangan Try Not To Smile?',
                                              style: TextStyle(color: Colors.white38, fontSize: 13),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            GestureDetector(
                                              onTap: () async {
                                                Navigator.pop(context);
                                                await authProvider.logout();
                                                if (mounted) {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => const LoginScreen(),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(50),
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFFFF8C00),
                                                      Color(0xFFFF3B30),
                                                      Color(0xFFFF2D78),
                                                    ],
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'MULAI BERMAIN! 🌈',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontStyle: FontStyle.italic,
                                                      fontSize: 15,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() {
                                    _errorMessage = e.toString().replaceAll('Exception: ', '');
                                  });
                                }
                              }
                            },
                      label: 'DAFTAR SEKARANG',
                    ),

                    const SizedBox(height: 24),

                    // ── Login Link ───────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Sudah punya akun? ',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Masuk di sini',
                                style: TextStyle(
                                  color: Color(0xFFFF6B9D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  final String label;

  const _GradientButton({
    required this.isLoading,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8C00), Color(0xFFFF3B30), Color(0xFFFF2D78)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withOpacity(0.45),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}