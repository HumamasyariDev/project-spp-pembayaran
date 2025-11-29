import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment_model.dart';
import '../models/spp_bill_model.dart';
import 'auth_service.dart';

class PaymentService {
  // ==================== SISWA ENDPOINTS ====================

  /// Mendapatkan daftar tagihan SPP
  Future<List<SppBill>> getSppBills() async {
    // Sementara return dummy data untuk demo
    // Nanti akan diganti dengan API call yang sebenarnya
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      SppBill(
        id: 1,
        userId: 1,
        month: '09',
        year: '2024',
        amount: 500000,
        status: 'belum_lunas',
        dueDate: DateTime(2024, 9, 10),
        userName: 'Muhammad Siswa',
        userNis: '2024001',
        userKelas: 'XII IPA 1',
      ),
      SppBill(
        id: 2,
        userId: 1,
        month: '08',
        year: '2024',
        amount: 500000,
        status: 'lunas',
        dueDate: DateTime(2024, 8, 10),
        paidAt: DateTime(2024, 8, 5),
        userName: 'Muhammad Siswa',
        userNis: '2024001',
        userKelas: 'XII IPA 1',
      ),
      SppBill(
        id: 3,
        userId: 1,
        month: '07',
        year: '2024',
        amount: 500000,
        status: 'lunas',
        dueDate: DateTime(2024, 7, 10),
        paidAt: DateTime(2024, 7, 8),
        userName: 'Muhammad Siswa',
        userNis: '2024001',
        userKelas: 'XII IPA 1',
      ),
    ];
  }

  /// Mendapatkan riwayat pembayaran dengan tiket
  Future<List<Payment>> getPaymentHistory() async {
    // Sementara return dummy data untuk demo
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      Payment(
        id: 1,
        userId: 1,
        sppBillId: 2,
        month: 'Agustus',
        year: '2024',
        amount: 500000,
        paymentMethod: 'Transfer Bank',
        paymentDate: '05 Agustus 2024',
        ticketCode: 'SPP2024080001',
        academicYear: '2024/2025',
        status: 'completed',
      ),
      Payment(
        id: 2,
        userId: 1,
        sppBillId: 3,
        month: 'Juli',
        year: '2024',
        amount: 500000,
        paymentMethod: 'Cash',
        paymentDate: '08 Juli 2024',
        ticketCode: 'SPP2024070001',
        academicYear: '2024/2025',
        status: 'completed',
      ),
    ];
  }

  /// Lihat semua tagihan SPP siswa
  static Future<Map<String, dynamic>> getMyBills() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/my-bills'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<SppBill> bills = [];
        if (data['data'] != null) {
          bills = (data['data'] as List)
              .map((json) => SppBill.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'bills': bills,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data tagihan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Lihat tagihan yang belum dibayar
  static Future<Map<String, dynamic>> getUnpaidBills() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/unpaid-bills'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<SppBill> bills = [];
        if (data['data'] != null) {
          bills = (data['data'] as List)
              .map((json) => SppBill.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'bills': bills,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data tagihan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Bayar tagihan SPP
  static Future<Map<String, dynamic>> createPayment({
    required int billId,
    required String paymentMethod, // cash, transfer
    String? proofImage, // URL atau base64 bukti transfer
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/bills/$billId/pay'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'payment_method': paymentMethod,
          'proof_image': proofImage,
          'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pembayaran berhasil dibuat',
          'payment': data['data'] != null ? Payment.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat pembayaran',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Lihat riwayat pembayaran siswa
  static Future<Map<String, dynamic>> getMyPayments() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/my-payments'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Payment> payments = [];
        if (data['data'] != null) {
          payments = (data['data'] as List)
              .map((json) => Payment.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'payments': payments,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data pembayaran',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ==================== PETUGAS/ADMIN ENDPOINTS ====================

  /// Lihat semua pembayaran (dengan filter status)
  static Future<Map<String, dynamic>> getAllPayments({String? status}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      String url = '${ApiConfig.baseUrl}/payments';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Payment> payments = [];
        if (data['data'] != null) {
          payments = (data['data'] as List)
              .map((json) => Payment.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'payments': payments,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data pembayaran',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Lihat detail pembayaran
  static Future<Map<String, dynamic>> getPaymentDetail(int paymentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/$paymentId'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'payment': data['data'] != null ? Payment.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil detail pembayaran',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Verifikasi atau tolak pembayaran
  static Future<Map<String, dynamic>> verifyPayment({
    required int paymentId,
    required String action, // verify, reject
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/$paymentId/verify'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'action': action,
          'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pembayaran berhasil diverifikasi',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memverifikasi pembayaran',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}

