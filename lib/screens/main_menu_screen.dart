// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'challenge_screen.dart';
import 'submit_video_screen.dart';
import 'profile_screen.dart';
import '../providers/video_provider.dart';
import 'video_play_screen.dart';

class MainMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Try Not To Smile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              if (authProvider.isLoggedIn) {
                authProvider.logout();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Active videos carousel / list
          SizedBox(
            height: 220,
            child: Consumer<VideoProvider>(
              builder: (context, vp, _) {
                if (vp.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (vp.videos.isEmpty) {
                  return Center(child: Text('Belum ada video aktif'));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.all(12),
                  itemCount: vp.videos.length,
                  itemBuilder: (context, index) {
                    final v = vp.videos[index];
                    return GestureDetector(
                      onTap: () {
                        if (v.videoUrl != null) {
                          // PERBAIKAN 1: Challenge Screen dengan parameter yang benar
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeScreen(
                                videoUrl: v.videoUrl!,
                                videoTitle: v.title ?? 'Untitled',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 160,
                        margin: EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: v.thumbnailUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(v.thumbnailUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: v.thumbnailUrl == null
                                    ? Center(child: Icon(Icons.play_circle_outline, size: 48))
                                    : null,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              v.title ?? 'Untitled',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Main controls
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // PERBAIKAN 2: Tombol Start Challenge - Bisa dihapus atau diarahkan ke video random
                    ElevatedButton(
                      onPressed: () {
                        // Ambil video provider
                        final videoProvider = Provider.of<VideoProvider>(context, listen: false);
                        
                        if (videoProvider.videos.isNotEmpty) {
                          // Ambil video pertama sebagai default
                          final firstVideo = videoProvider.videos.first;
                          if (firstVideo.videoUrl != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChallengeScreen(
                                  videoUrl: firstVideo.videoUrl!,
                                  videoTitle: firstVideo.title ?? 'Random Challenge',
                                ),
                              ),
                            );
                          } else {
                            // Tampilkan pesan error jika tidak ada video
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tidak ada video tersedia')),
                            );
                          }
                        } else {
                          // Tampilkan pesan error jika tidak ada video
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tidak ada video tersedia')),
                          );
                        }
                      },
                      child: Text('Start Challenge'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitVideoScreen(),
                          ),
                        );
                      },
                      child: Text('Submit Video'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                      child: Text('Profile/Settings'),
                    ),
                    // Tombol Admin Panel - hanya muncul jika user adalah admin
                    if (authProvider.role == 'admin') ...[
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin');
                        },
                        icon: Icon(Icons.admin_panel_settings),
                        label: Text('Admin Panel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}