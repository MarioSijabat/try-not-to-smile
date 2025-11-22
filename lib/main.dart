import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart'; // Nanti buat file ini
import 'screens/main_menu_screen.dart'; // Nanti buat

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inisialisasi Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Tambahkan provider lain nanti
      ],
      child: MaterialApp(
        title: 'Try Not To Smile',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MainMenuScreen(), // Halaman awal
      ),
    );
  }
}
