import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/reservation_controller.dart';
import 'package:selforder/models/payment_reservation_model.dart';
import 'package:selforder/models/reservation_model.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservationPage extends StatelessWidget {
  const ReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.find with lazy initialization
    final authController = Get.find<AuthController>();
    final reservationController = Get.find<ReservationController>();
    
    return Scaffold(
      body: Obx(() {
        if (!authController.isLoggedIn) {
          return _buildNotAuthenticatedView();
        }

        if (reservationController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => reservationController.refresh(),
          child: Column(
            children: [
              _buildFilterSection(reservationController),
              Expanded(
                child: reservationController.filteredReservations.isEmpty
                    ? _buildEmptyReservationView(reservationController)
                    : _buildReservationList(reservationController),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (!authController.isLoggedIn) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () => reservationController.showCreateReservationDialog(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Buat Reservasi'),
        );
      }),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'Silahkan masuk untuk melihat reservasi anda',
            style: TextStyle(fontSize: 16, color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.LOGIN),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ReservationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Status:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.filterOptions.map((filter) {
                  final isSelected = controller.selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.setFilter(filter);
                        }
                      },
                      selectedColor: AppColors.blue.withAlpha(51),
                      checkmarkColor: AppColors.blue,
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.blue : AppColors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReservationView(ReservationController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: AppColors.grey),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.selectedFilter == 'Semua'
                  ? 'Belum ada reservasi'
                  : 'Tidak ada reservasi ${controller.selectedFilter}',
              style: TextStyle(fontSize: 16, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reservasi Anda akan ditampilkan di sini',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => controller.refresh(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(ReservationController controller) {
    return Obx(
      () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredReservations.length,
        itemBuilder: (context, index) {
          final reservation = controller.filteredReservations[index];
          return _buildReservationCard(reservation, controller);
        },
      ),
    );
  }

  Widget _buildReservationCard(
    Reservation reservation,
    ReservationController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReservationDetails(reservation, controller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reservation.namaReservasi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: reservation.status.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: reservation.status.color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reservation.status.icon,
                          size: 14,
                          color: reservation.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation.status.label,
                          style: TextStyle(
                            color: reservation.status.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Icon(Icons.event_seat, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.jumlahKursi} Kursi',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.durasiJam} Jam',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reservation.formattedWaktuMulai,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.event_available, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reservation.formattedWaktuSelesai,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  Text(
                    reservation.formattedTotal,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Buttons
              _buildActionButtons(reservation, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    Reservation reservation,
    ReservationController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showReservationDetails(reservation, controller),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Detail'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),

        // Tombol Bayar untuk status Disetujui
        if (reservation.canBePaid) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.showPaymentDialog(
                reservation.id,
                reservation.totalHarga.toInt(),
              ),
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('Bayar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],

        // Tombol Lanjutkan Pembayaran
        if (reservation.hasPendingPayment) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openPaymentUrl(reservation.payment!.paymentUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Bayar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],

        // Tombol untuk reservasi selesai
        if (reservation.isCompleted) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.downloadReservationPDF(reservation),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],

        // Tombol Batalkan
        if (reservation.canBeCancelled) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _confirmCancelReservation(reservation, controller),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Batal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showReservationDetails(
    Reservation reservation,
    ReservationController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Detail Reservasi #${reservation.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nama', reservation.namaReservasi),
              _buildDetailRow('Jumlah Kursi', '${reservation.jumlahKursi}'),
              _buildDetailRow('Total Harga', reservation.formattedTotal),
              _buildDetailRow('Durasi', '${reservation.durasiJam} Jam'),
              _buildDetailRow('Waktu Mulai', reservation.formattedWaktuMulai),
              _buildDetailRow(
                'Waktu Selesai',
                reservation.formattedWaktuSelesai,
              ),
              _buildDetailRow('Status', reservation.status.label),
              _buildDetailRow('Dibuat', reservation.formattedCreated),

              if (reservation.catatan.isNotEmpty) ...[
                const Divider(height: 20),
                const Text(
                  'Catatan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(reservation.catatan, style: const TextStyle(fontSize: 13)),
              ],

              if (reservation.responsAdmin.isNotEmpty) ...[
                const Divider(height: 20),
                const Text(
                  'Respons Admin:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  reservation.responsAdmin,
                  style: const TextStyle(fontSize: 13),
                ),
              ],

              if (reservation.payment != null) ...[
                const Divider(height: 20),
                const Text(
                  'Informasi Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Metode',
                  reservation.payment!.metodePembayaran,
                ),
                _buildDetailRow('Status', reservation.payment!.status.label),
                _buildDetailRow('Reference', reservation.payment!.reference),
                if (reservation.payment!.expiryTime != null)
                  _buildDetailRow(
                    'Kadaluarsa',
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(reservation.payment!.expiryTime!),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          if (reservation.isCompleted)
            TextButton.icon(
              onPressed: () {
                Get.back();
                controller.sendReservationEmail(reservation.id);
              },
              icon: const Icon(Icons.email),
              label: const Text('Kirim Email'),
            ),
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelReservation(
    Reservation reservation,
    ReservationController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan reservasi ini?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.cancelReservation(reservation.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Ya, Batalkan'),
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
