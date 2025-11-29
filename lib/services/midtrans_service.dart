import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MidtransService {
  // Midtrans Configuration
  // Key langsung dari dashboard tanpa prefix tambahan
  static const String _serverKey = 'Mid-server-dFFtiNj8J4--bPOtjAKrQ7Fg'; // Server Key
  static const String _clientKey = 'Mid-client-ZruvXSfXPykBNH3T'; // Client Key
  static const bool _isProduction = false; // false = Sandbox, true = Production
  
  // Midtrans API URLs
  static String get _snapUrl => _isProduction
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
  
  static String get _apiUrl => _isProduction
      ? 'https://api.midtrans.com/v2'
      : 'https://api.sandbox.midtrans.com/v2';

  /// Create Snap Token untuk pembayaran
  static Future<Map<String, dynamic>> createSnapToken({
    required String orderId,
    required int grossAmount,
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> itemDetails,
  }) async {
    try {
      final auth = base64Encode(utf8.encode('$_serverKey:'));
      
      final body = {
        'transaction_details': {
          'order_id': orderId,
          'gross_amount': grossAmount,
        },
        'customer_details': customerDetails,
        'item_details': itemDetails,
        'enabled_payments': [
          'qris',
          'gopay',
          'shopeepay',
          'other_qris',
          'bca_va',
          'bni_va',
          'bri_va',
          'mandiri_va',
          'permata_va',
          'other_va',
          'indomaret',
          'alfamart',
        ],
      };

      final response = await http.post(
        Uri.parse(_snapUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'redirect_url': data['redirect_url'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create transaction: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Check transaction status
  static Future<Map<String, dynamic>> checkTransactionStatus(String orderId) async {
    try {
      final auth = base64Encode(utf8.encode('$_serverKey:'));
      
      final response = await http.get(
        Uri.parse('$_apiUrl/$orderId/status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transaction_status': data['transaction_status'],
          'fraud_status': data['fraud_status'],
          'payment_type': data['payment_type'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check status: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Cancel transaction
  static Future<Map<String, dynamic>> cancelTransaction(String orderId) async {
    try {
      final auth = base64Encode(utf8.encode('$_serverKey:'));
      
      final response = await http.post(
        Uri.parse('$_apiUrl/$orderId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Transaction cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to cancel transaction: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Generate unique order ID
  static String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'SPP-$timestamp';
  }

  /// Get client key for frontend
  static String get clientKey => _clientKey;
  
  /// Get snap URL for frontend
  static String get snapUrl => _isProduction
      ? 'https://app.midtrans.com/snap/snap.js'
      : 'https://app.sandbox.midtrans.com/snap/snap.js';
}

