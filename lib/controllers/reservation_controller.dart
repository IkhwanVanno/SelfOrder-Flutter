import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/models/reservation_model.dart';
import 'package:selforder/models/reservation_payment_method_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/reservation_service.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservationController extends GetxController {
  final _reservations = <Reservation>[].obs;
  final _isLoading = false.obs;
  final _selectedFilter = 'Semua'.obs;
  final _siteConfig = Rx<dynamic>(null);

  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading.value;
  String get selectedFilter => _selectedFilter.value;
  double get biayaPerJam => _siteConfig.value?.biayaReservasi ?? 50000.0;

  AuthController get _authController => Get.find<AuthController>();

  List<String> get filterOptions => [
    'Semua',
    'Menunggu Persetujuan',
    'Disetujui',
    'Ditolak',
    'Menunggu Pembayaran',
    'Selesai',
    'Dibatalkan',
  ];

  List<Reservation> get filteredReservations {
    if (_selectedFilter.value == 'Semua') {
      return _reservations;
    }
    return _reservations
        .where(
          (reservation) => reservation.status.label == _selectedFilter.value,
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadSiteConfig();
    if (_authController.isLoggedIn) {
      loadReservations();
    }
  }

  Future<void> loadSiteConfig() async {
    try {
      final config = await ApiService.fetchSiteConfig();
      _siteConfig.value = config;
    } catch (e) {
      print('Failed to load site config: $e');
      // Use default value
    }
  }

  Future<void> loadReservations() async {
    if (!_authController.isLoggedIn) {
      _reservations.clear();
      return;
    }

    _isLoading.value = true;
    try {
      final reservations = await ReservationService.fetchReservations();
      _reservations.value = reservations;
    } catch (e) {
      print('Failed to load reservations: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal memuat data reservasi'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Reservation?> loadReservationDetail(int id) async {
    try {
      return await ReservationService.fetchReservationDetail(id);
    } catch (e) {
      print('Failed to load reservation detail: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal memuat detail reservasi'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return null;
    }
  }

  Future<bool> createReservation({
    required String namaReservasi,
    required int jumlahKursi,
    required DateTime waktuMulai,
    required DateTime waktuSelesai,
    String? catatan,
  }) async {
    try {
      final result = await ReservationService.createReservation(
        namaReservasi: namaReservasi,
        jumlahKursi: jumlahKursi,
        waktuMulai: waktuMulai.toIso8601String(),
        waktuSelesai: waktuSelesai.toIso8601String(),
        catatan: catatan,
      );

      if (result['success'] == true) {
        toastification.show(
          title: const Text('Success'),
          description: Text(result['message']),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        await loadReservations();
        return true;
      } else {
        toastification.show(
          title: const Text('Error'),
          description: Text(result['message']),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        return false;
      }
    } catch (e) {
      print('Create reservation error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Terjadi kesalahan saat membuat reservasi'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return false;
    }
  }

  Future<bool> cancelReservation(int id) async {
    try {
      final result = await ReservationService.cancelReservation(id);

      if (result['success'] == true) {
        toastification.show(
          title: const Text('Success'),
          description: Text(result['message']),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        await loadReservations();
        return true;
      } else {
        toastification.show(
          title: const Text('Error'),
          description: Text(result['message']),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        return false;
      }
    } catch (e) {
      print('Cancel reservation error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Terjadi kesalahan saat membatalkan reservasi'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return false;
    }
  }

  Future<List<ReservationPaymentMethod>> getPaymentMethods(int amount) async {
    try {
      return await ReservationService.fetchPaymentMethods(amount);
    } catch (e) {
      print('Failed to load payment methods: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal memuat metode pembayaran'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return [];
    }
  }

  Future<bool> processPayment({
    required int reservationId,
    required String paymentMethod,
  }) async {
    try {
      final result = await ReservationService.processPayment(
        reservationId: reservationId,
        paymentMethod: paymentMethod,
      );

      if (result['success'] == true) {
        toastification.show(
          title: const Text('Success'),
          description: Text(result['message']),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        await loadReservations();
        return true;
      } else {
        toastification.show(
          title: const Text('Error'),
          description: Text(result['message']),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        return false;
      }
    } catch (e) {
      print('Process payment error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Terjadi kesalahan saat memproses pembayaran'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return false;
    }
  }

  Future<void> downloadReservationPDF(Reservation reservation) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          toastification.show(
            title: const Text('Error'),
            description: const Text(
              'Izin penyimpanan diperlukan untuk mengunduh PDF.',
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            autoCloseDuration: Duration(seconds: 2),
          );
          return;
        }
      }

      final pdfBytes = await ReservationService.downloadReservationPDF(
        reservation.id,
      );

      if (pdfBytes == null) {
        toastification.show(
          title: const Text('Error'),
          description: const Text('Gagal mengunduh file PDF'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
        return;
      }

      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        throw Exception("Platform tidak didukung");
      }

      final savePath = '${directory.path}/Reservasi-${reservation.id}.pdf';
      final file = File(savePath);
      await file.writeAsBytes(pdfBytes);

      toastification.show(
        title: const Text('Success'),
        description: Text('PDF disimpan di ${file.path}'),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );

      await OpenFile.open(file.path);
    } catch (e) {
      print('Download PDF error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal mengunduh file PDF'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
    }
  }

  Future<bool> sendReservationEmail(int id) async {
    try {
      final success = await ReservationService.sendReservationEmail(id);
      if (success) {
        toastification.show(
          title: const Text('Success'),
          description: const Text('Email berhasil dikirim'),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
      } else {
        toastification.show(
          title: const Text('Error'),
          description: const Text('Gagal mengirim email'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
      }
      return success;
    } catch (e) {
      print('Send email error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Terjadi kesalahan saat mengirim email'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return false;
    }
  }

  void setFilter(String filter) {
    _selectedFilter.value = filter;
  }

  void clearReservations() {
    _reservations.clear();
  }

  Future<void> refresh() async {
    await loadReservations();
  }

  double calculateEstimatedTotal(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = (duration.inMinutes / 60).ceil();
    return hours * biayaPerJam;
  }

  // Dialog untuk membuat reservasi
  void showCreateReservationDialog(BuildContext context) {
    final namaController = TextEditingController();
    final kursiController = TextEditingController();
    final catatanController = TextEditingController();

    final waktuMulai = Rx<DateTime?>(null);
    final waktuSelesai = Rx<DateTime?>(null);
    final estimatedTotal = 0.0.obs;
    final isProcessing = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Buat Reservasi Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info biaya
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue.withAlpha(51)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biaya reservasi: ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(biayaPerJam)}/jam',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nama Reservasi
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Reservasi *',
                  hintText: 'Contoh: Reservasi Ulang Tahun',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Jumlah Kursi
              TextField(
                controller: kursiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Kursi *',
                  hintText: 'Masukkan jumlah kursi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Waktu Mulai
              Obx(
                () => ListTile(
                  title: const Text('Waktu Mulai *'),
                  subtitle: Text(
                    waktuMulai.value != null
                        ? DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(waktuMulai.value!)
                        : 'Pilih waktu mulai',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: Get.context!,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        waktuMulai.value = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );

                        if (waktuSelesai.value != null) {
                          estimatedTotal.value = calculateEstimatedTotal(
                            waktuMulai.value!,
                            waktuSelesai.value!,
                          );
                        }
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Waktu Selesai
              Obx(
                () => ListTile(
                  title: const Text('Waktu Selesai *'),
                  subtitle: Text(
                    waktuSelesai.value != null
                        ? DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(waktuSelesai.value!)
                        : 'Pilih waktu selesai',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate: waktuMulai.value ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: Get.context!,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        waktuSelesai.value = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );

                        if (waktuMulai.value != null) {
                          estimatedTotal.value = calculateEstimatedTotal(
                            waktuMulai.value!,
                            waktuSelesai.value!,
                          );
                        }
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estimasi Total
              Obx(() {
                if (estimatedTotal.value > 0) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate, color: AppColors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimasi Total: ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(estimatedTotal.value)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),

              // Catatan
              TextField(
                controller: catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Tambahkan catatan khusus',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: isProcessing.value ? null : () => Get.back(),
              child: const Text('Batal'),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isProcessing.value
                  ? null
                  : () async {
                      if (namaController.text.isEmpty ||
                          kursiController.text.isEmpty ||
                          waktuMulai.value == null ||
                          waktuSelesai.value == null) {
                        toastification.show(
                          title: const Text('Error'),
                          description: const Text(
                            'Lengkapi semua field yang wajib diisi',
                          ),
                          type: ToastificationType.error,
                          style: ToastificationStyle.flatColored,
                          autoCloseDuration: Duration(seconds: 2),
                        );
                        return;
                      }

                      if (waktuSelesai.value!.isBefore(waktuMulai.value!)) {
                        toastification.show(
                          title: const Text('Error'),
                          description: const Text(
                            'Waktu selesai harus setelah waktu mulai',
                          ),
                          type: ToastificationType.error,
                          style: ToastificationStyle.flatColored,
                          autoCloseDuration: Duration(seconds: 2),
                        );
                        return;
                      }

                      isProcessing.value = true;

                      final success = await createReservation(
                        namaReservasi: namaController.text,
                        jumlahKursi: int.parse(kursiController.text),
                        waktuMulai: waktuMulai.value!,
                        waktuSelesai: waktuSelesai.value!,
                        catatan: catatanController.text.isNotEmpty
                            ? catatanController.text
                            : null,
                      );

                      isProcessing.value = false;

                      if (success) {
                        Get.back();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: isProcessing.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Dialog untuk pembayaran
  void showPaymentDialog(int reservationId, int amount) async {
    final paymentMethods = await getPaymentMethods(amount);

    if (paymentMethods.isEmpty) {
      toastification.show(
        title: const Text('Error'),
        description: const Text('Tidak ada metode pembayaran tersedia'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return;
    }

    final selectedMethod = Rx<String?>(null);

    Get.dialog(
      AlertDialog(
        title: const Text('Pilih Metode Pembayaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Harga:'),
                        Text(
                          NumberFormat.currency(
                            locale: "id_ID",
                            symbol: "Rp ",
                            decimalDigits: 0,
                          ).format(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Biaya payment akan ditambahkan sesuai metode yang dipilih',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => Column(
                  children: paymentMethods.map((method) {
                    return RadioListTile<String>(
                      title: Text(method.paymentName),
                      subtitle: Text(
                        'Fee: ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(method.totalFee)}',
                      ),
                      value: method.paymentMethod,
                      // ignore: deprecated_member_use
                      groupValue: selectedMethod.value,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        selectedMethod.value = value;
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          Obx(
            () => ElevatedButton(
              onPressed: selectedMethod.value == null
                  ? null
                  : () async {
                      final method = selectedMethod.value;
                      if (method == null) {
                        toastification.show(
                          title: const Text('Error'),
                          description: const Text(
                            'Pilih metode pembayaran terlebih dahulu',
                          ),
                          type: ToastificationType.error,
                          style: ToastificationStyle.flatColored,
                          autoCloseDuration: Duration(seconds: 2),
                        );
                        return;
                      }

                      Get.back();

                      final result = await processPayment(
                        reservationId: reservationId,
                        paymentMethod: method,
                      );

                      if (result) {
                        // Refresh to get updated reservation with payment URL
                        await refresh();

                        // Get updated reservation
                        final updatedReservation = reservations
                            .firstWhereOrNull((r) => r.id == reservationId);

                        // Open payment URL
                        if (updatedReservation?.payment?.paymentUrl != null &&
                            updatedReservation!
                                .payment!
                                .paymentUrl
                                .isNotEmpty) {
                          _openPaymentUrl(
                            updatedReservation.payment!.paymentUrl,
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Bayar Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentUrl(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        toastification.show(
          title: const Text('Error'),
          description: const Text('Tidak dapat membuka tautan pembayaran'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      toastification.show(
        title: const Text('Error'),
        description: const Text('Terjadi kesalahan saat membuka tautan'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
    }
  }
}
