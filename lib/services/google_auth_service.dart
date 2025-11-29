import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in dengan Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return {
          'success': false,
          'message': 'Sign in dibatalkan',
        };
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Return user data untuk proses selanjutnya (complete signup atau direct login)
        return {
          'success': true,
          'message': 'Login berhasil',
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'uid': user.uid,
        };
      }

      return {
        'success': false,
        'message': 'Gagal mendapatkan data user',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    final User? user = _auth.currentUser;
    return user != null;
  }

  /// Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      
      if (userString != null) {
        return jsonDecode(userString);
      }
      
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}

