// lib/screens/submit_video_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import 'auth/login_screen.dart';

class SubmitVideoScreen extends StatefulWidget {
  @override
  _SubmitVideoScreenState createState() => _SubmitVideoScreenState();
}

class _SubmitVideoScreenState extends State<SubmitVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  final _titleController = TextEditingController();
  String _category = 'Funny';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'Funny', 'emoji': '😂', 'label': 'Funny'},
    {'value': 'Animals', 'emoji': '🐾', 'label': 'Animals'},
    {'value': 'Pranks', 'emoji': '🎭', 'label': 'Pranks'},
    {'value': 'Kids', 'emoji': '👶', 'label': 'Kids'},
    {'value': 'Fails', 'emoji': '💥', 'label': 'Fails'},
    {'value': 'Others', 'emoji': '🎬', 'label': 'Others'},
  ];

  @override
  void dispose() {
    _linkController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // ── Not logged in state ─────────────────────────────────────────────────
    if (!authProvider.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
                const Spacer(),
                const Text('🔒', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                const Text(
                  'LOGIN DULU',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kamu perlu login untuk bisa kirim video lucu ke komunitas.',
                  style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'MASUK SEKARANG',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    // ── Main form ───────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
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
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Header ───────────────────────────────────────────────
                const Text(
                  'SEND FUNNY',
                  style: TextStyle(
                    fontSize: 36,
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
                    'VIDS! 🎬',
                    style: TextStyle(
                      fontSize: 36,
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
                  'Bagikan video lucu dari YouTube atau TikTok ke komunitas',
                  style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                ),

                const SizedBox(height: 36),

                // ── Video Link ───────────────────────────────────────────
                _buildLabel('Link Video'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _linkController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecor(
                    hintText: 'https://youtube.com/... atau https://tiktok.com/...',
                    icon: Icons.link_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Link tidak boleh kosong';
                    if (!v.contains('youtube.com') && !v.contains('tiktok.com')) {
                      return 'Link harus dari YouTube atau TikTok';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── Judul ────────────────────────────────────────────────
                _buildLabel('Judul / Deskripsi Singkat (opsional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLength: 80,
                  decoration: _inputDecor(
                    hintText: 'Ceritain kenapa ini lucu...',
                    icon: Icons.edit_outlined,
                  ).copyWith(counterStyle: const TextStyle(color: Colors.white24)),
                ),

                const SizedBox(height: 18),

                // ── Kategori ─────────────────────────────────────────────
                _buildLabel('Kategori'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((cat) {
                    final selected = _category == cat['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF8C00), Color(0xFFFF3B30), Color(0xFFFF2D78)],
                                )
                              : null,
                          color: selected ? null : const Color(0xFF252525),
                          border: Border.all(
                            color: selected ? Colors.transparent : Colors.white12,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B00).withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat['emoji']!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              cat['label']!,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white54,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── Info box ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white38, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Video yang dikirim akan direview admin sebelum ditampilkan ke pemain lain.',
                          style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Submit Button ─────────────────────────────────────────
                GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSubmitting = true);
                            try {
                              final firestoreService = FirestoreService();
                              final username = authProvider.userModel?.name ??
                                  authProvider.user!.displayName ??
                                  'Anonymous';

                              await firestoreService.submitVideo(
                                authProvider.user!.uid,
                                username,
                                _linkController.text.trim(),
                                _category,
                              );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Video berhasil dikirim! Tunggu review admin 🎉'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              Navigator.pop(context);
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Gagal kirim: $e')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: _isSubmitting
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFFF8C00), Color(0xFFFF3B30), Color(0xFFFF2D78)],
                            ),
                      color: _isSubmitting ? Colors.white12 : null,
                      boxShadow: _isSubmitting
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFFF6B00).withOpacity(0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'KIRIM VIDEO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 18,
                                    letterSpacing: 2,
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

  InputDecoration _inputDecor({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: const Color(0xFF252525),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12, width: 1),
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
    );
  }
}
