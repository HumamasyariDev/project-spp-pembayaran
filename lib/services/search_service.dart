import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class SearchService {
  static Future<Map<String, dynamic>> search(String query) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return _handleError('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/search?query=$query'),
        headers: ApiConfig.headers(token: token),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Server tidak merespons');
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Search API Response: $result');
        return result;
      } else {
        print('Search API Error: ${response.statusCode} - ${response.body}');
        return _handleError('Failed to load search results. Status: ${response.statusCode}');
      }
    } catch (e) {
      return _handleError(e.toString());
    }
  }

  // Get recent data untuk ditampilkan saat search kosong
  static Future<Map<String, dynamic>> getRecentData() async {
    final token = await AuthService.getToken();
    if (token == null) {
      return _handleError('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/search/recent'),
        headers: ApiConfig.headers(token: token),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Server tidak merespons');
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Recent Data Response: $result');
        return result;
      } else {
        print('Recent Data Error: ${response.statusCode} - ${response.body}');
        return _handleError('Failed to load recent data. Status: ${response.statusCode}');
      }
    } catch (e) {
      return _handleError(e.toString());
    }
  }

  static Map<String, dynamic> _handleError(String message) {
    print('Search Service Error: $message');
    return {'success': false, 'message': message, 'data': []};
  }
}
