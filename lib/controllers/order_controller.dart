import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/theme/app_theme.dart';

class OrderController extends GetxController {
  final _orders = <Order>[].obs;
  final _selectedFilter = 'All'.obs;
  final _isLoading = false.obs;

  List<Order> get orders => _orders;
  String get selectedFilter => _selectedFilter.value;
  bool get isLoading => _isLoading.value;

  AuthController get _authController => Get.find<AuthController>();

  List<String> get filterOptions => [
    'All',
    'Menunggu Pembayaran',
    'Antrean',
    'Proses',
    'Terkirim',
    'Dibatalkan',
  ];

  List<Order> get filteredOrders {
    if (_selectedFilter.value == 'All') {
      return _orders;
    }
    return _orders
        .where((order) => order.status.label == _selectedFilter.value)
        .toList();
  }

  Future<void> loadOrders() async {
    if (!_authController.isLoggedIn) {
      _orders.clear();
      return;
    }

    _isLoading.value = true;
    try {
      final orders = await ApiService.fetchOrders();
      _orders.value = orders;
    } catch (e) {
      print('Failed to load orders: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat pesanan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    _selectedFilter.value = filter;
  }

  Future<bool> sendInvoiceEmail(String orderId) async {
    try {
      final success = await ApiService.sendInvoiceEmail(orderId);
      if (success) {
        Get.snackbar(
          'Berhasil',
          'Invoice berhasil dikirim ke email',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Gagal mengirim invoice',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
      }
      return success;
    } catch (e) {
      print('Send invoice error: $e');
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

  Future<void> downloadInvoicePdf(Order order) async {
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

      final pdfBytes = await ApiService.getInvoicePdfBytes(order.id.toString());

      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory(
          '/storage/emulated/0/Download',
        ); // ke folder Downloads
      } else if (Platform.isIOS) {
        directory =
            await getApplicationDocumentsDirectory(); // iOS pakai default doc dir
      } else {
        throw Exception("Platform tidak didukung");
      }

      final savePath = '${directory.path}/Invoice-${order.nomorInvoice}.pdf';
      final file = File(savePath);
      await file.writeAsBytes(pdfBytes);

      Get.snackbar(
        'Berhasil',
        'Invoice disimpan: ${file.path}',
        backgroundColor: AppColors.green,
        colorText: AppColors.white,
      );

      await OpenFile.open(file.path);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan file: $e');
    }
  }

  void clearOrders() {
    _orders.clear();
  }

  // Force refresh
  Future<void> refresh() async {
    await loadOrders();
  }

  // Add new order to list (dipanggil setelah create order berhasil)
  void addOrder(Order order) {
    _orders.insert(0, order); // Add to beginning of list
  }
}
