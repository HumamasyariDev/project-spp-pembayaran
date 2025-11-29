class Payment {
  final int id;
  final int userId;
  final int sppBillId;
  final String month;
  final String year;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String ticketCode;
  final String academicYear;
  final String status;

  Payment({
    required this.id,
    required this.userId,
    required this.sppBillId,
    required this.month,
    required this.year,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.ticketCode,
    required this.academicYear,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      sppBillId: json['spp_bill_id'] is int ? json['spp_bill_id'] : int.parse(json['spp_bill_id'].toString()),
      month: json['month']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString() ?? '',
      ticketCode: json['ticket_code']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'spp_bill_id': sppBillId,
      'month': month,
      'year': year,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'ticket_code': ticketCode,
      'academic_year': academicYear,
      'status': status,
    };
  }

  String get formattedAmount {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String get monthName {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    int monthNum = int.tryParse(month) ?? 1;
    return months[monthNum - 1];
  }
}
