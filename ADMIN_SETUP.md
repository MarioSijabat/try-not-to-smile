# 🔐 Admin Panel Access Guide

## 📋 **Langkah-langkah Akses Admin Panel:**

### **1️⃣ Setup User Admin di Firebase**

Ada 2 cara untuk membuat user admin:

#### **Opsi A: Via Firebase Console (Manual)**
1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project Anda
3. Buka **Firestore Database**
4. Buat/Edit collection: `users`
5. Tambahkan document dengan struktur:
   ```
   Document ID: [UID dari Firebase Auth]
   Fields:
   - username: "admin" (string)
   - email: "admin@example.com" (string)
   - role: "admin" (string)  ⚠️ PENTING!
   - createdAt: [timestamp]
   ```

#### **Opsi B: Register Normal + Update Role**
1. Register akun baru via app (role default: 'user')
2. Buka Firebase Console → Firestore
3. Cari document user yang baru dibuat
4. Edit field `role` dari "user" menjadi "admin"

---

### **2️⃣ Jalankan Web Admin Panel**

```bash
# Di terminal
flutter run -d chrome -t lib/main_web_admin.dart
```

Browser akan otomatis terbuka di `http://localhost:xxxxx`

---

### **3️⃣ Login sebagai Admin**

1. **Buka browser** (sudah otomatis terbuka)
2. **Masukkan credentials admin:**
   - Email: `admin@example.com` (atau email yang sudah dibuat)
   - Password: `[password saat register]`
3. **Klik Login**

---

### **4️⃣ Verifikasi Access**

Setelah login:
- ✅ **Berhasil**: Muncul Admin Panel dengan 3 tabs (Inbox, Uploader, Manager)
- ❌ **Gagal**: Muncul "Access Denied" → role di Firestore bukan "admin"

---

## 🔧 **Troubleshooting:**

### **Problem: "Access Denied" setelah login**
**Solusi:**
1. Check Firestore → collection `users` → document dengan UID user
2. Pastikan field `role` = `"admin"` (huruf kecil)
3. Logout dan login kembali

### **Problem: Login gagal**
**Solusi:**
1. Check Firebase Authentication sudah enabled (Email/Password)
2. Check credentials benar
3. Check Firebase configuration di `firebase_options.dart`

### **Problem: Firestore error**
**Solusi:**
1. Check Firestore Rules di Firebase Console
2. Pastikan rules allow read/write untuk authenticated users:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null;
       }
       // ... other rules
     }
   }
   ```

---

## 🎯 **Quick Setup (First Time):**

### **Step 1: Register Admin Account**
Jalankan mobile app atau web app biasa:
```bash
flutter run
```
Register dengan:
- Username: `admin`
- Email: `admin@yourdomain.com`
- Password: `[pilih password aman]`

### **Step 2: Update Role di Firestore**
1. Buka Firebase Console
2. Firestore → collection `users`
3. Cari document dengan email admin
4. Edit field `role` → ubah ke `"admin"`
5. Save

### **Step 3: Login ke Admin Panel**
```bash
flutter run -d chrome -t lib/main_web_admin.dart
```
Login dengan credentials admin yang sudah dibuat.

---

## 🌐 **URL Access:**

### **Development:**
- Direct URL: `http://localhost:[port]/`
- Dengan routing: `http://localhost:[port]/#/admin`

### **Production (setelah deploy):**
- `https://yourdomain.com`
- `https://yourdomain.com/#/admin`

---

## 📱 **Perbedaan Mobile vs Web:**

| Platform | Entry Point | Default View | Admin Access |
|----------|-------------|--------------|--------------|
| 📱 Mobile | `main.dart` | Main Menu | Tombol di menu (jika admin) |
| 💻 Web | `main_web_admin.dart` | Admin Login | Langsung admin panel |

---

## 🔒 **Security Best Practices:**

1. ✅ Gunakan password yang kuat untuk admin
2. ✅ Jangan share credentials admin
3. ✅ Setup Firestore security rules yang ketat
4. ✅ Enable MFA (Multi-Factor Auth) untuk admin di Firebase
5. ✅ Regularly audit admin access logs

---

## 🚀 **Next Steps:**

Setelah berhasil login:
1. ✅ Test semua fitur admin panel
2. ✅ Upload test video
3. ✅ Manage submissions
4. ✅ Configure Firestore security rules
5. ✅ Deploy to production hosting
