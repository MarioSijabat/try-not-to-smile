import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart'; // Nanti buat file ini
import 'providers/video_provider.dart';
import 'screens/main_menu_screen.dart'; // Nanti buat
import 'screens/auth/login_screen.dart';
// Admin panel screen tidak diimport di sini karena khusus untuk web (main_web_admin.dart)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inisialisasi Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
      ],
      child: MaterialApp(
        title: 'Try Not To Smile',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => AuthWrapper(), // Mobile app selalu ke AuthWrapper
          // Admin panel route dihapus - gunakan main_web_admin.dart untuk web admin
        },
      ),
    );
  }
}

// Wrapper untuk Mobile - Full User App
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          // Selalu ke MainMenuScreen, handle guest di sana
          return MainMenuScreen();
        }
      },
    );
  }
}
