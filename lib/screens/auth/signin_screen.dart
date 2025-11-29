import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../widgets/common/custom_text_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (result['success']) {
        // Validasi role harus siswa
        final user = result['user'];
        if (user != null && user.roles != null) {
          // Cek apakah user memiliki role siswa (case insensitive)
          final isSiswa = user.roles.any((role) => 
            role.toString().toLowerCase() == 'siswa'
          );
          
          if (!isSiswa) {
            // Bukan siswa, logout dan tampilkan error
            await AuthService.logout();
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Akses ditolak! Aplikasi ini hanya untuk siswa.'),
                  backgroundColor: AppColors.destructive02,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }
        
        // Role siswa, boleh masuk
        if (mounted) {
          // Navigate ke home
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Login gagal'),
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
            content: Text('Terjadi kesalahan. Silakan coba lagi.'),
            backgroundColor: AppColors.destructive02,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final googleResult = await GoogleAuthService.signInWithGoogle();

      if (googleResult['success']) {
        // Check apakah email sudah terdaftar
        final emailCheck = await AuthService.checkEmail(googleResult['email']);

        if (mounted) {
          setState(() => _isLoading = false);

          if (emailCheck['exists'] == true) {
            // Email sudah terdaftar - auto login
            final loginResult = await AuthService.loginWithGoogle(
              email: googleResult['email'],
              googleId: googleResult['uid'],
              displayName: googleResult['displayName'],
              photoUrl: googleResult['photoUrl'],
            );

            if (loginResult['success']) {
              // Login berhasil, navigate to home
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selamat datang, ${loginResult['user']?.name ?? "User"}!'),
                    backgroundColor: AppColors.primary01,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pushReplacementNamed(context, '/home');
              }
            } else {
              // Login gagal
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loginResult['message'] ?? 'Login gagal'),
                    backgroundColor: AppColors.destructive02,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } else {
            // Email belum terdaftar - redirect ke signup
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun belum terdaftar. Silakan daftar terlebih dahulu'),
                backgroundColor: AppColors.primary04,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Navigate to signup
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.pushNamed(context, '/signup');
            }
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(googleResult['message'] ?? 'Login dengan Google gagal'),
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
            content: Text('Terjadi kesalahan saat login dengan Google'),
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
                  'assets/illustrations/signin_illustration.png',
                  height: 200,
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
                const SizedBox(height: 24),
                
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
                          'Selamat Datang Kembali 👋',
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
                        const SizedBox(height: 20),
                        
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
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 300.ms,
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
                            .fadeIn(duration: 500.ms, delay: 400.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 400.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 8),
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur Lupa Password akan segera tersedia'),
                                  backgroundColor: AppColors.primary04,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.33,
                                  color: AppColors.primary04,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
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
                                    'Login',
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
                            .fadeIn(duration: 500.ms, delay: 500.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              delay: 500.ms,
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
                                'Atau lanjutkan dengan',
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
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
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
                                  'Lanjutkan dengan Google',
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
                
                // Sign Up Link
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: RichText(
                      text: const TextSpan(
                        text: "Belum punya akun? ",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                          color: Color(0xFF677687),
                        ),
                        children: [
                          TextSpan(
                            text: 'Daftar',
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
