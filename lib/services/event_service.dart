import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class EventService {
  /// Get upcoming events
  static Future<Map<String, dynamic>> getUpcomingEvents({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/upcoming?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📅 Upcoming Events Response: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch upcoming events',
        };
      }
    } catch (e) {
      print('❌ Upcoming Events Error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get all events with optional filters
  static Future<Map<String, dynamic>> getAllEvents({
    String? category,
    String? fromDate,
    String? toDate,
    bool? featured,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      if (featured != null) queryParams['featured'] = featured.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}/events').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📅 All Events Response: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      print('❌ All Events Error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get event detail by ID
  static Future<Map<String, dynamic>> getEventDetail(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📅 Event Detail Response: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch event detail',
        };
      }
    } catch (e) {
      print('❌ Event Detail Error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get similar events by ID
  static Future<Map<String, dynamic>> getSimilarEvents(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId/similar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📅 Similar Events Response: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch similar events',
        };
      }
    } catch (e) {
      print('❌ Similar Events Error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Set reminder for an event
  static Future<Map<String, dynamic>> setReminder(int eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId/remind'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}

