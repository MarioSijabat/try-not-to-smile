# Firebase Rules Configuration

## Firestore Rules

**DEVELOPMENT MODE (allow login dulu):**

Pakai ini terlebih dahulu di Firebase Console > Firestore Database > Rules untuk debug:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Development: semua collection bisa read/write untuk user terautentikasi
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

Setelah berhasil login, verifikasi data di Firestore Console, lalu gunakan rules PRODUCTION di bawah.

**PRODUCTION MODE (aman):**

Setelah development selesai dan data sudah benar, ganti dengan rules ini:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Collection users - setiap user bisa baca dirinya sendiri + admin bisa baca semua
    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow create: if false; // Dibuat via Auth backend saja
      allow update, delete: if false; // Tidak boleh diedit via client
    }
    
    // Collection video_submissions - user bisa create, admin bisa manage
    match /video_submissions/{docId} {
      allow read: if request.auth != null && (resource.data.submittedByUid == request.auth.uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Collection active_videos - semua bisa read, admin bisa manage
    match /active_videos/{docId} {
      allow read: if true;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Fallback untuk collection lain
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Storage Rules

**DEVELOPMENT MODE (cepat testing):**
Jika ingin cepat test tanpa query Firestore, gunakan rules ini dulu:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Development: allow authenticated users to write (tidak aman untuk produksi)
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

**PRODUCTION MODE (aman):**
Setelah development selesai, gunakan rules ini:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function: cek apakah user adalah admin (dari koleksi users)
    function isAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Videos folder - hanya admin yang boleh menulis
    match /videos/{videoId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Thumbnails folder
    match /thumbnails/{thumbnailId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Folder lain: read public, write hanya admin
    match /{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

Catatan: Rules produksi cocok dengan struktur data Anda (admin disimpan di koleksi `users` dengan `role: "admin"`).

**Struktur data yang diperlukan di Firestore:**
```
Collection: users
  Document: <admin_uid>  (contoh: VIskqFTWQsg7muzczK7oFKIt1h82)
    - name: "tobok"
    - email: "tobok@test.com"
    - role: "admin"
    - createdAt: <timestamp>
    - last_login: <timestamp>
```


## Cara Menambahkan Admin

### Via Firebase Console (Manual):
1. Buka Firebase Console > Firestore Database
2. Klik "Start collection" atau pilih collection `admins`
3. Document ID: **email admin** (contoh: admin@example.com)
4. Field:
   - `role`: "admin"
   - `createdAt`: (timestamp)
   
### Via Postman/curl (jika ada backend API):
```bash
# Tidak applicable untuk setup ini
```

## Testing

1. Login sebagai admin di web panel
2. Coba upload video
3. Jika berhasil, berarti rules sudah benar
4. Jika gagal, cek di Firebase Console > Authentication apakah email sudah terdaftar

## Troubleshooting

**Error: "User is not authorized"**
- Pastikan email user ada di collection `admins`
- Pastikan user sudah login (check Firebase Auth)
- Pastikan rules sudah dipublish di Firebase Console

**Error: "Permission denied"**
- Rules belum di-deploy
- Email tidak match persis (case sensitive)
- User belum authenticated
