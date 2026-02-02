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
## 📂 Flutter Project Structure

```text
flutter_app/
├── android/                 # Android native configuration
│
├── ios/                     # iOS native configuration
│
├── assets/                  # Static assets
│   ├── images/              # Image assets
│   ├── icons/               # Icon assets
│   └── fonts/               # Custom fonts
│
├── lib/
│   ├── config/              # App configuration (env, constants, app config)
│   │   ├── app_config.dart
│   │   └── constants.dart
│   │
│   ├── controllers/         # State management / controllers
│   │   ├── auth_controller.dart
│   │   └── cart_controller.dart
│   │
│   ├── models/              # Data models
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   └── order_model.dart
│   │
│   ├── pages/               # UI pages / screens
│   │
│   ├── routes/              # App routing
│   │   └── app_routes.dart
│   │
│   ├── services/            # API & business services
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   │
│   ├── theme/               # App theme & styling
│   │   └── app_theme.dart
│   │
│   ├── widgets/             # Reusable UI components
│   │   ├── custom_button.dart
│   │   └── loading_widget.dart
│   │
│   └── main.dart             # Application entry point
│
├── pubspec.yaml              # Flutter dependencies & assets config
└── README.md                 # Project documentation
```
---
# Dokumentasi Flutter Controllers & Services

## Daftar Isi
- [Controllers](#controllers)
  - [AuthController](#authcontroller)
  - [ProductController](#productcontroller)
  - [CartController](#cartcontroller)
  - [OrderController](#ordercontroller)
  - [ReservationController](#reservationcontroller)
  - [SiteConfigController](#siteconfigcontroller)
  - [VersionController](#versioncontroller)
- [Services](#services)
  - [ApiService](#apiservice)
  - [AuthService](#authservice)
  - [ReservationService](#reservationservice)
  - [SessionManager](#sessionmanager)

---

## Controllers

### AuthController
Controller untuk mengelola state autentikasi pengguna menggunakan GetX.

#### Properties
- `currentUser` - Data user yang sedang login (Member model)
- `isLoggedIn` - Status login user (boolean)
- `isLoading` - Status loading saat proses autentikasi (boolean)

#### Methods

##### Authentication Methods

* **`login(String email, String password)`** - Login dengan email dan password
  - **Parameters**:
    - `email` - Email pengguna
    - `password` - Password pengguna
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**: 
    - Set currentUser
    - Load user data (cart, orders, reservations)
    - Notify auth state listeners

* **`loginWithGoogle()`** - Login menggunakan akun Google
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**: 
    - Trigger Google Sign-In flow
    - Set currentUser
    - Load user data
    - Notify auth state listeners

* **`register(String firstName, String lastName, String email, String password)`** - Registrasi akun baru
  - **Parameters**:
    - `firstName` - Nama depan
    - `lastName` - Nama belakang
    - `email` - Email
    - `password` - Password
  - **Return**: `Future<bool>` - true jika berhasil

* **`logout()`** - Logout user
  - **Side Effects**:
    - Clear currentUser
    - Clear user data (cart, orders)
    - Clear session
    - Notify auth state listeners

##### Profile Management

* **`updateProfile(String firstName, String lastName, String email, {String? password})`** - Update profil user
  - **Parameters**:
    - `firstName` - Nama depan baru
    - `lastName` - Nama belakang baru
    - `email` - Email baru
    - `password` - Password baru (optional)
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**: Update currentUser dengan data terbaru

##### Password Recovery

* **`forgotPassword(String email)`** - Request reset password
  - **Parameters**:
    - `email` - Email yang terdaftar
  - **Return**: `Future<Map<String, dynamic>>` - {success: bool, message: String}

##### Internal Methods

* **`_checkLoginStatus()`** - Cek status login saat init
  - **Private method** - Dipanggil otomatis di onInit()
  - Mengecek session dan fetch user data jika ada

* **`_loadUserData()`** - Load semua data user (products, cart, orders, reservations)
  - **Private method** - Dipanggil setelah login berhasil

* **`_clearUserData()`** - Clear semua data user
  - **Private method** - Dipanggil saat logout

---

### ProductController
Controller untuk mengelola daftar produk dengan pagination dan filtering menggunakan GetX.

#### Properties
- `categories` - List kategori produk
- `selectedCategoryId` - ID kategori yang dipilih untuk filter
- `selectedFilter` - Filter yang dipilih (populer, harga_tertinggi, harga_terendah)
- `guestCartQuantities` - Map jumlah item di cart untuk guest user
- `pagingController` - Controller untuk infinite scroll pagination

#### Methods

##### Product Loading

* **`loadCategories()`** - Load semua kategori produk
  - **Return**: `Future<void>`
  - **Side Effects**: Update list categories

* **`loadProducts()`** - Trigger reload produk
  - **Return**: `Future<void>`
  - **Side Effects**: Reset pagination controller

* **`_fetchProductPage(int pageKey)`** - Fetch produk dengan pagination
  - **Parameters**: `pageKey` - Nomor halaman
  - **Private method** - Dipanggil otomatis oleh pagingController
  - **Side Effects**: 
    - Append produk ke pagingController
    - Cache produk ke _productCache

##### Product Filtering

* **`selectCategory(int? categoryId)`** - Filter produk berdasarkan kategori
  - **Parameters**: `categoryId` - ID kategori (null untuk semua)
  - **Side Effects**: Reset pagination dengan filter baru

* **`selectFilter(String? filter)`** - Set filter produk
  - **Parameters**: `filter` - 'populer' | 'harga_tertinggi' | 'harga_terendah' | null
  - **Side Effects**: Reset pagination dengan filter baru

* **`resetPagination()`** - Reset pagination ke halaman pertama
  - **Side Effects**: Refresh pagingController

##### Product Cache Management

* **`getProductById(int productId)`** - Ambil produk dari cache atau pagingController
  - **Parameters**: `productId` - ID produk
  - **Return**: `Product?` - Product object atau null
  - **Use Case**: Digunakan untuk mendapatkan detail produk tanpa API call

* **`fetchAndCacheProduct(int productId)`** - Fetch produk dari API dan simpan ke cache
  - **Parameters**: `productId` - ID produk
  - **Return**: `Future<Product?>` - Product object atau null
  - **Side Effects**: Update _productCache

* **`preloadProductsByIds(List<int> productIds)`** - Preload multiple produk sekaligus
  - **Parameters**: `productIds` - List ID produk
  - **Return**: `Future<void>`
  - **Use Case**: Digunakan sebelum menampilkan cart untuk preload semua produk

* **`clearProductCache()`** - Hapus semua cache produk
  - **Side Effects**: Clear _productCache map

##### Guest Cart Management

* **`updateGuestCart(int productId, int quantity)`** - Update jumlah item di guest cart
  - **Parameters**: 
    - `productId` - ID produk
    - `quantity` - Jumlah item (0 untuk hapus)
  - **Use Case**: Untuk user yang belum login

* **`getGuestCartQuantity(int productId)`** - Ambil jumlah item di guest cart
  - **Parameters**: `productId` - ID produk
  - **Return**: `int` - Jumlah item atau 0

* **`clearGuestCart()`** - Clear guest cart
  - **Side Effects**: Clear guestCartQuantities map

##### Utility Methods

* **`refresh()`** - Refresh categories dan products
  - **Return**: `Future<void>`
  - **Use Case**: Pull to refresh

---

### CartController
Controller untuk mengelola keranjang belanja dengan optimistic updates dan debouncing.

#### Properties
- `cartItems` - List item di keranjang
- `paymentMethods` - List metode pembayaran yang tersedia
- `selectedPaymentMethod` - Metode pembayaran yang dipilih
- `isLoading` - Status loading cart items
- `isLoadingPayment` - Status loading payment methods
- `totalItems` - Total jumlah item di keranjang

#### Methods

##### Cart Data Management

* **`loadCartItems()`** - Load semua item di keranjang
  - **Return**: `Future<void>`
  - **Side Effects**: 
    - Update cartItems
    - Preload products untuk semua cart items
    - Load payment methods jika ada items

* **`loadPaymentMethods()`** - Load metode pembayaran berdasarkan total belanja
  - **Return**: `Future<void>`
  - **Side Effects**: Update paymentMethods list
  - **Condition**: Total harus > 0

##### Cart Operations

* **`addToCart(int productId, int quantity)`** - Tambah produk ke keranjang
  - **Parameters**:
    - `productId` - ID produk
    - `quantity` - Jumlah item yang ditambahkan
  - **Return**: `Future<void>`
  - **Features**:
    - Optimistic update
    - Debouncing (600ms) untuk prevent multiple API calls
    - Auto preload product
    - Show toast notification
  - **Auth**: Redirect ke login jika belum login

* **`updateQuantity(int cartItemId, int newQuantity)`** - Update jumlah item di keranjang
  - **Parameters**:
    - `cartItemId` - ID cart item
    - `newQuantity` - Jumlah baru (0 untuk hapus)
  - **Return**: `Future<void>`
  - **Features**:
    - Optimistic update
    - Debouncing (600ms)
    - Auto rollback jika gagal

* **`removeFromCart(int cartItemId)`** - Hapus item dari keranjang
  - **Parameters**: `cartItemId` - ID cart item
  - **Return**: `Future<void>`
  - **Features**:
    - Optimistic removal
    - Auto rollback jika gagal
    - Show toast notification

##### Payment & Checkout

* **`selectPaymentMethod(PaymentMethod? method)`** - Pilih metode pembayaran
  - **Parameters**: `method` - Payment method object
  - **Side Effects**: Update selectedPaymentMethod

* **`createOrder(String tableNumber)`** - Buat order dan proses checkout
  - **Parameters**: `tableNumber` - Nomor meja
  - **Return**: `Future<Order>` - Order object dengan payment URL
  - **Throws**: Exception jika belum login atau belum pilih payment method
  - **Side Effects**:
    - Clear cart items
    - Clear payment methods
    - Refresh OrderController
  - **Use Case**: Setelah success, redirect ke payment URL di Order object

##### Calculation Methods

* **`getCartQuantity(int productId)`** - Ambil jumlah produk di cart
  - **Parameters**: `productId` - ID produk
  - **Return**: `int` - Jumlah atau 0

* **`calculateSubtotal()`** - Hitung total harga barang
  - **Return**: `int` - Total harga tanpa biaya payment

* **`calculatePaymentFee()`** - Hitung biaya payment method
  - **Return**: `int` - Biaya payment atau 0

* **`calculateTotal()`** - Hitung total keseluruhan
  - **Return**: `int` - Subtotal + Payment Fee

##### Utility Methods

* **`clearCart()`** - Hapus semua data cart
  - **Side Effects**: Clear cartItems, paymentMethods, selectedPaymentMethod

* **`refresh()`** - Refresh cart dari server
  - **Return**: `Future<void>`
  - **Use Case**: Pull to refresh

##### Internal Methods

* **`_debounceApiCall(int productId, Function() callback)`** - Debounce API calls
  - **Private method**
  - **Parameters**:
    - `productId` - ID produk (sebagai key)
    - `callback` - Function yang akan dipanggil setelah delay
  - **Delay**: 600ms
  - **Use Case**: Prevent spam API calls saat user cepat klik +/-

---

### OrderController
Controller untuk mengelola daftar pesanan user menggunakan GetX.

#### Properties
- `orders` - List semua pesanan user
- `selectedFilter` - Filter status yang dipilih
- `isLoading` - Status loading orders
- `filterOptions` - List opsi filter yang tersedia
- `filteredOrders` - Orders yang sudah difilter berdasarkan selectedFilter

#### Methods

##### Order Management

* **`loadOrders()`** - Load semua pesanan user
  - **Return**: `Future<void>`
  - **Side Effects**: Update orders list
  - **Auth**: Return empty jika belum login

* **`setFilter(String filter)`** - Set filter status order
  - **Parameters**: `filter` - 'All' | 'Menunggu Pembayaran' | 'Antrean' | 'Proses' | 'Terkirim' | 'Dibatalkan'
  - **Side Effects**: Update selectedFilter

##### Invoice Operations

* **`sendInvoiceEmail(String orderId)`** - Kirim invoice ke email
  - **Parameters**: `orderId` - ID order
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**: Show toast notification

* **`downloadInvoicePdf(Order order)`** - Download invoice PDF
  - **Parameters**: `order` - Order object
  - **Return**: `Future<void>`
  - **Features**:
    - Request storage permission (Android)
    - Save to Downloads folder (Android) atau Documents (iOS)
    - Auto open file setelah download
    - Show toast notification
  - **Throws**: Exception jika platform tidak didukung

##### Utility Methods

* **`clearOrders()`** - Hapus semua data orders
  - **Side Effects**: Clear orders list

* **`refresh()`** - Refresh orders dari server
  - **Return**: `Future<void>`
  - **Use Case**: Pull to refresh

* **`addOrder(Order order)`** - Tambah order baru ke list
  - **Parameters**: `order` - Order object
  - **Side Effects**: Insert order di posisi pertama list
  - **Use Case**: Dipanggil setelah create order berhasil

---

### ReservationController
Controller untuk mengelola reservasi meja menggunakan GetX.

#### Properties
- `reservations` - List semua reservasi user
- `selectedFilter` - Filter status yang dipilih
- `isLoading` - Status loading reservations
- `paymentMethods` - List metode pembayaran untuk reservasi
- `selectedPaymentMethod` - Metode pembayaran yang dipilih
- `filterOptions` - List opsi filter yang tersedia
- `filteredReservations` - Reservasi yang sudah difilter

#### Methods

##### Reservation Management

* **`loadReservations()`** - Load semua reservasi user
  - **Return**: `Future<void>`
  - **Side Effects**: Update reservations list
  - **Auth**: Return empty jika belum login

* **`createReservation({...})`** - Buat reservasi baru
  - **Parameters**:
    - `namaReservasi` - Nama pemesan
    - `jumlahKursi` - Jumlah kursi
    - `waktuMulai` - Waktu mulai (DateTime string)
    - `waktuSelesai` - Waktu selesai (DateTime string)
    - `catatan` - Catatan tambahan (optional)
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**: 
    - Reload reservations
    - Show toast notification

* **`cancelReservation(int id)`** - Batalkan reservasi
  - **Parameters**: `id` - ID reservasi
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**:
    - Reload reservations
    - Show toast notification

* **`setFilter(String filter)`** - Set filter status reservasi
  - **Parameters**: `filter` - Status filter
  - **Side Effects**: Update selectedFilter

##### Payment Operations

* **`loadPaymentMethods(int amount)`** - Load metode pembayaran
  - **Parameters**: `amount` - Total yang harus dibayar
  - **Return**: `Future<void>`
  - **Side Effects**: Update paymentMethods list

* **`selectPaymentMethod(ReservationPaymentMethod? method)`** - Pilih metode pembayaran
  - **Parameters**: `method` - Payment method object
  - **Side Effects**: Update selectedPaymentMethod

* **`processPayment(int reservationId)`** - Proses pembayaran reservasi
  - **Parameters**: `reservationId` - ID reservasi
  - **Return**: `Future<Map<String, dynamic>>` - {success: bool, message: String, data: {...}}
  - **Throws**: Exception jika belum pilih payment method
  - **Side Effects**: 
    - Update reservation status
    - Clear selected payment method
    - Show toast notification
  - **Response Data**: Berisi payment_url untuk redirect ke gateway

##### Receipt Operations

* **`downloadReservationPdf(Reservation reservation)`** - Download tanda terima PDF
  - **Parameters**: `reservation` - Reservation object
  - **Return**: `Future<void>`
  - **Features**:
    - Request storage permission (Android)
    - Save to Downloads folder
    - Auto open file
    - Show toast notification
  - **Condition**: Hanya untuk status "Selesai"

* **`sendReservationEmail(int id)`** - Kirim tanda terima ke email
  - **Parameters**: `id` - ID reservasi
  - **Return**: `Future<bool>` - true jika berhasil
  - **Side Effects**: Show toast notification
  - **Condition**: Hanya untuk status "Selesai"

##### Utility Methods

* **`clearReservations()`** - Hapus semua data reservasi
  - **Side Effects**: Clear reservations list

* **`refresh()`** - Refresh reservations dari server
  - **Return**: `Future<void>`
  - **Use Case**: Pull to refresh

---

### SiteConfigController
Controller untuk mengelola konfigurasi website/app menggunakan GetX.

#### Properties
- `siteConfig` - Object konfigurasi site
- `isLoading` - Status loading config

#### Methods

* **`loadSiteConfig()`** - Load konfigurasi site
  - **Return**: `Future<void>`
  - **Side Effects**: Update siteConfig
  - **Optimization**: Tidak reload jika sudah ada data

**Use Case**: 
- Mendapatkan logo, nama aplikasi
- Mendapatkan biaya reservasi default
- Mendapatkan informasi kontak, alamat

---

### VersionController
Controller untuk cek versi aplikasi dan force update menggunakan GetX.

#### Properties
- `isLoading` - Status loading version check
- `currentVersion` - Versi aplikasi saat ini
- `serverVersion` - Versi terbaru dari server
- `needsUpdate` - Flag apakah perlu update

#### Methods

* **`checkVersion()`** - Cek versi aplikasi
  - **Return**: `Future<void>`
  - **Side Effects**:
    - Get current version dari PackageInfo
    - Fetch server version dari API
    - Compare versions
    - Set needsUpdate flag
  - **Logic**: needsUpdate = true jika server version > current version

* **`getVersionStatus()`** - Ambil status versi dari server
  - **Return**: `String` - Status ('stable', 'beta', dll)

* **`getReleaseDate()`** - Ambil tanggal rilis versi terbaru
  - **Return**: `String` - Tanggal rilis

**Use Case**:
- Force update jika versi terlalu lama
- Tampilkan dialog update available
- Block akses jika versi tidak kompatibel

---

## Services

### ApiService
Service untuk semua HTTP request ke backend API.

#### Static Properties
- `_baseUrl` - Base URL API dari AppConfig

#### Methods

##### App Version

* **`checkAppVersion()`** - Cek versi terbaru dari server
  - **Endpoint**: GET `/appversion`
  - **Return**: `Future<AppVersion>`
  - **Headers**: Session headers

##### Site Configuration

* **`fetchSiteConfig()`** - Fetch konfigurasi site
  - **Endpoint**: GET `/siteconfig`
  - **Return**: `Future<SiteConfig>`
  - **Headers**: Session headers
  - **Auth**: Yes (update session dari response)

##### Categories

* **`fetchCategories()`** - Fetch semua kategori produk
  - **Endpoint**: GET `/categories`
  - **Return**: `Future<List<CategoryProduct>>`
  - **Headers**: Session headers
  - **Auth**: Yes

##### Products

* **`fetchProducts({...})`** - Fetch produk dengan pagination dan filter
  - **Endpoint**: GET `/products`
  - **Parameters**:
    - `categoryId` - Filter kategori (optional)
    - `filter` - Sort filter (optional)
    - `page` - Nomor halaman (default: 1)
    - `limit` - Item per halaman (default: 6)
  - **Return**: `Future<List<Product>>`
  - **Headers**: Session headers
  - **Auth**: Yes

* **`fetchProductById(int productId)`** - Fetch detail produk
  - **Endpoint**: GET `/products/{id}`
  - **Parameters**: `productId` - ID produk
  - **Return**: `Future<Product?>` - null jika tidak ditemukan
  - **Headers**: Session headers
  - **Auth**: Yes

##### Payment Methods

* **`fetchPaymentMethods(int amount)`** - Fetch metode pembayaran
  - **Endpoint**: POST `/paymentmethods`
  - **Parameters**: `amount` - Total yang akan dibayar
  - **Return**: `Future<List<PaymentMethod>>`
  - **Body**: `{"amount": amount}`
  - **Headers**: Session headers + Content-Type
  - **Note**: Payment fee dihitung berdasarkan amount

##### Cart Operations

* **`fetchCartItems()`** - Fetch semua item di keranjang
  - **Endpoint**: GET `/cart`
  - **Return**: `Future<List<CartItem>>` - Empty list jika belum login
  - **Headers**: Session headers
  - **Auth**: Required

* **`addToCart(int productId, int quantity)`** - Tambah item ke keranjang
  - **Endpoint**: POST `/cart`
  - **Parameters**:
    - `productId` - ID produk
    - `quantity` - Jumlah item
  - **Return**: `Future<CartItem>` - Cart item yang dibuat/diupdate
  - **Body**: `{"produk_id": productId, "kuantitas": quantity}`
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 201 Created

* **`updateCartItem(int cartItemId, int quantity)`** - Update jumlah item
  - **Endpoint**: PUT `/cart/{id}`
  - **Parameters**:
    - `cartItemId` - ID cart item
    - `quantity` - Jumlah baru
  - **Return**: `Future<CartItem>` - Cart item yang diupdate
  - **Body**: `{"kuantitas": quantity}`
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 200 OK

* **`removeFromCart(int cartItemId)`** - Hapus item dari keranjang
  - **Endpoint**: DELETE `/cart/{id}`
  - **Parameters**: `cartItemId` - ID cart item
  - **Return**: `Future<void>`
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 200 OK

* **`clearCart()`** - Hapus semua item di keranjang
  - **Logic**: Fetch semua items lalu hapus satu per satu
  - **Return**: `Future<void>`
  - **Auth**: Required

##### Orders

* **`fetchOrders()`** - Fetch semua pesanan user
  - **Endpoint**: GET `/orders`
  - **Return**: `Future<List<Order>>` - Empty list jika belum login
  - **Headers**: Session headers
  - **Auth**: Required

* **`createOrderWithPayment({...})`** - Buat order dengan pembayaran
  - **Endpoint**: POST `/orders`
  - **Parameters**:
    - `tableNumber` - Nomor meja
    - `paymentMethod` - Kode metode pembayaran
  - **Return**: `Future<Order>` - Order dengan payment_url
  - **Body**: `{"nomor_meja": tableNumber, "payment_method": paymentMethod}`
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 201 Created
  - **Throws**: Exception dengan error message dari server

* **`sendInvoiceEmail(String orderId)`** - Kirim invoice ke email
  - **Endpoint**: POST `/orders/{id}/send-email`
  - **Parameters**: `orderId` - ID order
  - **Return**: `Future<bool>` - true jika status 200
  - **Headers**: Session headers
  - **Auth**: Required

* **`getInvoicePdfBytes(String orderId)`** - Download invoice PDF
  - **Endpoint**: GET `/orders/{id}/pdf`
  - **Parameters**: `orderId` - ID order
  - **Return**: `Future<Uint8List>` - PDF bytes
  - **Headers**: Session headers
  - **Auth**: Required
  - **Response**: `{"pdf_base64": "..."}`
  - **Throws**: Exception jika PDF tidak tersedia

##### Session Handling

* **`_handleResponse(http.Response response)`** - Handle response dan update session
  - **Private method**
  - **Parameters**: `response` - HTTP Response object
  - **Side Effects**: 
    - Update session cookie dari response
    - Throw Exception jika status 401 (session expired)

---

### AuthService
Service untuk autentikasi dan manajemen user session.

#### Static Properties
- `currentUser` - Current logged in user (Member)
- `isLoggedIn` - Status login (bool)
- `_authStateListeners` - List callback untuk auth state changes
- `_googleSignIn` - Google Sign-In instance

#### Methods

##### Authentication

* **`init()`** - Inisialisasi auth service
  - **Return**: `Future<void>`
  - **Side Effects**:
    - Init SessionManager
    - Restore user dari session jika ada
    - Fetch current member data
    - Notify auth listeners
  - **Use Case**: Dipanggil di app startup

* **`login(String email, String password)`** - Login dengan email/password
  - **Endpoint**: POST `/login`
  - **Parameters**:
    - `email` - Email user
    - `password` - Password
  - **Return**: `Future<bool>` - true jika berhasil
  - **Body**: `{"email": email, "password": password}`
  - **Side Effects**:
    - Save session cookie
    - Set currentUser
    - Send FCM token
    - Notify auth listeners
  - **Status Code**: 200 OK

* **`loginWithGoogle()`** - Login dengan Google OAuth
  - **Endpoint**: POST `/google-auth`
  - **Return**: `Future<bool>` - true jika berhasil
  - **Flow**:
    1. Sign out dari Google (clear prev session)
    2. Trigger Google Sign-In
    3. Get Google auth tokens
    4. Send tokens ke backend
    5. Save session
    6. Send FCM token
  - **Body**: 
    ```json
    {
      "id_token": "...",
      "access_token": "...",
      "email": "...",
      "display_name": "...",
      "photo_url": "..."
    }
    ```
  - **Side Effects**:
    - Save session cookie
    - Set currentUser
    - Send FCM token
    - Notify auth listeners
  - **Status Code**: 200 OK

* **`register(String firstName, String lastName, String email, String password)`** - Registrasi user baru
  - **Endpoint**: POST `/register`
  - **Parameters**:
    - `firstName` - Nama depan
    - `lastName` - Nama belakang
    - `email` - Email
    - `password` - Password
  - **Return**: `Future<bool>` - true jika berhasil
  - **Body**: 
    ```json
    {
      "first_name": firstName,
      "surname": lastName,
      "email": email,
      "password": password
    }
    ```
  - **Status Code**: 201 Created

* **`logout()`** - Logout user
  - **Endpoint**: POST `/logout`
  - **Return**: `Future<bool>` - always true
  - **Side Effects**:
    - Call logout API
    - Sign out dari Google
    - Clear currentUser
    - Clear session
    - Notify auth listeners

##### Profile Management

* **`fetchCurrentMember()`** - Fetch data user terbaru
  - **Endpoint**: GET `/member`
  - **Return**: `Future<Member?>` - null jika tidak login/error
  - **Headers**: Session headers
  - **Side Effects**:
    - Update currentUser
    - Update session user data
    - Send FCM token
    - Notify auth listeners
  - **Error Handling**: Auto logout jika 401

* **`updateProfile(String firstName, String lastName, String email, {String? password})`** - Update profil user
  - **Endpoints**: 
    - PUT `/member` - Update profile data
    - PUT `/member/password` - Update password (jika ada)
  - **Parameters**:
    - `firstName` - Nama depan baru
    - `lastName` - Nama belakang baru
    - `email` - Email baru
    - `password` - Password baru (optional)
  - **Return**: `Future<bool>` - true jika berhasil
  - **Body Profile**: 
    ```json
    {
      "first_name": firstName,
      "surname": lastName,
      "email": email
    }
    ```
  - **Body Password**: `{"new_password": password}`
  - **Side Effects**:
    - Update currentUser
    - Update session user data
    - Notify auth listeners
  - **Status Code**: 200 OK

##### Password Recovery

* **`forgotPassword(String email)`** - Request reset password
  - **Endpoint**: POST `/forgotpassword`
  - **Parameters**: `email` - Email yang terdaftar
  - **Return**: `Future<Map<String, dynamic>>` - {success: bool, message: String}
  - **Body**: `{"email": email}`
  - **Status Code**: 200 OK jika berhasil

##### Push Notifications

* **`sendFcmTokenToServer(String token)`** - Kirim FCM token ke server
  - **Endpoint**: POST `/fcm-token`
  - **Parameters**: `token` - FCM device token
  - **Return**: `Future<bool>` - true jika berhasil
  - **Body**: 
    ```json
    {
      "token": token,
      "device_name": "Android Device" / "iOS Device"
    }
    ```
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 200 atau 201
  - **Use Case**: Untuk push notification pesanan/reservasi

##### Auth State Listeners

* **`addAuthStateListener(Function() listener)`** - Tambah listener untuk auth changes
  - **Parameters**: `listener` - Callback function
  - **Side Effects**: Add ke _authStateListeners list

* **`removeAuthStateListener(Function() listener)`** - Hapus listener
  - **Parameters**: `listener` - Callback function
  - **Side Effects**: Remove dari _authStateListeners list

* **`clearAuthStateListeners()`** - Hapus semua listeners
  - **Side Effects**: Clear _authStateListeners list

* **`_notifyAllAuthStateListeners()`** - Trigger semua listeners
  - **Private method**
  - **Side Effects**: Call semua registered listeners
  - **Error Handling**: Auto remove listener jika throw error

---

### ReservationService
Service untuk operasi reservasi meja.

#### Static Properties
- `_baseUrl` - Base URL API dari AppConfig

#### Methods

##### Reservation CRUD

* **`fetchReservations()`** - Fetch semua reservasi user
  - **Endpoint**: GET `/reservations`
  - **Return**: `Future<List<Reservation>>` - Empty list jika belum login
  - **Headers**: Session headers
  - **Auth**: Required

* **`fetchReservationDetail(int id)`** - Fetch detail reservasi
  - **Endpoint**: GET `/reservations/{id}`
  - **Parameters**: `id` - ID reservasi
  - **Return**: `Future<Reservation?>` - null jika tidak ditemukan
  - **Headers**: Session headers
  - **Auth**: Required

* **`createReservation({...})`** - Buat reservasi baru
  - **Endpoint**: POST `/reservations`
  - **Parameters**:
    - `namaReservasi` - Nama pemesan (required)
    - `jumlahKursi` - Jumlah kursi (required)
    - `waktuMulai` - Waktu mulai ISO 8601 (required)
    - `waktuSelesai` - Waktu selesai ISO 8601 (required)
    - `catatan` - Catatan tambahan (optional)
  - **Return**: `Future<Map<String, dynamic>>` 
    ```json
    {
      "success": true,
      "message": "...",
      "data": Reservation
    }
    ```
  - **Body**: 
    ```json
    {
      "nama_reservasi": "...",
      "jumlah_kursi": 4,
      "waktu_mulai": "2024-01-15T18:00:00",
      "waktu_selesai": "2024-01-15T20:00:00",
      "catatan": "..." // optional
    }
    ```
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 201 Created

* **`cancelReservation(int id)`** - Batalkan reservasi
  - **Endpoint**: POST `/reservations/{id}/cancel`
  - **Parameters**: `id` - ID reservasi
  - **Return**: `Future<Map<String, dynamic>>` - {success: bool, message: String}
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 200 OK

##### Payment

* **`fetchPaymentMethods(int amount)`** - Fetch metode pembayaran
  - **Endpoint**: POST `/reservationpaymentmethods`
  - **Parameters**: `amount` - Total yang akan dibayar
  - **Return**: `Future<List<ReservationPaymentMethod>>`
  - **Body**: `{"amount": amount}`
  - **Headers**: Session headers

* **`processPayment({...})`** - Proses pembayaran reservasi
  - **Endpoint**: POST `/reservations/{id}/payment`
  - **Parameters**:
    - `reservationId` - ID reservasi
    - `paymentMethod` - Kode metode pembayaran
  - **Return**: `Future<Map<String, dynamic>>` 
    ```json
    {
      "success": true,
      "message": "...",
      "data": {
        "payment_url": "https://...",
        "reference": "...",
        ...
      }
    }
    ```
  - **Body**: `{"payment_method": paymentMethod}`
  - **Headers**: Session headers
  - **Auth**: Required
  - **Status Code**: 200 OK

##### Receipt

* **`downloadReservationPDF(int id)`** - Download tanda terima PDF
  - **Endpoint**: GET `/reservations/{id}/pdf`
  - **Parameters**: `id` - ID reservasi
  - **Return**: `Future<Uint8List?>` - PDF bytes atau null
  - **Headers**: Session headers
  - **Auth**: Required
  - **Response**: `{"success": true, "data": {"pdf_base64": "..."}}`

* **`sendReservationEmail(int id)`** - Kirim tanda terima ke email
  - **Endpoint**: POST `/reservations/{id}/send-email`
  - **Parameters**: `id` - ID reservasi
  - **Return**: `Future<bool>` - true jika status 200
  - **Headers**: Session headers
  - **Auth**: Required

##### Session Handling

* **`_handleResponse(http.Response response)`** - Handle response dan update session
  - **Private method**
  - **Parameters**: `response` - HTTP Response object
  - **Side Effects**: 
    - Update session cookie
    - Throw Exception jika 401

---

### SessionManager
Service untuk manajemen session dan local storage.

#### Static Properties
- `_keyIsLoggedIn` - Key untuk login status
- `_keyUserData` - Key untuk user data
- `_keySessionCookie` - Key untuk session cookie
- `_prefs` - SharedPreferences instance
- `_sessionCookie` - Current session cookie

#### Methods

##### Initialization

* **`init()`** - Inisialisasi SessionManager
  - **Return**: `Future<void>`
  - **Side Effects**:
    - Init SharedPreferences
    - Load session cookie dari storage
  - **Use Case**: Dipanggil di app startup sebelum AuthService.init()

##### Session Management

* **`saveSession(Map<String, dynamic> userData, String? cookie)`** - Simpan session
  - **Parameters**:
    - `userData` - Data user (Map dari Member.toJson())
    - `cookie` - Set-Cookie header dari response
  - **Return**: `Future<void>`
  - **Side Effects**:
    - Save isLoggedIn = true
    - Save userData ke SharedPreferences
    - Extract dan save PHPSESSID dari cookie
    - Update _sessionCookie
  - **Cookie Format**: Extract "PHPSESSID=..." dari Set-Cookie header

* **`updateUserData(Map<String, dynamic> userData)`** - Update user data
  - **Parameters**: `userData` - Data user baru
  - **Return**: `Future<void>`
  - **Side Effects**: Update userData di SharedPreferences
  - **Use Case**: Dipanggil setelah update profile

* **`clearSession()`** - Hapus session
  - **Return**: `Future<void>`
  - **Side Effects**:
    - Set isLoggedIn = false
    - Remove userData
    - Remove sessionCookie
    - Clear _sessionCookie
  - **Use Case**: Dipanggil saat logout

##### Getters

* **`isLoggedIn`** - Cek status login
  - **Return**: `bool` - true jika user login
  - **Source**: SharedPreferences

* **`currentUser`** - Get current user data
  - **Return**: `Map<String, dynamic>?` - User data atau null
  - **Source**: SharedPreferences (JSON decoded)

* **`sessionCookie`** - Get session cookie
  - **Return**: `String?` - PHPSESSID cookie atau null

##### HTTP Headers

* **`getHeaders()`** - Get HTTP headers dengan session
  - **Return**: `Map<String, String>` - Headers untuk HTTP request
  - **Headers**:
    ```dart
    {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cookie': 'PHPSESSID=...' // jika ada session
    }
    ```
  - **Use Case**: Digunakan di semua authenticated API calls

* **`updateSessionFromResponse(http.Response response)`** - Update session dari response
  - **Parameters**: `response` - HTTP Response object
  - **Side Effects**:
    - Extract Set-Cookie header
    - Update _sessionCookie
    - Save ke SharedPreferences
  - **Use Case**: Dipanggil di setiap API response untuk refresh session

---

## Architecture Overview

### State Management
- Menggunakan **GetX** untuk reactive state management
- Controllers di-register sebagai singleton menggunakan `Get.put()` atau `Get.lazyPut()`
- Reactive variables menggunakan `.obs` dan `.value`

### Data Flow

#### Login Flow
```
User Input → AuthController.login()
           → AuthService.login() [API Call]
           → SessionManager.saveSession() [Save to Local Storage]
           → AuthController._loadUserData()
              → ProductController.refresh()
              → CartController.loadCartItems()
              → OrderController.loadOrders()
              → ReservationController.loadReservations()
           → Notify UI (GetX reactive)
```

#### Add to Cart Flow
```
User Action → CartController.addToCart()
            → ProductController.fetchAndCacheProduct() [Cache product]
            → Optimistic Update (add to local list)
            → Debounce Timer (600ms)
            → ApiService.addToCart() [API Call]
            → Update with server response
            → Show Toast Notification
            (If Error: Rollback + Reload from server)
```

#### Checkout Flow
```
User Checkout → CartController.createOrder()
              → ApiService.createOrderWithPayment() [API Call]
              → Clear cart items
              → OrderController.refresh()
              → Navigate to Payment Gateway (Order.paymentUrl)
              → [User pays at gateway]
              → Callback to Backend
              → Order Status Updated
              → Email Invoice Sent
```

### Error Handling

#### Network Errors
- All API calls wrapped in try-catch
- Toast notifications untuk user feedback
- Optimistic updates dengan rollback mechanism

#### Session Expiry
- Auto-detect 401 response
- Auto logout user
- Redirect ke login page

#### Loading States
- `isLoading` observable di setiap controller
- Tampilkan loading indicator di UI
- Prevent multiple simultaneous requests

### Caching Strategy

#### Product Cache
- Cache di `ProductController._productCache`
- Preload products untuk cart items
- Cache never expires (single session)
- Clear saat logout

#### Session Cache
- Session cookie disimpan di SharedPreferences
- Auto restore saat app restart
- Update dari setiap API response

### Performance Optimizations

#### Debouncing
- Cart quantity updates debounced 600ms
- Prevent spam API calls
- Aggregate multiple changes into single request

#### Pagination
- Infinite scroll dengan `PagingController`
- Load 6 items per page
- Auto load next page saat scroll

#### Lazy Loading
- Controllers di-register dengan `Get.lazyPut()`
- Only initialized saat pertama kali digunakan

---

## Environment Variables

Pastikan file `app_config.dart` berisi:

```dart
class AppConfig {
  static const String baseUrl = 'YOUR_API_BASE_URL';
  
  // Google Sign-In (opsional, bisa di firebase config juga)
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
}
```

## Dependencies Required

```yaml
dependencies:
  get: ^4.6.5
  http: ^1.1.0
  shared_preferences: ^2.2.2
  google_sign_in: ^6.1.5
  firebase_messaging: ^14.7.3
  toastification: ^1.0.0
  infinite_scroll_pagination: ^4.0.0
  open_file: ^3.3.2
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  package_info_plus: ^5.0.1
```

## Best Practices

1. **Always check authentication** sebelum API calls yang butuh auth
2. **Use optimistic updates** untuk better UX
3. **Implement debouncing** untuk prevent spam requests
4. **Cache data** yang sering diakses
5. **Handle errors gracefully** dengan toast notifications
6. **Auto logout** saat session expired
7. **Preload data** yang akan digunakan
8. **Clear sensitive data** saat logout

---

## Common Issues & Solutions

### Issue: Session Expired
**Solution**: Auto logout dipanggil, user perlu login ulang

### Issue: Product not found in cart
**Solution**: Preload products sebelum render cart dengan `preloadProductsByIds()`

### Issue: Debounce tidak bekerja
**Solution**: Pastikan setiap product punya timer terpisah di `_debounceTimers` map

### Issue: Cart quantity tidak update
**Solution**: Cek apakah `productCache` sudah ada product tersebut

### Issue: Payment URL tidak ada
**Solution**: Cek response dari `createOrderWithPayment()`, pastikan backend return `payment_url`

---

## API Response Format

Semua API endpoint mengikuti format standar:

### Success Response
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... } // atau array
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "message": "User friendly message"
}
```

### Pagination Response
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "page": 1,
    "limit": 6,
    "total": 24,
    "hasMore": true
  }
}
```

---

**Last Updated**: February 2026  
**Version**: 1.0.0
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
