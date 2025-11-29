class Queue {
  final int id;
  final int userId;
  final String queueNumber;
  final String? qrCode; // ✅ Added unique QR code for each queue
  final String status; // waiting, called, serving, completed, cancelled
  final DateTime date;
  final DateTime? calledAt;
  final DateTime? servedAt;
  final DateTime? completedAt;
  final String? notes;
  final String? userName;
  final String? userNis;
  
  Queue({
    required this.id,
    required this.userId,
    required this.queueNumber,
    this.qrCode, // ✅ Optional QR code parameter
    required this.status,
    required this.date,
    this.calledAt,
    this.servedAt,
    this.completedAt,
    this.notes,
    this.userName,
    this.userNis,
  });
  
  factory Queue.fromJson(Map<String, dynamic> json) {
    // Safe int parsing - handle both int and String types
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
    // Safe string parsing
    String safeParseString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      return value.toString();
    }
    
    // Safe DateTime parsing
    DateTime? safeParseDatetime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) return DateTime.parse(value);
        return null;
      } catch (e) {
        return null;
      }
    }
    
    return Queue(
      id: safeParseInt(json['id']),
      userId: safeParseInt(json['user_id']),
      queueNumber: safeParseString(json['queue_number'], defaultValue: '-'),
      qrCode: json['qr_code']?.toString(), // ✅ Parse QR code from API
      status: safeParseString(json['status'], defaultValue: 'waiting'),
      date: safeParseDatetime(json['date']) ?? DateTime.now(),
      calledAt: safeParseDatetime(json['called_at']),
      servedAt: safeParseDatetime(json['served_at']),
      completedAt: safeParseDatetime(json['completed_at']),
      notes: json['notes']?.toString(),
      userName: json['user_name']?.toString(),
      userNis: json['user_nis']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'queue_number': queueNumber,
      'qr_code': qrCode, // ✅ Include QR code in serialization
      'status': status,
      'date': date.toIso8601String(),
      'called_at': calledAt?.toIso8601String(),
      'served_at': servedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'user_name': userName,
      'user_nis': userNis,
    };
  }
  
  // Status helper methods
  bool get isWaiting => status == 'waiting';
  bool get isCalled => status == 'called';
  bool get isServing => status == 'serving';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  String get statusText {
    switch (status) {
      case 'waiting':
        return 'Menunggu';
      case 'called':
        return 'Dipanggil';
      case 'serving':
        return 'Sedang Dilayani';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

