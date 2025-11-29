import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  int _totalPaid = 0;

  List<Map<String, dynamic>> get _successPayments =>
      _payments.where((p) => p['status'] == 'success').toList();

  List<Map<String, dynamic>> get _failedPayments =>
      _payments.where((p) => p['status'] == 'failed').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Fetching payment history...');
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final paymentsData = data['data']['payments'] as List;
          final summary = data['data']['summary'];

          setState(() {
            _payments = paymentsData.map((payment) {
              return {
                'id': payment['id'],
                'type': payment['type'],
                'month': payment['month'],
                'amount': payment['amount'],
                'date': DateTime.parse(payment['date']),
                'status': payment['status'],
                'method': payment['method'],
                'fine': payment['fine'] ?? 0,
                'is_installment': payment['is_installment'] ?? false,
              };
            }).toList();
            _totalPaid = summary['total_paid'];
            _isLoading = false;
          });
          print('✅ Loaded ${_payments.length} payments');
        }
      } else {
        throw Exception('Failed to load payment history');
      }
    } catch (e) {
      print('❌ Error loading payment history: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF16A085),
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF16A085),
                onRefresh: _loadPaymentHistory,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildSummaryCard(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllTab(),
                          _buildSuccessTab(),
                          _buildFailedTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16A085),
            Color(0xFF1ABC9C),
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Riwayat Pembayaran',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_list,
              size: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main Amount Card - Smaller Version
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF16A085),
                  Color(0xFF1ABC9C),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A085).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Total Pembayaran Tahun Ini',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Amount
                      Text(
                        'Rp ${_formatCurrency(_totalPaid)}',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_successPayments.length}',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lunas',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Stats Row - Compact Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Berhasil',
                  value: '${_successPayments.length}',
                  color: const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.cancel_rounded,
                  label: 'Gagal',
                  value: '${_failedPayments.length}',
                  color: const Color(0xFFE74C3C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total',
                  value: '${_payments.length}',
                  color: const Color(0xFF3498DB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: _tabController.index == 0
                ? [const Color(0xFF16A085), const Color(0xFF1ABC9C)] // Semua - Teal
                : _tabController.index == 1
                    ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)] // Berhasil - Hijau
                    : [const Color(0xFFE74C3C), const Color(0xFFC0392B)], // Gagal - Merah
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontFamily: 'Lato',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Lato',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        onTap: (index) {
          setState(() {}); // Rebuild untuk update warna
        },
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Berhasil'),
          Tab(text: 'Gagal'),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return _buildPaymentList(_payments);
  }

  Widget _buildSuccessTab() {
    return _buildPaymentList(_successPayments);
  }

  Widget _buildFailedTab() {
    return _buildPaymentList(_failedPayments);
  }

  Widget _buildPaymentList(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Group by month
    final groupedPayments = <String, List<Map<String, dynamic>>>{};
    for (var payment in payments) {
      final date = payment['date'] as DateTime;
      final monthYear = DateFormat('MMMM yyyy').format(date);
      groupedPayments.putIfAbsent(monthYear, () => []).add(payment);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      itemCount: groupedPayments.length,
      itemBuilder: (context, index) {
        final monthYear = groupedPayments.keys.elementAt(index);
        final monthPayments = groupedPayments[monthYear]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                monthYear,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            ...monthPayments.map((payment) => _buildPaymentCard(payment)),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final isSuccess = payment['status'] == 'success';
    final isInstallment = payment['is_installment'] == true;
    final statusColor = isSuccess ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    final statusIcon = isSuccess ? Icons.check_circle : Icons.cancel;
    final statusLabel = isSuccess ? 'Berhasil' : 'Gagal';
    final date = payment['date'] as DateTime;

    // Icon berdasarkan tipe
    IconData typeIcon;
    Color typeColor;
    if (isInstallment) {
      typeIcon = Icons.payments_outlined;
      typeColor = const Color(0xFF3498DB);
    } else {
      switch (payment['type']) {
        case 'SPP':
          typeIcon = Icons.school;
          typeColor = const Color(0xFF3498DB);
          break;
        case 'Ujian':
          typeIcon = Icons.assignment;
          typeColor = const Color(0xFF9B59B6);
          break;
        default:
          typeIcon = Icons.receipt;
          typeColor = const Color(0xFF95A5A6);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentDetail(payment),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Type Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isInstallment ? 'Cicilan SPP' : payment['type'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 10, color: statusColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment['month'] as String,
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(date),
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${_formatCurrency((payment['amount'] as int) + (payment['fine'] as int))}',
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSuccess ? const Color(0xFF16A085) : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment['method'] as String,
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (payment['fine'] > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39C12).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          size: 16,
                          color: Color(0xFFF39C12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Termasuk denda: Rp ${_formatCurrency(payment['fine'] as int)}',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF39C12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetail(Map<String, dynamic> payment) {
    final isSuccess = payment['status'] == 'success';
    final date = payment['date'] as DateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Detail Pembayaran',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('ID Transaksi', payment['id'] as String),
            _buildDetailRow('Tipe', payment['type'] as String),
            _buildDetailRow('Bulan', payment['month'] as String),
            _buildDetailRow('Tanggal', DateFormat('dd MMMM yyyy, HH:mm').format(date)),
            _buildDetailRow('Metode', payment['method'] as String),
            _buildDetailRow('Tagihan', 'Rp ${_formatCurrency(payment['amount'] as int)}'),
            if (payment['fine'] > 0)
              _buildDetailRow('Denda', 'Rp ${_formatCurrency(payment['fine'] as int)}'),
            _buildDetailRow(
              'Total',
              'Rp ${_formatCurrency((payment['amount'] as int) + (payment['fine'] as int))}',
              isTotal: true,
            ),
            _buildDetailRow(
              'Status',
              isSuccess ? 'Berhasil' : 'Gagal',
              valueColor: isSuccess ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 24),
            if (isSuccess)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur download struk akan segera hadir'),
                        backgroundColor: Color(0xFF16A085),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A085),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text(
                    'Download Struk',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? const Color(0xFF000000) : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isTotal ? const Color(0xFF16A085) : const Color(0xFF000000)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

