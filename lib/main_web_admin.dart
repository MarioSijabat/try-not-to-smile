// lib/main_web_admin.dart
// Entry point khusus untuk Web Admin Panel
// Build dengan: flutter build web --web-renderer html --dart-define=ADMIN_ONLY=true

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Try Not To Smile - Admin Panel',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: AdminAuthWrapper(),
      ),
    );
  }
}

class AdminAuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Admin Panel...'),
                ],
              ),
            ),
          );
        }

        // Belum login - tampilkan login screen
        if (!authProvider.isLoggedIn) {
          return LoginScreen(isAdminLogin: true);
        }

        // Sudah login tapi bukan admin - tampilkan access denied
        if (authProvider.role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: Text('Access Denied'),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () => authProvider.logout(),
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.red),
                  SizedBox(height: 24),
                  Text(
                    'Admin Access Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You need administrator privileges to access this panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => authProvider.logout(),
                    icon: Icon(Icons.logout),
                    label: Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Admin authenticated - tampilkan admin panel
        return AdminPanelScreen();
      },
    );
  }
}
