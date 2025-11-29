import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/payment_model.dart';

class TicketDetailScreen extends StatelessWidget {
  final Payment payment;

  const TicketDetailScreen({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral01,
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur berbagi belum tersedia'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // TODO: Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur download belum tersedia'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Ticket Card
            _buildTicketCard(context)
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 32),
            // Additional Info
            _buildAdditionalInfo()
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary04, AppColors.primary06],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'PEMBAYARAN BERHASIL',
                  style: AppTypography.heading6Semibold.copyWith(
                    color: AppColors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SPP ${payment.month}',
                  style: AppTypography.heading4Semibold.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          // QR Code Section
          Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.neutral03,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payment.ticketCode,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: AppColors.white,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kode QR Tiket',
                    style: AppTypography.paraSmallMedium.copyWith(
                      color: AppColors.neutral08,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Barcode Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral01,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: payment.ticketCode,
                    width: double.infinity,
                    height: 80,
                    drawText: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    payment.ticketCode,
                    style: AppTypography.paraMediumMedium.copyWith(
                      color: AppColors.dark,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Divider with circles
          _buildDividerWithCircles(),
          // Payment Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailRow('Nama Siswa', 'Muhammad Siswa'),
                _buildDetailRow('NIS', '2024001'),
                _buildDetailRow('Kelas', 'XII IPA 1'),
                const Divider(height: 32),
                _buildDetailRow('Nominal Pembayaran',
                    'Rp ${payment.amount.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}'),
                _buildDetailRow('Metode Pembayaran', payment.paymentMethod),
                _buildDetailRow('Tanggal Pembayaran', payment.paymentDate),
                _buildDetailRow('Tahun Ajaran', payment.academicYear),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerWithCircles() {
    return Stack(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.neutral03,
                AppColors.neutral03.withOpacity(0.1),
                AppColors.neutral03,
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.neutral01,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.neutral01,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.paraMediumRegular.copyWith(
              color: AppColors.neutral08,
            ),
          ),
          Text(
            value,
            style: AppTypography.paraMediumMedium.copyWith(
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary04.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary04.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary04,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Simpan tiket ini sebagai bukti pembayaran SPP Anda. Tunjukkan QR Code atau Barcode saat diperlukan.',
              style: AppTypography.paraSmallRegular.copyWith(
                color: AppColors.dark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

