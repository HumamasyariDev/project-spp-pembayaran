import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';

class CompleteGoogleSignupScreen extends StatefulWidget {
  final String email;
  final String? photoUrl;
  final String? displayName;

  const CompleteGoogleSignupScreen({
    super.key,
    required this.email,
    this.photoUrl,
    this.displayName,
  });

  @override
  State<CompleteGoogleSignupScreen> createState() => _CompleteGoogleSignupScreenState();
}

class _CompleteGoogleSignupScreenState extends State<CompleteGoogleSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google if available
    if (widget.displayName != null && widget.displayName!.isNotEmpty) {
      _nameController.text = widget.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteSignup() async {
    if (!_formKey.currentState!.validate()) {
      // Show validation error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan isi semua field dengan benar'),
          backgroundColor: AppColors.destructive02,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simpan data registrasi Google sementara ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final registrationData = {
        'name': _nameController.text.trim(),
        'email': widget.email,
        'password': _passwordController.text,
        'role': 'siswa',
      };
      
      await prefs.setString('temp_registration', jsonEncode(registrationData));
      
      print('✓ Google registration data saved temporarily');
      print('✓ Name: ${_nameController.text.trim()}');
      print('✓ Email: ${widget.email}');

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Redirect ke halaman complete profile (form data lengkap)
        Navigator.pushNamed(context, '/complete-profile');
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.destructive02,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
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
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary04.withOpacity(0.05),
                    Colors.white,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.25, 1.0],
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Simple Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary04.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.primary04,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary04.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primary04,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Langkah 1 dari 3',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary04,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .scale(begin: const Offset(0.8, 0.8), delay: 200.ms),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),

                  // Google Profile Info
                  Center(
                    child: Column(
                      children: [
                        // Profile Picture
                        if (widget.photoUrl != null)
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary04,
                                width: 3,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(widget.photoUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary04.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppColors.primary04,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Email from Google
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary04.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary04.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_rounded,
                                size: 18,
                                color: AppColors.primary04,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.email,
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary04,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 600.ms, curve: Curves.easeOutBack),

                            const SizedBox(height: 24),

                            // Title
                            const Text(
                              'Lengkapi Data Anda',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF021326),
                                letterSpacing: -0.5,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 100.ms)
                                .slideX(begin: -0.2, end: 0, delay: 100.ms),

                            const SizedBox(height: 8),

                            Text(
                              'Isi nama lengkap dan buat password untuk melanjutkan',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF677687).withOpacity(0.9),
                                height: 1.5,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  // Name Field
                  Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF021326),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      hintStyle: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF677687).withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary04,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFE8E8E8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary04,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      if (value.trim().length < 3) {
                        return 'Nama minimal 3 karakter';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 300.ms),

                  const SizedBox(height: 20),

                  // Password Field
                  Text(
                    'Password',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF021326),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buat password',
                      hintStyle: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF677687).withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary04,
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: const Color(0xFF677687),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFE8E8E8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary04,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
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
                      .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 400.ms),

                  const SizedBox(height: 20),

                  // Confirm Password Field
                  Text(
                    'Konfirmasi Password',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF021326),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Konfirmasi password',
                      hintStyle: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF677687).withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary04,
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: const Color(0xFF677687),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFE8E8E8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary04,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != _passwordController.text) {
                        return 'Password tidak sama';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleCompleteSignup(),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 500.ms)
                      .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 500.ms),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Button - Floating Style
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: _isLoading
                        ? Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary04.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleCompleteSignup,
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary04,
                                      AppColors.primary04.withOpacity(0.8),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary04.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Simpan & Lanjutkan',
                                        style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.5, end: 0, delay: 600.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

