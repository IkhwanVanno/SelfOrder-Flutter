import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:toastification/toastification.dart';

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
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal memuat data pesanan'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
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
        toastification.show(
          title: const Text('Success'),
          description: const Text('Invoice berhasil dikirim via email'),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
      } else {
        toastification.show(
          title: const Text('Error'),
          description: const Text('Gagal mengirim invoice via email'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: Duration(seconds: 2),
        );
      }
      return success;
    } catch (e) {
      print('Send invoice error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal mengirim invoice via email'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
      return false;
    }
  }

  Future<void> downloadInvoicePdf(Order order) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          toastification.show(
            title: const Text('Permission Denied'),
            description: const Text(
              'Izin penyimpanan diperlukan untuk mengunduh invoice.',
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            autoCloseDuration: Duration(seconds: 2),
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

      toastification.show(
        title: const Text('Success'),
        description: Text('Invoice disimpan di ${file.path}'),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );

      await OpenFile.open(file.path);
    } catch (e) {
      print('Download invoice error: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal mengunduh invoice PDF'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
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
