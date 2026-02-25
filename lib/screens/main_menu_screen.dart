// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import 'submit_video_screen.dart';
import 'profile_screen.dart';
import 'swipeable_challenge_screen.dart';
import 'smile_test_screen.dart';

class MainMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 26),
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
                    // ─── Title ───────────────────────────────────────────
                    const Text(
                      'TRY NOT TO',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 3,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RainbowText(
                          text: 'SMILE',
                          fontSize: 52,
                          colors: const [
                            Color(0xFFFF3B30),
                            Color(0xFFFF9500),
                            Color(0xFFFFCC00),
                            Color(0xFF34C759),
                            Color(0xFF5856D6),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text('✦', style: TextStyle(color: Color(0xFFFFCC00), fontSize: 22)),
                        const SizedBox(width: 2),
                        const Text('✦', style: TextStyle(color: Color(0xFFFFD700), fontSize: 14)),
                      ],
                    ),

                    const SizedBox(height: 56),

                    // ─── BOTHER ME button ─────────────────────────────────
                    _GradientBorderButton(
                      isLight: true,
                      onTap: () {
                        final videoProvider =
                            Provider.of<VideoProvider>(context, listen: false);
                        if (videoProvider.videos.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Belum ada video tersedia')),
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
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('✦',
                                    style: TextStyle(
                                        color: Color(0xFFFF6B9D),
                                        fontSize: 16)),
                                SizedBox(width: 10),
                                Text(
                                  'BOTHER ME!',
                                  style: TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 22,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rainbow emoji — right side hanging over border
                          const Positioned(
                            right: -14,
                            top: -14,
                            child: Text('🌈',
                                style: TextStyle(fontSize: 52),
                                textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── TEST DETEKSI SENYUM button ───────────────────────
                    _GradientBorderButton(
                      isLight: false,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SmileTestScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.face, color: Colors.greenAccent, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'TEST SENYUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 20,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.chevron_right,
                                color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── SEND FUNNY VIDS button ───────────────────────────
                    _GradientBorderButton(
                      isLight: false,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SubmitVideoScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(
                              child: Text(
                                'SEND FUNNY VIDS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 20,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.white, size: 28),
                          ],
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