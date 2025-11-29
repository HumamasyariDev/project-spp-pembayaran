class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type; // queue, payment, general
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk icon berdasarkan type
  String get iconType {
    switch (type) {
      case 'queue':
        return 'queue';
      case 'payment':
        return 'payment';
      default:
        return 'general';
    }
  }

  // Helper untuk warna berdasarkan type
  String get colorType {
    switch (type) {
      case 'queue':
        return 'blue';
      case 'payment':
        return 'green';
      default:
        return 'gray';
    }
  }
}

