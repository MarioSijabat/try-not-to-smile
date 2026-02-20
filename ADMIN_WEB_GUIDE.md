# 🎯 Panduan Admin Web Panel

## Perbedaan Entry Points

Project ini memiliki **2 entry points berbeda**:

### 1. `lib/main.dart` - Mobile App (Android/iOS)
- Untuk user biasa
- Fitur: Challenge, Submit Video, Profile
- Run dengan: `flutter run` atau `flutter run -d <device_id>`

### 2. `lib/main_web_admin.dart` - Web Admin Panel
- **Khusus untuk Admin**
- Fitur: Inbox, Uploader, Video Manager
- **Hanya bisa run di Web** (menggunakan `dart:html`)

---

## 🚀 Cara Run Admin Panel

### Option 1: Development Mode (Chrome)
```bash
flutter run -d chrome -t lib/main_web_admin.dart
```

### Option 2: Build Production Web
```bash
# Build untuk production
flutter build web --web-renderer html -t lib/main_web_admin.dart

# Output di: build/web/
# Deploy folder ini ke hosting (Firebase Hosting, Netlify, dll)
```

### Option 3: Run di Edge Browser
```bash
flutter run -d edge -t lib/main_web_admin.dart
```

---

## 🔐 Setup Admin User

Sebelum bisa login ke Admin Panel, Anda perlu set user role `admin` di Firestore:

### Cara Manual (Firebase Console):
1. Buka https://console.firebase.google.com
2. Pilih project → **Firestore Database**
3. Buka collection `users`
4. Edit/buat document dengan **UID user** sebagai Document ID
5. Tambah field:
   ```
   role: "admin"  (string)
   ```

### Cara Otomatis (Script):
1. Dapatkan UID user dari **Authentication** di Firebase Console
2. Edit file `lib/utils/set_admin_role.dart`:
   ```dart
   const String targetUserId = 'PASTE_UID_DISINI';
   ```
3. Run script:
   ```bash
   flutter run -d chrome -t lib/utils/set_admin_role.dart
   ```

---

## 🎨 Fitur Admin Panel

### Tab 1: Inbox 📥
- Lihat semua video submissions dari user
- Status: Pending, Approved, Rejected
- **Tombol Approve/Reject** untuk pending submissions
- Auto-update `processed_at` timestamp

### Tab 2: Uploader 📤
- Upload file video `.mp4` langsung dari komputer
- **Validasi ukuran maksimal 5MB**
- Form input:
  - ✅ Title (wajib)
  - ✅ Credit Username (wajib)
  - ⚪ Credit UID (opsional)
  - ⚪ Hashtags (opsional, comma-separated)
  - ⚪ Duration (opsional, dalam detik)
- Upload ke Firebase Storage
- Auto-generate unique filename

### Tab 3: Manager 📚
- List semua active videos (is_deleted = false)
- Tampilan: title, credit, hashtags, duration, created date
- **Tombol Delete** dengan confirmation
- Soft delete: set `is_deleted=true`, `expire_at` (+30 hari)

---

## ⚠️ Troubleshooting

### Error: "dart:html is not available on this platform"
**Penyebab**: Mencoba run admin panel di Android/iOS device.  
**Solusi**: Admin panel hanya bisa run di web browser:
```bash
flutter run -d chrome -t lib/main_web_admin.dart
```

### Error: "Access Denied" setelah login
**Penyebab**: User belum punya role admin.  
**Solusi**: Set field `role: "admin"` di Firestore collection `users`.

### Upload gagal "File terlalu besar"
**Penyebab**: File video lebih dari 5MB.  
**Solusi**: Compress video dengan HandBrake (CRF 24-28, 720p).

---

## 📋 Next Steps

1. **Setup Firestore Security Rules** (lihat FIREBASE_RULES.md)
2. **Aktifkan TTL Policy** di Firebase Console untuk auto-delete expired videos
3. **Buat Composite Index** untuk query performa:
   - Collection: `active_videos`
   - Fields: `is_deleted` (Asc) + `created_at` (Desc)

---

## 🔗 File Penting

- Entry point: `lib/main_web_admin.dart`
- Screen: `lib/screens/admin_panel_screen.dart`
- Services: `lib/services/firestore_service.dart`, `lib/services/storage_service.dart`
- Models: `lib/models/video_submission_model.dart`, `lib/models/active_video_model.dart`
