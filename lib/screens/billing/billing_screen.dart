import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/midtrans_service.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../utils/date_formatter.dart';
import '../payment/midtrans_webview_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Map<String, dynamic>> _billings = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBillingData();
  }

  Future<void> _loadBillingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Fetching billing data...');
      final result = await DashboardService.getStats();
      print('📦 Result: ${result['success']}');
      
      if (result['success'] == true && result['data'] != null) {
        final allBills = result['data']['unpaid_bills']['bills'] as List;
        print('📊 Total bills from API: ${allBills.length}');
        
        setState(() {
          _billings = allBills.map((bill) {
            try {
              // Format due date with error handling
              String formattedDueDate = '-';
              try {
                formattedDueDate = DateFormatter.formatStringToIndonesian(bill['jatuh_tempo']);
              } catch (e) {
                print('⚠️ Error formatting date: ${bill['jatuh_tempo']} - $e');
                formattedDueDate = bill['jatuh_tempo'] ?? '-';
              }
              
              // Format paid date to Indonesian with time WIB
              String formattedPaidDate = '-';
              if (bill['tanggal_bayar'] != null) {
                try {
                  formattedPaidDate = DateFormatter.formatStringToIndonesianWithTime(bill['tanggal_bayar']);
                } catch (e) {
                  print('⚠️ Error formatting paid date: ${bill['tanggal_bayar']} - $e');
                  formattedPaidDate = bill['tanggal_bayar'] ?? '-';
                }
              }
              
              return {
                'id': bill['id'],
                'month': bill['bulan'], // Hanya bulan saja, tanpa tahun (avoid double 2025)
                'year': bill['tahun'], // Simpan tahun terpisah
                // For paid bills: show total amount (jumlah)
                // For unpaid/partial: show remaining amount
                'amount': (bill['status'] == 'paid' || bill['status'] == 'lunas') 
                    ? bill['jumlah'] 
                    : (bill['remaining'] ?? bill['jumlah']),
                'total_amount': bill['jumlah'], // Store total amount separately
                'terbayar': bill['terbayar'] ?? 0, // Amount already paid
                'remaining': bill['remaining'] ?? bill['jumlah'], // Remaining amount
                'dueDate': formattedDueDate,
                'status': bill['status'],
                'fine': bill['denda'] ?? 0,
                'paidDate': formattedPaidDate,
                'paymentMethod': bill['metode_bayar'],
              };
            } catch (e) {
              print('❌ Error mapping bill ${bill['id']}: $e');
              rethrow;
            }
          }).toList();
          print('✅ Mapped ${_billings.length} bills successfully');
          _isLoading = false;
        });
      } else {
        print('❌ API returned success=false or data=null');
        print('   Response: $result');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading billing data: $e');
      print('   Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _unpaidCount => _billings.where((b) => b['status'] == 'unpaid').length;
  int get _paidCount => _billings.where((b) => b['status'] == 'paid').length;
  int get _partialCount => _billings.where((b) => b['status'] == 'partial').length;
  int get _totalUnpaid => _billings
      .where((b) => b['status'] == 'unpaid')
      .fold(0, (sum, b) => sum + (b['amount'] as int) + (b['fine'] as int));
  int get _totalPartial => _billings
      .where((b) => b['status'] == 'partial')
      .fold(0, (sum, b) => sum + (b['remaining'] as int));

  List<Map<String, dynamic>> get _filteredBillings {
    print('🔍 Filter: $_selectedFilter, Total billings: ${_billings.length}');
    if (_selectedFilter == 'all') {
      print('   Returning all ${_billings.length} billings');
      return _billings;
    }
    final filtered = _billings.where((b) => b['status'] == _selectedFilter).toList();
    print('   Filtered result: ${filtered.length} billings');
    return filtered;
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
        backgroundColor: Colors.white,
        body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF16A085),
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF16A085),
                onRefresh: _loadBillingData,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          const SizedBox(height: 20),
                          _buildSummaryCard(),
                          const SizedBox(height: 24),
                          _buildFilterChips(),
                          const SizedBox(height: 20),
                          ..._filteredBillings.map((billing) => _buildBillingCard(billing)),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF2B2849),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Tagihan SPP',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2849),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalOutstanding = _totalUnpaid + _totalPartial;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A085).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Tagihan Tertunggak',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(totalOutstanding)}',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.warning_amber_rounded,
                    label: 'Belum Bayar',
                    count: _unpaidCount,
                    amount: _totalUnpaid,
                    color: const Color(0xFFFFC107),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.schedule,
                    label: 'Cicilan',
                    count: _partialCount,
                    amount: _totalPartial,
                    color: const Color(0xFF3498DB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required int count,
    required int amount,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count $label',
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              'Rp ${_formatCurrency(amount)}',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              label: 'Semua',
              value: 'all',
              count: _billings.length,
              color: const Color(0xFF16A085),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFilterChip(
              label: 'Belum',
              value: 'unpaid',
              count: _unpaidCount,
              color: const Color(0xFFFFC107),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFilterChip(
              label: 'Cicilan',
              value: 'partial',
              count: _partialCount,
              color: const Color(0xFF3498DB),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFilterChip(
              label: 'Lunas',
              value: 'paid',
              count: _paidCount,
              color: const Color(0xFF2ECC71),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
    required Color color,
  }) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF2B2849),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingCard(Map<String, dynamic> billing) {
    final isPaid = billing['status'] == 'paid';
    final isPartial = billing['status'] == 'partial';
    final statusColor = isPaid ? const Color(0xFF2ECC71) : 
                       isPartial ? const Color(0xFF3498DB) : 
                       const Color(0xFFFFC107);
    final totalAmount = (billing['amount'] as int) + (billing['fine'] as int);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid ? statusColor.withOpacity(0.2) : const Color(0xFFF0F0F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPaid 
                ? statusColor.withOpacity(0.08) 
                : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPaid ? null : () => _handlePayment(billing),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Month + Status Badge
                Row(
                  children: [
                    // Icon Calendar/Check
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.2),
                            statusColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle_rounded : 
                        isPartial ? Icons.schedule_rounded :
                        Icons.event_note_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Month & Year
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${billing['month']} ${billing['year']}',
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B2849),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  billing['dueDate'],
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor,
                            statusColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isPaid ? 'LUNAS' : isPartial ? 'CICILAN' : 'BELUM',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 18),
                
                // Amount Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF8F9FA),
                        const Color(0xFFFFFFFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE8EAED),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // SPP Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A085).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 16,
                                  color: Color(0xFF16A085),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isPaid ? 'Total SPP' : isPartial ? 'Sisa Cicilan' : 'Tagihan SPP',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Rp ${_formatCurrency(billing['amount'] as int)}',
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B2849),
                            ),
                          ),
                        ],
                      ),
                      
                      // Payment Progress (for partial payments)
                      if (billing['terbayar'] > 0 && !isPaid) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3498DB).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    size: 16,
                                    color: Color(0xFF3498DB),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sudah Dibayar',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${_formatCurrency(billing['terbayar'] as int)}',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar with percentage
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (billing['terbayar'] as int) / (billing['total_amount'] as int),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${((billing['terbayar'] as int) / (billing['total_amount'] as int) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ],
                        ),
                        // Button to view installment history
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showInstallmentHistory(billing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3498DB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF3498DB).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: Color(0xFF3498DB),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Lihat Riwayat Cicilan',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3498DB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // Fine (if exists)
                      if (billing['fine'] > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE74C3C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    size: 16,
                                    color: Color(0xFFE74C3C),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Denda Keterlambatan',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${_formatCurrency(billing['fine'] as int)}',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE74C3C),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2B2849),
                              ),
                            ),
                            Text(
                              'Rp ${_formatCurrency(totalAmount)}',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A085),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Paid Date Info
                if (isPaid && billing['paidDate'] != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dibayar pada ${billing['paidDate']}',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (billing['paymentMethod'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              billing['paymentMethod'],
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                
                // Payment Button
                if (!isPaid) ...[
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF16A085),
                          Color(0xFF1ABC9C),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A085).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _handlePayment(billing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'Bayar Sekarang',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• Rp ${_formatCurrency(totalAmount)}',
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _updatePaymentStatus(
    int tagihanId, 
    String orderId, 
    String? paymentType, {
    bool isInstallment = false,
    int? amount,
  }) async {
    try {
      print('🔔 _updatePaymentStatus called');
      print('   tagihan_id: $tagihanId');
      print('   order_id: $orderId');
      print('   payment_type: $paymentType');
      print('   isInstallment: $isInstallment');
      print('   amount: $amount');
      
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Token not found');
        throw Exception('Token not found');
      }
      print('✅ Token found: ${token.substring(0, 20)}...');

      final url = '${ApiConfig.baseUrl}/midtrans/update-payment-status';
      print('📡 Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tagihan_id': tagihanId,
          'order_id': orderId,
          'payment_type': paymentType ?? 'Midtrans',
          'is_installment': isInstallment,
          'amount': amount, // Send amount directly for installment
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Payment status updated successfully');
      } else {
        print('❌ Failed to update payment status: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Error updating payment status: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  Future<void> _handlePayment(Map<String, dynamic> billing) async {
    // Show payment options dialog
    _showPaymentOptionsDialog(billing);
  }

  void _showPaymentOptionsDialog(Map<String, dynamic> billing) {
    final totalAmount = billing['amount'] as int;
    final totalWithFine = totalAmount + (billing['fine'] as int);
    final isPartial = billing['status'] == 'partial';
    final terbayar = billing['terbayar'] as int;
    final totalTagihan = billing['total_amount'] as int;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B2849),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SPP ${billing['month']} ${billing['year']}',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              
              // Payment info
              if (isPartial) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF3498DB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sudah dibayar: Rp ${_formatCurrency(terbayar)} dari Rp ${_formatCurrency(totalTagihan)}',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3498DB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Option 1: Full Payment
              _buildPaymentOption(
                icon: Icons.payment_rounded,
                title: 'Bayar Lunas',
                subtitle: 'Bayar seluruh sisa tagihan sekaligus',
                amount: totalWithFine,
                color: const Color(0xFF16A085),
                onTap: () {
                  Navigator.pop(context);
                  _processPayment(billing, totalWithFine, false);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Option 2: Installment
              _buildPaymentOption(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Bayar Cicilan',
                subtitle: 'Bayar sebagian sesuai kemampuan',
                amount: null,
                color: const Color(0xFF3498DB),
                onTap: () {
                  Navigator.pop(context);
                  _showInstallmentDialog(billing);
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int? amount,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2849),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (amount != null)
              Text(
                'Rp ${_formatCurrency(amount)}',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showInstallmentDialog(Map<String, dynamic> billing) {
    final maxAmount = (billing['amount'] as int) + (billing['fine'] as int);
    final TextEditingController amountController = TextEditingController();
    String displayAmount = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Masukkan Nominal Cicilan',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2B2849),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SPP ${billing['month']} ${billing['year']}',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sisa tagihan: Rp ${_formatCurrency(maxAmount)}',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A085),
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
                      ),
                      child: const Text(
                        'Rp',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B2849),
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() => displayAmount = '');
                            return;
                          }
                          final number = int.tryParse(value) ?? 0;
                          setState(() => displayAmount = _formatCurrency(number));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (displayAmount.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Rp $displayAmount',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A085),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [50000, 100000, 200000, 250000].map((amount) {
                  return InkWell(
                    onTap: () {
                      amountController.text = amount.toString();
                      setState(() => displayAmount = _formatCurrency(amount));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A085).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF16A085).withOpacity(0.3)),
                      ),
                      child: Text(
                        'Rp ${_formatCurrency(amount)}',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A085),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text) ?? 0;
                if (amount < 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Minimal pembayaran Rp 10.000'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (amount > maxAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maksimal pembayaran Rp ${_formatCurrency(maxAmount)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _processPayment(billing, amount, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A085),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Bayar',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> billing, int amount, bool isInstallment) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
              ),
              SizedBox(height: 16),
              Text(
                'Memproses pembayaran...',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('User not found');

      Map<String, dynamic> result;
      String orderId;
      
      if (isInstallment) {
        // Use installment endpoint from backend
        result = await _createInstallmentPayment(billing['id'], amount);
        // Get order_id from backend response
        orderId = result['order_id'] ?? 'CICILAN-${billing['id']}-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Use regular Midtrans payment
        orderId = MidtransService.generateOrderId();
        result = await MidtransService.createSnapToken(
          orderId: orderId,
          grossAmount: amount,
          customerDetails: {
            'first_name': user.name,
            'email': user.email,
            'phone': user.telepon ?? '-',
          },
          itemDetails: [
            {
              'id': 'spp-${billing['id']}',
              'price': billing['amount'],
              'quantity': 1,
              'name': 'SPP ${billing['month']} ${billing['year']}',
            },
            if (billing['fine'] > 0)
              {
                'id': 'fine-${billing['id']}',
                'price': billing['fine'],
                'quantity': 1,
                'name': 'Denda Keterlambatan',
              },
          ],
        );
      }

      Navigator.pop(context);

      if (result['success']) {
        final snapToken = result['token'];
        final redirectUrl = result['redirect_url'];
        
        print('🚀 Opening WebView with snapToken and redirectUrl...');
        print('   isInstallment: $isInstallment');
        print('   amount: $amount');
        print('   orderId: $orderId');
        
        final paymentResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MidtransWebViewScreen(
              snapToken: snapToken,
              redirectUrl: redirectUrl,
            ),
          ),
        );

        print('🔙 WebView closed, paymentResult: $paymentResult');

        if (paymentResult != null && paymentResult['status'] == 'success') {
          print('✅ Payment SUCCESS detected!');
          print('   Calling _updatePaymentStatus...');
          // Update payment status in backend - pass amount for installment
          await _updatePaymentStatus(
            billing['id'], 
            orderId, 
            paymentResult['payment_type'],
            isInstallment: isInstallment,
            amount: isInstallment ? amount : null,
          );
          print('   Showing success dialog...');
          _showSuccessDialog(isInstallment: isInstallment, amount: amount);
          print('   Reloading billing data...');
          await _loadBillingData();
        } else if (paymentResult != null && paymentResult['status'] == 'cancelled') {
          print('❌ Payment CANCELLED');
          _showErrorDialog('Pembayaran dibatalkan');
        } else {
          print('⚠️ paymentResult is NULL or unknown status');
          print('   paymentResult: $paymentResult');
        }
      } else {
        _showErrorDialog(result['message'] ?? 'Gagal membuat transaksi');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog(e.toString());
    }
  }

  Future<Map<String, dynamic>> _createInstallmentPayment(int tagihanId, int amount) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/mobile/pay-midtrans'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tagihan_id': tagihanId,
          'amount': amount,
        }),
      );

      print('📡 Installment API Response: ${response.statusCode}');
      print('   Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'token': responseData['data']['snap_token'],
          'redirect_url': responseData['data']['redirect_url'],
          'order_id': responseData['data']['order_id'], // Get order_id from backend
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membuat pembayaran cicilan',
        };
      }
    } catch (e) {
      print('❌ Error creating installment payment: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  void _showSuccessDialog({bool isInstallment = false, int? amount}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isInstallment ? const Color(0xFF3498DB) : const Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              isInstallment ? 'Cicilan Berhasil!' : 'Pembayaran Berhasil!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B2849),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isInstallment 
                ? 'Pembayaran cicilan sebesar Rp ${_formatCurrency(amount ?? 0)} berhasil.\nTerima kasih!'
                : 'Tagihan SPP Anda telah berhasil dibayar.\nTerima kasih!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInstallment ? const Color(0xFF3498DB) : const Color(0xFF2ECC71),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE74C3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pembayaran Gagal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B2849),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallmentHistory(Map<String, dynamic> billing) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A085)),
      ),
    );

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/installments/${billing['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          _showInstallmentHistoryDialog(billing, data['data']);
        } else {
          _showErrorDialog(data['message'] ?? 'Gagal memuat riwayat cicilan');
        }
      } else {
        _showErrorDialog('Gagal memuat riwayat cicilan');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _showInstallmentHistoryDialog(Map<String, dynamic> billing, Map<String, dynamic> data) {
    final installments = data['installments'] as List? ?? [];
    final tagihan = data['tagihan'] as Map<String, dynamic>? ?? {};
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Color(0xFF3498DB),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Cicilan',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2B2849),
                              ),
                            ),
                            Text(
                              '${billing['month']} ${billing['year']}',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInstallmentSummaryItem(
                          'Total Tagihan',
                          'Rp ${_formatCurrency(tagihan['jumlah'] ?? billing['total_amount'])}',
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _buildInstallmentSummaryItem(
                          'Sudah Dibayar',
                          'Rp ${_formatCurrency(tagihan['terbayar'] ?? billing['terbayar'])}',
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _buildInstallmentSummaryItem(
                          'Sisa',
                          'Rp ${_formatCurrency(tagihan['remaining'] ?? billing['remaining'])}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Installment list
            Expanded(
              child: installments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat cicilan',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: installments.length,
                      itemBuilder: (context, index) {
                        final installment = installments[index] as Map<String, dynamic>;
                        final isSuccess = installment['status'] == 'success';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSuccess 
                                      ? const Color(0xFF2ECC71).withOpacity(0.1)
                                      : const Color(0xFFE74C3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isSuccess 
                                          ? const Color(0xFF2ECC71)
                                          : const Color(0xFFE74C3C),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rp ${_formatCurrency(installment['amount'] ?? 0)}',
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2B2849),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      installment['paid_at'] ?? installment['created_at'] ?? '-',
                                      style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSuccess 
                                      ? const Color(0xFF2ECC71).withOpacity(0.1)
                                      : const Color(0xFFE74C3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isSuccess ? 'Berhasil' : 'Gagal',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSuccess 
                                        ? const Color(0xFF2ECC71)
                                        : const Color(0xFFE74C3C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
