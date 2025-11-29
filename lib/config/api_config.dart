class ApiConfig {
  // ==================== LOCAL NETWORK (WIFI) ====================
  // Backend Laravel Docker di jaringan lokal
  // IP Address: 192.168.1.7
  static const String baseUrl = 'http://192.168.0.192:8000/api';
  
  // ==================== AUTH ENDPOINTS ====================
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/profile';
  static const String logout = '$baseUrl/auth/logout';
  
  // ==================== QUEUE ENDPOINTS ====================
  // Siswa
  static const String queues = '$baseUrl/queues';
  static const String myQueues = '$baseUrl/queues/my-queues';
  // Petugas/Admin
  static const String activeQueues = '$baseUrl/queues/active';
  static const String callNext = '$baseUrl/queues/call-next';
  
  // ==================== PAYMENT ENDPOINTS ====================
  // Siswa
  static const String myBills = '$baseUrl/payments/my-bills';
  static const String unpaidBills = '$baseUrl/payments/unpaid-bills';
  static const String myPayments = '$baseUrl/payments/my-payments';
  // Petugas/Admin
  static const String payments = '$baseUrl/payments';
  
  // ==================== NOTIFICATION ENDPOINTS ====================
  static const String notifications = '$baseUrl/notifications';
  static const String unreadCount = '$baseUrl/notifications/unread-count';
  static const String unreadNotifications = '$baseUrl/notifications/unread';
  static const String markAllRead = '$baseUrl/notifications/mark-all-read';
  static String markNotificationRead(int id) => '$baseUrl/notifications/$id/mark-read';
  static String deleteNotification(int id) => '$baseUrl/notifications/$id';
  
  // Headers
  static Map<String, String> headers({String? token}) {
    final Map<String, String> header = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      header['Authorization'] = 'Bearer $token';
    }
    
    return header;
  }
}

