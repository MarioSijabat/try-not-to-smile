// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please login to view profile'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authProvider.user!;
    final userModel = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(title: Text('Profile/Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Username: ${userModel?.name ?? user.displayName ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Email: ${user.email ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic untuk update profile jika perlu
                // Misal: Navigasi ke edit screen
              },
              child: Text('Edit Profile'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
                Navigator.pop(context);
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
