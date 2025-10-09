# 🛒 SelfOrder - Flutter App with Silverstripe RESTful API

**SelfOrder** adalah aplikasi Flutter untuk sistem pemesanan mandiri (**self-order**) yang terintegrasi dengan **RESTful API Silverstripe**. Aplikasi ini dirancang untuk memberikan pengalaman pemesanan makanan/minuman yang modern dan praktis, dengan fitur-fitur lengkap termasuk pembayaran, invoice, dan login Google.

---

## 🚀 Fitur Utama

* 🔐 Login dengan akun Google
* 💳 Integrasi pembayaran menggunakan **Duitku**
* 🧾 Unduh dan simpan file PDF invoice
* 📧 Pengiriman invoice melalui email
* 📡 Komunikasi API dengan backend **Silverstripe RESTful API**

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

## 🔐 Konfigurasi Keystore

### 🔸 Membuat Keystore untuk Rilis

Gunakan perintah berikut untuk membuat file keystore:

```bash
keytool -genkey -v -keystore selforder.keystore -alias selforder-key -keyalg RSA -keysize 2048 -validity 10000
```

Keterangan:

* `selforder.keystore`: Nama file keystore (boleh diubah).
* `selforder-key`: Alias dari kunci (bebas, misalnya `release-key`).
* `-keysize 2048`: Ukuran kunci.
* `-validity 10000`: Masa berlaku sertifikat dalam hari.

📌 Saat perintah dijalankan, Anda akan diminta mengisi:

* Password untuk keystore
* Nama lengkap, organisasi, kota, negara, dll
* Password untuk alias (boleh disamakan dengan keystore password)

---

## 🔍 Mendapatkan SHA1 Fingerprint

### Untuk Keystore Rilis:

```bash
keytool -list -v -keystore selforder.keystore -alias selforder-key
```

### Untuk Keystore Debug (Google Login):

```bash
keytool -list -v -keystore "C:\Users\<UserPCName>\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

📌 Masukkan SHA1 fingerprint ini ke Google Developer Console pada bagian **OAuth 2.0 Client ID**.

---

## 📚 Referensi

* [Flutter Codelab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Flutter Cookbook (Contoh-contoh Praktis)](https://docs.flutter.dev/cookbook)
* [Flutter Documentation (Official)](https://docs.flutter.dev)

---

## 🛠 Teknologi

* Flutter SDK
* Silverstripe CMS + RESTful API
* Duitku Payment Gateway
* Google Sign-In
* Email Sender (Invoice)

---

Jika kamu butuh bantuan lebih lanjut atau ingin kontribusi ke proyek ini, silakan buat *issue* atau *pull request*.

---