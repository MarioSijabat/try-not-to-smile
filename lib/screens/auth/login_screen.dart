// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
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
  bool _obscurePassword = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.login(
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
              Text(
                widget.isAdminLogin
                    ? 'Login berhasil! Welcome Admin'
                    : 'Login berhasil! Selamat datang kembali',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Login gagal: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = widget.isAdminLogin;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video Background ──────────────────────────────────────────────
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

          // ── Dark overlay ──────────────────────────────────────────────────
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

          // ── Form Content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back button ──────────────────────────────────────────
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

                    // ── Header ────────────────────────────────────────────────
                    if (isAdmin) ...[
                      const Icon(Icons.admin_panel_settings, size: 56, color: Color(0xFFFF9500)),
                      const SizedBox(height: 12),
                      const Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFFF9500),
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        'Panel Access',
                        style: TextStyle(color: Colors.white54, fontSize: 15),
                      ),
                    ] else ...[
                      const Text(
                        'WELCOME',
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
                          'BACK! 😄',
                          style: TextStyle(
                            fontSize: 38,
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
                        'Masuk untuk lanjutkan tantanganmu',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],

                    const SizedBox(height: 48),

                    // ── Email Field ───────────────────────────────────────────
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'contoh@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Password Field ────────────────────────────────────────
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
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // ── Login Button ──────────────────────────────────────────
                    _GradientButton(
                      isLoading: authProvider.isLoading,
                      onTap: authProvider.isLoading ? null : _handleLogin,
                      label: isAdmin ? 'MASUK ADMIN' : 'MASUK',
                      accentColor: isAdmin ? const Color(0xFFFF9500) : null,
                    ),

                    const SizedBox(height: 24),

                    // ── Register Link ─────────────────────────────────────────
                    if (!isAdmin)
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Belum punya akun? ',
                              style: TextStyle(color: Colors.white60, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Daftar sekarang',
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
  final Color? accentColor;

  const _GradientButton({
    required this.isLoading,
    required this.onTap,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = accentColor != null
        ? LinearGradient(colors: [accentColor!, accentColor!.withOpacity(0.7)])
        : const LinearGradient(
            colors: [Color(0xFFFF8C00), Color(0xFFFF3B30), Color(0xFFFF2D78)],
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: (accentColor ?? const Color(0xFFFF6B00)).withOpacity(0.45),
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
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}