import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class NotificationService {
  /// Get all notifications for the logged-in user
  /// [filter] can be: 'Semua', 'Pembayaran', 'Acara', 'Pengumuman', 'Sistem'
  static Future<List<Map<String, dynamic>>> getNotifications([String filter = 'Semua']) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('No auth token found');
      }

      // Build URL dengan atau tanpa filter
      String url = '${ApiConfig.baseUrl}/notifications';
      if (filter != 'Semua') {
        url += '?type=$filter';
      }

      print('📬 Fetching notifications with filter: $filter');
      print('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Notifications Response: ${response.statusCode}');
      print('📬 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📬 Parsed data: ${data['status']}, has data: ${data['data'] != null}');
        if (data['status'] == true && data['data'] != null) {
          final notifications = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Loaded ${notifications.length} notifications');
          if (notifications.isNotEmpty) {
            print('   First notification: ${notifications[0]}');
          }
          return notifications;
        }
        print('⚠️ Status or data is null');
        return [];
      } else {
        print('❌ Failed to load notifications: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        return 0;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return data['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/mark-read'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
}
