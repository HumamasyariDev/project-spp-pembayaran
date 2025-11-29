import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'google_auth_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Attempting login for: $email');
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token
        if (data['data'] != null && data['data']['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['data']['token']);
          await prefs.setString('user', jsonEncode(data['data']['user']));
        }

        return {
          'success': data['status'] ?? true,
          'message': data['message'] ?? 'Login berhasil',
          'user': data['data'] != null ? User.fromJson(data['data']['user']) : null,
          'token': data['data'] != null ? data['data']['token'] : null,
        };
      } else {
        // ✅ FIXED: Return error message dari backend dengan detail
        String errorMessage = data['message'] ?? 'Login gagal';
        
        // Jika ada error tambahan dari backend (misalnya validasi status kelulusan)
        if (data['error'] != null) {
          errorMessage = data['error'];
        }
        
        print('❌ Login failed: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Login exception: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Register
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('📝 Attempting registration with NISN: ${userData['nisn']}');
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: ApiConfig.headers(),
        body: jsonEncode(userData),
      );

      print('📥 Register response status: ${response.statusCode}');
      print('📥 Register response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Simpan token dan user data setelah register berhasil
        if (data['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          
          // Simpan token jika ada
          if (data['data']['token'] != null) {
            await prefs.setString('token', data['data']['token']);
            print('✓ Token saved after registration: ${data['data']['token'].substring(0, 20)}...');
          }
          
          // Simpan user data
          if (data['data']['user'] != null) {
            await prefs.setString('user', jsonEncode(data['data']['user']));
            print('✓ User data saved after registration');
          } else if (data['data']['id'] != null) {
            // Jika response langsung user object (bukan nested)
            await prefs.setString('user', jsonEncode(data['data']));
            print('✓ User data saved (direct object)');
          }
        }
        
        return {
          'success': data['status'] ?? true,
          'message': data['message'] ?? 'Registrasi berhasil',
          'user': data['data']['user'] != null ? User.fromJson(data['data']['user']) : null,
          'token': data['data']['token'],
        };
      } else {
        // ✅ FIXED: Return error message dari backend dengan detail (NISN validation errors)
        String errorMessage = data['message'] ?? 'Registrasi gagal';
        
        // Jika ada error tambahan dari backend
        if (data['error'] != null) {
          errorMessage = data['error'];
        }
        
        // Jika ada validation errors (untuk field-specific errors)
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            // Ambil error pertama
            errorMessage = errors.values.first.toString();
            if (errorMessage.startsWith('[') && errorMessage.endsWith(']')) {
              errorMessage = errorMessage.substring(1, errorMessage.length - 1);
            }
          }
        }
        
        print('❌ Registration failed: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'],
        };
      }
    } catch (e) {
      print('❌ Registration exception: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
  }

  // Logout
  static Future<bool> logout() async {
    try {
      // Logout from Google if logged in via Google
      try {
        await GoogleAuthService.signOut();
      } catch (e) {
        // Ignore if Google Sign-In not used
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.setBool('isLoggedIn', false);
      await prefs.clear(); // Clear all data
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Update Profile (kelas & jurusan)
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );

      print('📡 Update profile response status: ${response.statusCode}');
      print('📡 Update profile response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update user data di SharedPreferences
        if (data['data'] != null && data['data']['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(data['data']['user']));
        }

        return {
          'success': data['status'] ?? true,
          'message': data['message'] ?? 'Profile berhasil diupdate',
          'user': data['data'] != null ? User.fromJson(data['data']['user']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Update profile gagal',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Check if email exists (for Google Sign In validation)
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/check-email'),
        headers: ApiConfig.headers(),
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'exists': data['exists'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'exists': false,
          'message': data['message'] ?? 'Gagal mengecek email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'exists': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ✅ Validate NISN before registration
  static Future<Map<String, dynamic>> validateNisn(String nisn) async {
    try {
      print('🔍 Validating NISN: $nisn');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/validate-nisn'),
        headers: ApiConfig.headers(),
        body: jsonEncode({'nisn': nisn}),
      );

      print('📥 Validate NISN response status: ${response.statusCode}');
      print('📥 Validate NISN response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['status'] ?? true,
          'message': data['message'] ?? 'NISN valid',
          'data': data['data'],
        };
      } else {
        // ✅ Return error message dari backend
        String errorMessage = data['message'] ?? 'NISN tidak valid';
        
        if (data['error'] != null) {
          errorMessage = data['error'];
        }
        
        print('❌ NISN validation failed: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ NISN validation exception: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Login with Google (auto-login for existing users)
  static Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    String? googleId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login-google'),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': email,
          'google_id': googleId,
          'display_name': displayName,
          'photo_url': photoUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token
        if (data['data'] != null && data['data']['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['data']['token']);
          await prefs.setString('user', jsonEncode(data['data']['user']));
        }

        return {
          'success': data['status'] ?? true,
          'message': data['message'] ?? 'Login berhasil',
          'user': data['data'] != null ? User.fromJson(data['data']['user']) : null,
          'token': data['data'] != null ? data['data']['token'] : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login gagal',
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

