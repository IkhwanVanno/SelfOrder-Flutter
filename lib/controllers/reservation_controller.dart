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
      Get.snackbar(
        'Error',
        'Gagal memuat reservasi',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
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
      Get.snackbar(
        'Error',
        'Gagal memuat detail reservasi',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
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
        Get.snackbar(
          'Berhasil',
          result['message'],
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
        await loadReservations();
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          result['message'],
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
        return false;
      }
    } catch (e) {
      print('Create reservation error: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
      return false;
    }
  }

  Future<bool> cancelReservation(int id) async {
    try {
      final result = await ReservationService.cancelReservation(id);

      if (result['success'] == true) {
        Get.snackbar(
          'Berhasil',
          result['message'],
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
        await loadReservations();
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          result['message'],
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
        return false;
      }
    } catch (e) {
      print('Cancel reservation error: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
      return false;
    }
  }

  Future<List<ReservationPaymentMethod>> getPaymentMethods(int amount) async {
    try {
      return await ReservationService.fetchPaymentMethods(amount);
    } catch (e) {
      print('Failed to load payment methods: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat metode pembayaran',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
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
        Get.snackbar(
          'Berhasil',
          result['message'],
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
        await loadReservations();
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          result['message'],
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
        return false;
      }
    } catch (e) {
      print('Process payment error: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
      return false;
    }
  }

  Future<void> downloadReservationPDF(Reservation reservation) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Izin Ditolak',
            'Tidak bisa menyimpan file tanpa izin',
            backgroundColor: AppColors.red,
            colorText: AppColors.white,
          );
          return;
        }
      }

      final pdfBytes = await ReservationService.downloadReservationPDF(
        reservation.id,
      );

      if (pdfBytes == null) {
        Get.snackbar(
          'Error',
          'Gagal mengunduh PDF',
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
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

      Get.snackbar(
        'Berhasil',
        'Tanda terima disimpan: ${file.path}',
        backgroundColor: AppColors.green,
        colorText: AppColors.white,
        duration: const Duration(seconds: 3),
      );

      await OpenFile.open(file.path);
    } catch (e) {
      print('Download PDF error: $e');
      Get.snackbar(
        'Error',
        'Gagal menyimpan file: $e',
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    }
  }

  Future<bool> sendReservationEmail(int id) async {
    try {
      final success = await ReservationService.sendReservationEmail(id);
      if (success) {
        Get.snackbar(
          'Berhasil',
          'Tanda terima berhasil dikirim ke email',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Gagal mengirim email',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
      }
      return success;
    } catch (e) {
      print('Send email error: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
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
  void showCreateReservationDialog() {
    final namaController = TextEditingController();
    final kursiController = TextEditingController();
    final catatanController = TextEditingController();

    DateTime? waktuMulai;
    DateTime? waktuSelesai;

    final estimatedTotal = 0.0.obs;

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
              StatefulBuilder(
                builder: (context, setState) {
                  return ListTile(
                    title: const Text('Waktu Mulai *'),
                    subtitle: Text(
                      waktuMulai != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(waktuMulai!)
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
                          setState(() {
                            waktuMulai = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                          if (waktuSelesai != null) {
                            estimatedTotal.value = calculateEstimatedTotal(
                              waktuMulai!,
                              waktuSelesai!,
                            );
                          }
                        }
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.grey),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Waktu Selesai
              StatefulBuilder(
                builder: (context, setState) {
                  return ListTile(
                    title: const Text('Waktu Selesai *'),
                    subtitle: Text(
                      waktuSelesai != null
                          ? DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(waktuSelesai!)
                          : 'Pilih waktu selesai',
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
                          setState(() {
                            waktuSelesai = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                          if (waktuMulai != null) {
                            estimatedTotal.value = calculateEstimatedTotal(
                              waktuMulai!,
                              waktuSelesai!,
                            );
                          }
                        }
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.grey),
                    ),
                  );
                },
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
          TextButton(
            onPressed: () {
              namaController.dispose();
              kursiController.dispose();
              catatanController.dispose();
              Get.back();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.isEmpty ||
                  kursiController.text.isEmpty ||
                  waktuMulai == null ||
                  waktuSelesai == null) {
                Get.snackbar(
                  'Error',
                  'Mohon lengkapi semua field yang wajib diisi',
                  backgroundColor: AppColors.red,
                  colorText: AppColors.white,
                );
                return;
              }

              if (waktuSelesai!.isBefore(waktuMulai!)) {
                Get.snackbar(
                  'Error',
                  'Waktu selesai harus setelah waktu mulai',
                  backgroundColor: AppColors.red,
                  colorText: AppColors.white,
                );
                return;
              }

              final success = await createReservation(
                namaReservasi: namaController.text,
                jumlahKursi: int.parse(kursiController.text),
                waktuMulai: waktuMulai!,
                waktuSelesai: waktuSelesai!,
                catatan: catatanController.text,
              );

              if (success) {
                namaController.dispose();
                kursiController.dispose();
                catatanController.dispose();
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog untuk pembayaran
  void showPaymentDialog(int reservationId, int amount) async {
    final paymentMethods = await getPaymentMethods(amount);

    if (paymentMethods.isEmpty) {
      Get.snackbar(
        'Error',
        'Tidak ada metode pembayaran tersedia',
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
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
                        Get.snackbar(
                          'Error',
                          'Pilih metode pembayaran terlebih dahulu',
                          backgroundColor: AppColors.red,
                          colorText: AppColors.white,
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
        Get.snackbar(
          'Error',
          'Tidak dapat membuka halaman pembayaran',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    }
  }
}
