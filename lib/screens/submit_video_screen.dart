// lib/screens/submit_video_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart'; // Asumsi punya ini untuk simpan ke Firestore

class SubmitVideoScreen extends StatefulWidget {
  @override
  _SubmitVideoScreenState createState() => _SubmitVideoScreenState();
}

class _SubmitVideoScreenState extends State<SubmitVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  String _category = 'Funny'; // Default category
  final List<String> _categories = [
    'Funny',
    'Animals',
    'Pranks',
    'Others',
  ]; // Contoh kategori

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('Submit Video')),
        body: Center(child: Text('Please login to submit video')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Submit Video')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Video Link (YouTube/TikTok)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a link';
                  }
                  // Optional: Validasi URL sederhana
                  if (!value.contains('youtube.com') &&
                      !value.contains('tiktok.com')) {
                    return 'Link must be from YouTube or TikTok';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      // Simpan ke Firestore via service
                      final firestoreService = FirestoreService();
                      await firestoreService.submitVideo(
                        authProvider.user!.uid,
                        authProvider.user!.displayName ?? 'Anonymous',
                        _linkController.text,
                        _category,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Video submitted successfully!'),
                        ),
                      );
                      Navigator.pop(context); // Kembali ke menu
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
