import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../widgets/common/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan dan Kebijakan Privasi'),
          backgroundColor: AppColors.destructive02,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simpan data registrasi sementara ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final registrationData = {
        'name': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': 'siswa',
      };
      
      await prefs.setString('temp_registration', jsonEncode(registrationData));
      
      print('✓ Registration data saved temporarily');
      print('✓ Name: ${_usernameController.text}');
      print('✓ Email: ${_emailController.text}');

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Redirect ke halaman complete profile (form data lengkap)
        Navigator.pushNamed(context, '/complete-profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: AppColors.destructive02,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (result['success']) {
        // Check apakah email sudah terdaftar
        final emailCheck = await AuthService.checkEmail(result['email']);
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          if (emailCheck['exists'] == true) {
            // Email sudah terdaftar - tidak bisa registrasi lagi
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email ${result['email']} sudah terdaftar. Silakan login.'),
                backgroundColor: AppColors.primary04,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Redirect ke login
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/signin');
            }
          } else {
            // Email belum terdaftar - lanjut ke registrasi
            Navigator.pushReplacementNamed(
              context,
              '/complete-google-signup',
              arguments: {
                'email': result['email'],
                'photoUrl': result['photoUrl'],
                'displayName': result['displayName'],
                'uid': result['uid'],
              },
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Daftar dengan Google gagal'),
              backgroundColor: AppColors.destructive02,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat daftar dengan Google'),
            backgroundColor: AppColors.destructive02,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 48),
                
                // Illustration
                Image.asset(
                  'assets/illustrations/signup_illustration.png',
                  height: 180,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 16),
                
                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Welcome Text
                        const Text(
                          'Selamat Datang 👋',
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.33,
                            color: Color(0xFF021326),
                  ),
                )
                    .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .slideX(
                              begin: -0.2,
                              end: 0,
                              duration: 600.ms,
                              delay: 200.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 16),
                        
                        // Username Field
                CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hintText: 'Masukkan username',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                              return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 300.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 12),
                
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                          hintText: 'Masukkan email',
                          prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                            if (!value.contains('@')) {
                              return 'Email tidak valid';
                    }
                    return null;
                  },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 400.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 400.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 12),
                
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                          hintText: 'Masukkan password',
                          prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                              size: 19,
                              color: const Color(0xFF677687),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 500.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 12),
                        
                        // Terms Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 17,
                              height: 17,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (value) {
                                  setState(() => _agreeToTerms = value ?? false);
                                },
                                activeColor: AppColors.primary04,
                                side: const BorderSide(
                                  color: Color(0xFFCBD1D8),
                                  width: 1,
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Saya setuju dengan ',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.33,
                                    color: Color(0xFF021326),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Syarat & Ketentuan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' dan '),
                                    TextSpan(
                                      text: 'Kebijakan Privasi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary04,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                                : const Text(
                            'Daftar',
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.33,
                                    ),
                                  ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 600.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 600.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .then()
                            .shimmer(
                              duration: 1500.ms,
                              delay: 200.ms,
                              color: Colors.white.withOpacity(0.3),
                            ),
                        const SizedBox(height: 20),
                        
                        // Or Divider
                Row(
                  children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white,
                                      Color(0xFF677687),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                                'Atau buat akun dengan',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.33,
                                  color: Color(0xFF677687),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF677687),
                                      Colors.white,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Google Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignUp,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              side: const BorderSide(
                                color: Color(0xFFCBD1D8),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Colors.white,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/google_icon.png',
                                  width: 26,
                                  height: 26,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Daftar dengan Google',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.33,
                                    color: Color(0xFF677687),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Sign In Link
                InkWell(
                  onTap: () {
                        Navigator.pushReplacementNamed(context, '/signin');
                      },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: RichText(
                      text: const TextSpan(
                        text: "Sudah punya akun? ",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                          color: Color(0xFF677687),
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.33,
                              color: AppColors.primary04,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
