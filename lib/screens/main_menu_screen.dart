// lib/screens/main_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Asumsi Anda punya ini dari setup sebelumnya
import 'challenge_screen.dart'; // Nanti buat ini
import 'submit_video_screen.dart'; // Nanti buat ini
import 'profile_screen.dart'; // Nanti buat ini

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
                // Navigasi ke login jika perlu
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChallengeScreen()),
                );
              },
              child: Text('Start Challenge'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: authProvider.isLoggedIn
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubmitVideoScreen(),
                        ),
                      );
                    }
                  : null, // Disable jika guest
              child: Text('Submit Video'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: authProvider.isLoggedIn
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    }
                  : null, // Disable jika guest
              child: Text('Profile/Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
