import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/queue_model.dart';
import 'auth_service.dart';

class QueueService {
  // ==================== SISWA ENDPOINTS ====================
  
  /// Ambil nomor antrian baru
  static Future<Map<String, dynamic>> createQueue({
    required int serviceId, 
    String? notes
  }) async {
    try {
      final token = await AuthService.getToken();
      print('DEBUG createQueue: Token = ${token?.substring(0, 20)}...'); // Debug
      
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final requestBody = {
        'service_id': serviceId,
        'notes': notes,
      };
      
      print('DEBUG createQueue: Request Body = $requestBody'); // Debug
      print('DEBUG createQueue: serviceId = $serviceId (${serviceId.runtimeType})'); // Debug
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/queues'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(requestBody),
      );

      print('DEBUG createQueue: Status Code = ${response.statusCode}'); // Debug
      print('DEBUG createQueue: Response Body = ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Antrian berhasil dibuat',
          'queue': data['data'] != null ? Queue.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat antrian',
        };
      }
    } catch (e) {
      print('DEBUG createQueue: Error = $e'); // Debug
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Lihat riwayat antrian siswa
  static Future<Map<String, dynamic>> getMyQueues() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/queues/my-queues'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Queue> queues = [];
        if (data['data'] != null) {
          queues = (data['data'] as List)
              .map((json) => Queue.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'queues': queues,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data antrian',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get active queues with real-time estimation (returns array)
  static Future<Map<String, dynamic>> getMyActiveQueues() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/queues/my-active-queue'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'] ?? [], // Returns array of active queues
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data antrian',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Batalkan antrian (siswa)
  static Future<Map<String, dynamic>> cancelQueue(int queueId) async {
    try {
      final token = await AuthService.getToken();
      print('DEBUG cancelQueue: Token = ${token?.substring(0, 20)}...'); // Debug
      print('DEBUG cancelQueue: Queue ID = $queueId'); // Debug
      
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final url = '${ApiConfig.baseUrl}/queues/$queueId/cancel';
      print('DEBUG cancelQueue: URL = $url'); // Debug
      
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.headers(token: token),
      );

      print('DEBUG cancelQueue: Status Code = ${response.statusCode}'); // Debug
      print('DEBUG cancelQueue: Response Body = ${response.body}'); // Debug

      if (response.statusCode == 200) {
        // Parse response with try-catch to handle any JSON errors
        try {
          final data = jsonDecode(response.body);
          // Check both 'success' and 'status' for backward compatibility
          final isSuccess = data['success'] == true || 
                          data['success'] == 'true' ||
                          data['status'] == true || 
                          data['status'] == 'true';
          return {
            'success': isSuccess,
            'message': data['message']?.toString() ?? 'Antrian berhasil dibatalkan',
          };
        } catch (jsonError) {
          print('DEBUG cancelQueue: JSON Parse Error = $jsonError'); // Debug
          // If JSON parse fails but status is 200, consider it success
          return {
            'success': true,
            'message': 'Antrian berhasil dibatalkan',
          };
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message']?.toString() ?? 'Gagal membatalkan antrian',
          };
        } catch (jsonError) {
          return {
            'success': false,
            'message': 'Gagal membatalkan antrian (Status: ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('DEBUG cancelQueue: Error = $e'); // Debug
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ==================== PUBLIC ENDPOINTS ====================

  /// Get layanan tersedia dengan statistik real-time
  static Future<Map<String, dynamic>> getServices() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/queues/services'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> services = [];
        if (data['data'] != null) {
          services = (data['data'] as List)
              .map((json) => json as Map<String, dynamic>)
              .toList();
        }

        return {
          'success': true,
          'services': services,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data layanan',
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

  /// Lihat antrian aktif hari ini (petugas/admin)
  static Future<Map<String, dynamic>> getActiveQueues() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/queues/active'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Queue> queues = [];
        if (data['data'] != null) {
          queues = (data['data'] as List)
              .map((json) => Queue.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'queues': queues,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data antrian',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Panggil antrian berikutnya (petugas/admin)
  static Future<Map<String, dynamic>> callNext() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/queues/call-next'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Antrian berhasil dipanggil',
          'queue': data['data'] != null ? Queue.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memanggil antrian',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Tandai antrian sedang dilayani (petugas/admin)
  static Future<Map<String, dynamic>> serveQueue(int queueId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/queues/$queueId/serve'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Antrian sedang dilayani',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal melayani antrian',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Tandai antrian selesai (petugas/admin)
  static Future<Map<String, dynamic>> completeQueue(int queueId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/queues/$queueId/complete'),
        headers: ApiConfig.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Antrian selesai',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyelesaikan antrian',
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

