import 'dart:html' as html; // WAJIB untuk web file picker!
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/admin_panel_service.dart';
import '../services/video_storage_service.dart';
import '../providers/auth_provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  // SERVICES
  final AdminPanelService _adminService = AdminPanelService();
  final VideoStorageService _storageService = VideoStorageService();

  // STATE VARIABLES
  late TabController _tabController;
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _activeVideos = [];
  
  // ============ UPLOAD FORM CONTROLLERS ============
  final _titleController = TextEditingController();
  final _creditUsernameController = TextEditingController();
  final _creditUidController = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _durationController = TextEditingController();
  
  // ============ UPLOAD STATE ============
  Uint8List? _selectedVideoBytes;
  String? _selectedVideoName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ✅ HARUS 3!
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _creditUsernameController.dispose();
    _creditUidController.dispose();
    _hashtagsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // --- LOAD DATA ---
  void _loadData() {
    _adminService.getVideoSubmissions().listen((submissions) {
      if (mounted) setState(() => _submissions = submissions);
    });

    _adminService.getActiveVideos().listen((videos) {
      if (mounted) setState(() => _activeVideos = videos);
    });
  }

  // ============ UPLOAD VIDEO METHODS ============
  
  /// 📁 PICK VIDEO FILE (WEB ONLY)
  Future<void> _pickVideoFile() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'video/mp4';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      // Validasi ukuran (max 10MB)
      const maxSize = 10 * 1024 * 1024;
      if (file.size > maxSize) {
        _showErrorDialog('File terlalu besar! Maksimal 10MB.');
        return;
      }

      // Validasi format
      if (!file.name.toLowerCase().endsWith('.mp4')) {
        _showErrorDialog('Hanya file .mp4 yang diperbolehkan!');
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        if (mounted) {
          setState(() {
            _selectedVideoBytes = reader.result as Uint8List?;
            _selectedVideoName = file.name;
          });
        }
      });
    });
  }

  /// 🚀 UPLOAD VIDEO KE FIREBASE
  Future<void> _uploadVideo() async {
    // Validasi file
    if (_selectedVideoBytes == null || _selectedVideoName == null) {
      _showErrorDialog('Pilih file video terlebih dahulu!');
      return;
    }

    // Validasi form wajib
    if (_titleController.text.trim().isEmpty) {
      _showErrorDialog('Title wajib diisi!');
      return;
    }

    if (_creditUsernameController.text.trim().isEmpty) {
      _showErrorDialog('Credit Username wajib diisi!');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.role != 'admin') {
      _showErrorDialog('Anda tidak memiliki izin untuk mengupload video!');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. UPLOAD KE STORAGE
      final videoUrl = await _storageService.uploadVideo(
        _selectedVideoBytes!,
        _selectedVideoName!,
      );

      // 2. PARSE HASHTAGS
      List<String> hashtags = [];
      if (_hashtagsController.text.trim().isNotEmpty) {
        hashtags = _hashtagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
      }

      // 3. PARSE DURATION
      int? duration;
      if (_durationController.text.trim().isNotEmpty) {
        duration = int.tryParse(_durationController.text.trim());
      }

      // 4. SAVE TO FIRESTORE
      await _adminService.addActiveVideoComplete(
        title: _titleController.text.trim(),
        videoUrl: videoUrl,
        creditUsername: _creditUsernameController.text.trim(),
        publishedBy: authProvider.user?.uid ?? 'admin',
        creditUid: _creditUidController.text.trim().isEmpty
            ? null
            : _creditUidController.text.trim(),
        hashtags: hashtags.isEmpty ? null : hashtags,
        durationSec: duration,
      );

      // 5. CLEAR FORM
      _clearUploadForm();
      _showSuccessDialog('✅ Video berhasil diupload!');

    } catch (e) {
      _showErrorDialog('Upload gagal: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// 🧹 CLEAR UPLOAD FORM
  void _clearUploadForm() {
    setState(() {
      _titleController.clear();
      _creditUsernameController.clear();
      _creditUidController.clear();
      _hashtagsController.clear();
      _durationController.clear();
      _selectedVideoBytes = null;
      _selectedVideoName = null;
    });
  }

  // --- ACTIONS (SUBMISSIONS) ---
  Future<void> _approveSubmission(Map<String, dynamic> submission) async {
    try {
      await _adminService.approveSubmission(submission['id']);
      _showSuccessDialog('Submission approved!');
    } catch (e) {
      _showErrorDialog('Approve gagal: $e');
    }
  }

  Future<void> _rejectSubmission(Map<String, dynamic> submission) async {
    try {
      await _adminService.rejectSubmission(submission['id']);
      _showSuccessDialog('Submission rejected!');
    } catch (e) {
      _showErrorDialog('Reject gagal: $e');
    }
  }

  // --- ACTIONS (ACTIVE VIDEOS) ---
  Future<void> _deleteVideo(Map<String, dynamic> video) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Yakin ingin menghapus video "${video['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.softDeleteVideo(
          video['docId'], 
          authProvider.user?.uid ?? 'admin',
        );
        _showSuccessDialog('Video berhasil dihapus!');
      } catch (e) {
        _showErrorDialog('Delete gagal: $e');
      }
    }
  }

  // --- UI HELPERS ---
  Future<void> _openLink(String? url) async {
    if (url != null) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          html.window.open(url, '_blank');
        }
      } catch (e) {
        _showErrorDialog('Tidak bisa membuka link');
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 1)),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }
  
  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'Inbox'),
            Tab(icon: Icon(Icons.upload_file), text: 'Uploader'), // ✅ TAB UPLOADER!
            Tab(icon: Icon(Icons.video_library), text: 'Manager'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInboxTab(),      // TAB 1: Submissions
          _buildUploaderTab(),   // ✅ TAB 2: Upload Video Form!
          _buildManagerTab(),    // TAB 3: Active Videos
        ],
      ),
    );
  }

  // ============ TAB 1: INBOX (SUBMISSIONS) ============
  Widget _buildInboxTab() {
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada submission', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final sub = _submissions[index];
        final isPending = sub['status'] == 'pending';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sub['status'] == 'approved'
                          ? Icons.check_circle
                          : sub['status'] == 'rejected'
                              ? Icons.cancel
                              : Icons.pending,
                      color: sub['status'] == 'approved'
                          ? Colors.green
                          : sub['status'] == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openLink(sub['original_link']),
                        child: Text(
                          sub['original_link'] ?? 'No Link',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                      tooltip: 'Copy Link',
                      onPressed: () => _copyToClipboard(sub['original_link'] ?? ''),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        (sub['status'] ?? 'pending').toString().toUpperCase(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: sub['status'] == 'approved'
                          ? Colors.green
                          : sub['status'] == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Submitted by: ${sub['submitted_by_username'] ?? 'Unknown'}'),
                Text('Category: ${sub['category_suggestion'] ?? '-'}'),
                Text('Submitted: ${_formatTimestamp(sub['created_at'])}'),
                if (sub['processed_at'] != null)
                  Text('Processed: ${_formatTimestamp(sub['processed_at'])}'),
                
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rejectSubmission(sub),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveSubmission(sub),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ ✅ TAB 2: UPLOADER (FORM UPLOAD VIDEO) ============
  Widget _buildUploaderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Video .mp4',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max file size: 10MB | Format: .mp4',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Divider(height: 32),
                  
                  // 📁 FILE PICKER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedVideoName != null
                              ? Icons.video_file
                              : Icons.upload_file,
                          size: 48,
                          color: _selectedVideoName != null
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedVideoName ?? 'No file selected',
                          style: TextStyle(
                            fontWeight: _selectedVideoName != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickVideoFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose File'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 📝 FORM FIELDS
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter video title',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _creditUsernameController,
                    decoration: const InputDecoration(
                      labelText: 'Credit Username *',
                      hintText: 'Enter creator username',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _creditUidController,
                    decoration: const InputDecoration(
                      labelText: 'Credit UID (Optional)',
                      hintText: 'User ID if exists',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _hashtagsController,
                    decoration: const InputDecoration(
                      labelText: 'Hashtags (Optional)',
                      hintText: 'Comma-separated: funny, cute, animals',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (seconds, Optional)',
                      hintText: 'e.g., 30',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 24),
                  
                  // 🚀 UPLOAD BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadVideo,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        _isUploading ? 'Uploading...' : 'Upload Video',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 🧹 CLEAR BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _clearUploadForm,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Form'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ TAB 3: MANAGER (ACTIVE VIDEOS) ============
  Widget _buildManagerTab() {
    if (_activeVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.video_library, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada active videos', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeVideos.length,
      itemBuilder: (context, index) {
        final video = _activeVideos[index];
        
        final rawHashtags = video['hashtags'];
        final tagsList = rawHashtags is List ? rawHashtags : [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.play_arrow, color: Colors.white),
            ),
            title: Text(
              video['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Credit: ${video['credit_username'] ?? '-'}'),
                if (tagsList.isNotEmpty)
                  Text('Tags: ${tagsList.join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Duration: ${video['duration_sec'] ?? '-'}s'),
                Text('Created: ${_formatTimestamp(video['created_at'])}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Video',
              onPressed: () => _deleteVideo(video),
            ),
          ),
        );
      },
    );
  }
}