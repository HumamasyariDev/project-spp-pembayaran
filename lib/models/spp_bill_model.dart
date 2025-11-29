class SppBill {
  final int id;
  final int userId;
  final String month; // 01-12
  final String year; // 2024, 2025
  final int amount;
  final String status; // unpaid, paid, overdue
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? userName;
  final String? userNis;
  final String? userKelas;
  
  SppBill({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.userName,
    this.userNis,
    this.userKelas,
  });
  
  factory SppBill.fromJson(Map<String, dynamic> json) {
    return SppBill(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      month: json['month']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      amount: json['amount'] is int ? json['amount'] : int.parse(json['amount'].toString()),
      status: json['status']?.toString() ?? 'unpaid',
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'].toString()) 
          : DateTime.now(),
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'].toString()) 
          : null,
      userName: json['user_name']?.toString(),
      userNis: json['user_nis']?.toString(),
      userKelas: json['user_kelas']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'year': year,
      'amount': amount,
      'status': status,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'user_name': userName,
      'user_nis': userNis,
      'user_kelas': userKelas,
    };
  }
  
  // Helper methods
  bool get isUnpaid => status == 'unpaid';
  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';
  
  String get monthName {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    int monthNum = int.parse(month);
    return months[monthNum - 1];
  }
  
  String get formattedAmount {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
  
  String get periodLabel => '$monthName $year';
  
  bool get isDueNow {
    return DateTime.now().isAfter(dueDate) && isUnpaid;
  }
}

