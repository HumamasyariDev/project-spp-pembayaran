import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final paymentService = PaymentService();
      final payments = await paymentService.getPaymentHistory();
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat riwayat pembayaran'),
            backgroundColor: AppColors.destructive02,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: AppColors.primary04,
      child: _isLoading
          ? _buildLoadingState()
          : _payments.isEmpty
              ? _buildEmptyState()
              : _buildTicketsList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary04),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 100,
              color: AppColors.neutral05,
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Tiket',
              style: AppTypography.heading4Semibold.copyWith(
                color: AppColors.dark,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            Text(
              'Tiket pembayaran SPP Anda akan muncul di sini setelah melakukan pembayaran',
              style: AppTypography.paraMediumRegular.copyWith(
                color: AppColors.neutral08,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _payments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildTicketCard(_payments[index])
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildTicketCard(Payment payment) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailScreen(payment: payment),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary04.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        color: AppColors.primary04,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPP ${payment.month}',
                            style: AppTypography.heading6Semibold.copyWith(
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tahun Ajaran ${payment.academicYear}',
                            style: AppTypography.paraSmallRegular.copyWith(
                              color: AppColors.neutral08,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary04.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Lunas',
                        style: AppTypography.paraXSmallMedium.copyWith(
                          color: AppColors.primary04,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider
                Container(
                  height: 1,
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
                const SizedBox(height: 16),
                // Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Nominal',
                        'Rp ${payment.amount.toStringAsFixed(0).replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.',
                            )}',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Tanggal Bayar',
                        payment.paymentDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // View ticket button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TicketDetailScreen(payment: payment),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2, size: 20),
                    label: const Text('Lihat Tiket'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.paraSmallRegular.copyWith(
            color: AppColors.neutral07,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.paraMediumMedium.copyWith(
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }
}

