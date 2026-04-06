// lib/screens/main_menu_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import '../services/category_service.dart';
import 'submit_video_screen.dart';
import 'profile_screen.dart';
import 'swipeable_challenge_screen.dart';
import 'smile_test_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  StreamSubscription<List<CategoryModel>>? _categorySub;

  @override
  void initState() {
    super.initState();
    _categorySub = _categoryService.getCategories().listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    super.dispose();
  }

  // ─── Bottom sheet pilih kategori ─────────────────────────────────────────
  Future<void> _showCategoryPicker(VideoProvider videoProvider) async {
    // Kalau tidak ada kategori, langsung masuk dengan semua video
    if (_categories.isEmpty) {
      _startChallenge(videoProvider, null);
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Kategori',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih tema video yang ingin kamu hadapi',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Grid kategori
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  // Card "Semua"
                  _CategoryCard(
                    icon: '🎬',
                    name: 'Semua',
                    onTap: () {
                      Navigator.pop(context);
                      _startChallenge(videoProvider, null);
                    },
                  ),
                  // Card per kategori
                  ..._categories.map((cat) => _CategoryCard(
                    icon: cat.icon,
                    name: cat.name,
                    onTap: () {
                      Navigator.pop(context);
                      _startChallenge(videoProvider, cat.id);
                    },
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _startChallenge(VideoProvider videoProvider, String? categoryId) {
    videoProvider.setCategory(categoryId);
    if (videoProvider.videos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada video untuk kategori ini')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwipeableChallengeScreen(
          videos: videoProvider.videos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Profile icon — top left
            Positioned(
              top: 12,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1.5),
                    color: Colors.white10,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/icons/Icon_profile.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/label_'smile'.svg",
                      height: 125,
                    ),

                    const SizedBox(height: 56),

                    // ─── BOTHER ME button ─────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        if (videoProvider.isLoading) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Memuat video, sebentar lagi...'),
                                ],
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        _showCategoryPicker(videoProvider);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.asset(
                          'assets/icons/bother_me.jpeg',
                          height: 95,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── TEST DETEKSI SENYUM button ───────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SmileTestScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          height: 75, // Menyamakan feel proporsi dengan tombol SVG (yang ada whitespace)
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525), // Flat dark color menyerupai style solid
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.face, color: Colors.greenAccent, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'TEST SENYUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 22,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.chevron_right,
                                  color: Colors.white54, size: 28),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── SEND FUNNY VIDS button ───────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SubmitVideoScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SvgPicture.asset(
                          'assets/icons/button_sendvideos.svg',
                          height: 95,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // ─── Admin Panel (admin only) ─────────────────────────
                    if (authProvider.role == 'admin') ...[
                      const SizedBox(height: 20),
                      _GradientBorderButton(
                        isLight: false,
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.admin_panel_settings,
                                  color: Colors.orange),
                              SizedBox(width: 10),
                              Text(
                                'ADMIN PANEL',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 20,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rainbow Text Widget ──────────────────────────────────────────────────────
class _RainbowText extends StatelessWidget {
  final String text;
  final double fontSize;
  final List<Color> colors;

  const _RainbowText({
    required this.text,
    required this.fontSize,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(chars.length, (i) {
        return Text(
          chars[i],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: colors[i % colors.length],
            height: 1.0,
          ),
        );
      }),
    );
  }
}

// ─── Gradient Border Button ───────────────────────────────────────────────────
class _GradientBorderButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isLight;

  const _GradientBorderButton({
    required this.onTap,
    required this.child,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF8C00),
              Color(0xFFFF3B30),
              Color(0xFFFF2D78),
            ],
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
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(47),
            color: isLight
                ? const Color(0xFFF5F5F0)
                : const Color(0xFF252525),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Category Card Widget ──────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
