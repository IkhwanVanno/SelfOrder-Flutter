# 🛒 SelfOrder - Flutter App with Silverstripe RESTful API

**SelfOrder** adalah aplikasi Flutter untuk sistem pemesanan mandiri (**self-order**) yang terintegrasi dengan **RESTful API Silverstripe**. Aplikasi ini dirancang untuk memberikan pengalaman pemesanan makanan/minuman yang modern dan praktis, dengan fitur-fitur lengkap termasuk pembayaran, invoice, dan login Google.

---

## 🚀 Fitur Utama

- 🔐 Login dengan akun Google
- 💳 Integrasi pembayaran menggunakan **Duitku**
- 🧾 Unduh dan simpan file PDF invoice
- 📧 Pengiriman invoice melalui email
- 📡 Komunikasi API dengan backend **Silverstripe RESTful API**

---

## 📦 Persiapan Awal

### 1. Clone Project dan Install Dependency

```bash
git clone <repository-url>
cd SelfOrder
flutter pub get
```

### 2. Jalankan Project

```bash
flutter run
```

---

## 🔐 Konfigurasi Login Google (Firebase)

### Langkah Umum (Android & iOS)

1. **Masuk ke Firebase Console**:
   [https://console.firebase.google.com](https://console.firebase.google.com)

2. **Buat atau pilih project Firebase** yang akan digunakan.

3. **Tambahkan aplikasi Android dan iOS**:

   - Untuk Android, masukkan `applicationId` (misal: `com.example.selforder`)
   - Untuk iOS, masukkan `Bundle ID` (misal: `com.example.selforder`)

4. **Unduh file konfigurasi dari Firebase**:

   - **Android:** Unduh `google-services.json`
   - **iOS:** Unduh `GoogleService-Info.plist`

5. **Letakkan file ke folder berikut**:

   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

6. **Tambahkan SHA-1 debug ke Firebase** (jika login Google tidak bekerja):

   Jalankan perintah berikut di terminal:

   ```bash
   keytool -genkey -v -keystore "C:\Users\PCUSERNAME\.android\debug.keystore" -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US"
   ```

   ## cara chek debugkey(keyStore)
   ```bash
   .\gradlew signingReport 
   ```
   # atau
   ```bash
   keytool -list -v -keystore "C:\Users\PCUSERNAME\.android\debug.keystore" -storepass android
   ```

   Masukkan SHA-1 ke Firebase Console > Project Settings > Android App.

---

## 📚 Referensi

- [Flutter Codelab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook (Contoh-contoh Praktis)](https://docs.flutter.dev/cookbook)
- [Flutter Documentation (Official)](https://docs.flutter.dev)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com/)

---

## 🛠 Teknologi

- Flutter SDK
- Silverstripe CMS + RESTful API
- Duitku Payment Gateway
- Google Sign-In
- Email Sender (Invoice)

---

Jika kamu butuh bantuan lebih lanjut atau ingin kontribusi ke proyek ini, silakan buat _issue_ atau _pull request_.

---
