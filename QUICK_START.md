# ⚡ Quick Start Guide

## 🎯 **Akses Admin Panel (Cepat)**

### **Langkah 1: Buat Akun Admin**
Pilih salah satu cara:

#### **Cara 1: Via Firebase Console (Tercepat)**
1. Buka Firebase Console → Authentication
2. Add user:
   - Email: `admin@example.com`
   - Password: `admin123` (ganti dengan password aman!)
3. Copy **UID** user yang baru dibuat
4. Buka Firestore Database
5. Buat collection `users` → Add document:
   - Document ID: `[paste UID dari step 3]`
   - Fields:
     ```
     username: "admin"
     email: "admin@example.com"
     role: "admin"
     createdAt: [current timestamp]
     ```
6. Save

#### **Cara 2: Register via App**
```bash
# Jalankan app biasa
flutter run -d chrome

# Register dengan:
# - Username: admin
# - Email: admin@example.com  
# - Password: [your-password]

# Lalu update role di Firestore Console
```

---

### **Langkah 2: Jalankan Admin Panel**
```bash
flutter run -d chrome -t lib/main_web_admin.dart
```

---

### **Langkah 3: Login**
- Email: `admin@example.com`
- Password: `[password yang Anda buat]`

---

## ✅ **Selesai!**

Admin panel sekarang terbuka dengan fitur:
- 📥 **Inbox**: Review video submissions
- 📤 **Uploader**: Upload new videos
- ⚙️ **Manager**: Manage active videos

---

## 🔄 **Development Workflow:**

### **Web Admin:**
```bash
flutter run -d chrome -t lib/main_web_admin.dart
# Hot reload: press 'r'
```

### **Mobile User App:**
```bash
flutter run -d android
# atau
flutter run -d ios
```

---

## 📝 **Default Test Credentials:**

Untuk testing, Anda bisa buat:

| Role | Email | Suggested Password |
|------|-------|-------------------|
| Admin | admin@test.com | Admin@123 |
| User | user@test.com | User@123 |

⚠️ **PENTING**: Ganti password untuk production!

---

## 🆘 **Butuh Bantuan?**

- Masalah login? → Lihat [ADMIN_SETUP.md](ADMIN_SETUP.md)
- Build commands? → Lihat [BUILD_COMMANDS.md](BUILD_COMMANDS.md)
- Error Firebase? → Check `firebase_options.dart` dan Firebase Console

---

## 🎨 **Customize:**

File-file penting:
- Admin UI: `lib/screens/admin_panel_screen.dart`
- Login UI: `lib/screens/auth/login_screen.dart`
- Auth Logic: `lib/providers/auth_provider.dart`
- Web Config: `web/index.html`
