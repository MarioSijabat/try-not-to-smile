# 🚀 Build Commands - Try Not To Smile

## 📱 **Mobile App (User)**

### Android
```bash
# Development
flutter run -d android

# Build APK untuk testing
flutter build apk --release

# Build APK split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi

# Build App Bundle untuk Play Store
flutter build appbundle --release
```

### iOS
```bash
# Development
flutter run -d ios

# Build untuk iOS
flutter build ios --release

# Build IPA (perlu Xcode)
flutter build ipa --release
```

---

## 💻 **Web App (Admin Panel)**

### Metode 1: Auto-detect (Main.dart akan detect platform)
```bash
# Development
flutter run -d chrome

# Build Production
flutter build web --release

# Build dengan HTML renderer (lebih kompatibel)
flutter build web --release --web-renderer html
```

### Metode 2: Dedicated Admin Entry (Recommended)
```bash
# Development dengan entry point khusus admin
flutter run -d chrome -t lib/main_web_admin.dart

# Build Production khusus Admin Panel
flutter build web --release -t lib/main_web_admin.dart --web-renderer html

# Output akan ada di: build/web/
```

---

## 🎯 **Workflow Rekomendasi**

### Develop Mobile (User App)
1. Sambungkan device/emulator Android/iOS
2. Run: `flutter run`
3. Code di `lib/screens/` untuk user features
4. Tombol admin di main menu akan muncul untuk testing

### Develop Web (Admin Panel)
1. Run: `flutter run -d chrome -t lib/main_web_admin.dart`
2. Code di `lib/screens/admin_panel_screen.dart`
3. Test authentication dan admin features
4. Admin panel langsung muncul tanpa main menu

---

## 📦 **Deploy**

### Mobile
- **Android**: Upload APK/AAB ke Google Play Console
- **iOS**: Upload IPA ke App Store Connect via Xcode

### Web (Admin Panel)
```bash
# Build
flutter build web --release -t lib/main_web_admin.dart

# Deploy build/web/ ke:
# - Firebase Hosting
# - Netlify
# - Vercel
# - Any static hosting
```

**Firebase Hosting Example:**
```bash
firebase init hosting
# Point to build/web directory
firebase deploy --only hosting
```

---

## 🔍 **Testing Platform Detection**

### Check current platform:
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### Check in running app:
```dart
import 'dart:io' show Platform;

if (Platform.isAndroid) { /* Android */ }
if (Platform.isIOS) { /* iOS */ }
// Note: Platform tidak tersedia di Web, gunakan kIsWeb
```

---

## ⚙️ **Configuration Files**

### Mobile
- Android: `android/app/build.gradle.kts`
- iOS: `ios/Runner/Info.plist`
- Icons: `android/app/src/main/res/` & `ios/Runner/Assets.xcassets/`

### Web
- Entry: `web/index.html`
- Manifest: `web/manifest.json`
- Icons: `web/icons/`

---

## 🐛 **Troubleshooting**

### Mobile tidak detect device
```bash
flutter devices
# Pastikan device muncul di list
```

### Web error CORS/Firebase
- Check Firebase configuration di `firebase_options.dart`
- Enable Web platform di Firebase Console

### Build error
```bash
flutter clean
flutter pub get
flutter build [platform]
```
