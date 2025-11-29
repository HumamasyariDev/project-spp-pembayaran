import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: ${e.toString()}'),
            backgroundColor: AppColors.destructive02,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF021326),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Camera Option
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary04.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary04.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary04,
                                AppColors.primary04.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary04.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kamera',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF021326),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ambil foto baru',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF677687).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: AppColors.primary04,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Gallery Option
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary04.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary04.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary04,
                                AppColors.primary04.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary04.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Galeri',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF021326),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pilih dari galeri foto',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF677687).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: AppColors.primary04,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    // Validasi: Foto wajib diisi
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Foto profil wajib diisi'),
          backgroundColor: AppColors.destructive02,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil data registrasi dan profile yang sudah disimpan
      final tempRegistration = prefs.getString('temp_registration');
      final tempProfile = prefs.getString('temp_profile');
      
      if (tempRegistration == null || tempProfile == null) {
        throw Exception('Data registrasi tidak lengkap');
      }
      
      final registrationData = jsonDecode(tempRegistration) as Map<String, dynamic>;
      final profileData = jsonDecode(tempProfile) as Map<String, dynamic>;
      
      // Gabungkan semua data
      final Map<String, dynamic> completeData = {
        ...registrationData,
        ...profileData,
        'password_confirmation': registrationData['password'],
      };
      
      print('🔄 Registering user with complete data...');
      print('✓ Name: ${completeData['name']}');
      print('✓ Email: ${completeData['email']}');
      print('✓ NISN: ${completeData['nisn']}');
      print('✓ Kelas: ${completeData['kelas']}');
      print('✓ Jurusan: ${completeData['jurusan']}');
      
      // Kirim ke backend untuk save ke database
      final result = await AuthService.register(completeData);
      
      if (result['success']) {
        // Simpan foto profil ke local storage
        await prefs.setString('profile_photo_path', _selectedImage!.path);
        
        // Hapus data temporary
        await prefs.remove('temp_registration');
        await prefs.remove('temp_profile');
        
        print('✓ Registration complete!');
        print('✓ User saved to database');
        print('✓ Temporary data cleared');
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registrasi berhasil! Selamat datang!'),
              backgroundColor: AppColors.primary04,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception(result['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Tampilkan error detail
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
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
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Simple Header with Back Button
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
                                'Langkah Terakhir',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          
                          // Title
                          const Text(
                            'Foto Profil',
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
                            'Hampir selesai! Upload foto profil terbaik Anda 📸',
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
                          
                          const SizedBox(height: 48),
                          
                          // Avatar Section
                          Center(
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Main Avatar with Smooth Shadow
                                  Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary04.withOpacity(0.15),
                                          blurRadius: 40,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedImage != null
                                              ? AppColors.primary04.withOpacity(0.3)
                                              : const Color(0xFFE8E8E8),
                                          width: 4,
                                        ),
                                        color: _selectedImage == null
                                            ? const Color(0xFFF8F9FA)
                                            : Colors.white,
                                        image: _selectedImage != null
                                            ? DecorationImage(
                                                image: FileImage(_selectedImage!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _selectedImage == null
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 100,
                                              color: const Color(0xFF677687).withOpacity(0.3),
                                            )
                                          : null,
                                    ),
                                  ),
                                  
                                  // Camera Button - Floating Style
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary04,
                                            AppColors.primary04.withOpacity(0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary04.withOpacity(0.5),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    )
                                        .animate(
                                          onPlay: (controller) => controller.repeat(reverse: true),
                                        )
                                        .scale(
                                          begin: const Offset(1.0, 1.0),
                                          end: const Offset(1.1, 1.1),
                                          duration: 1500.ms,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 600.ms)
                              .scale(
                                begin: const Offset(0.7, 0.7),
                                end: const Offset(1.0, 1.0),
                                delay: 300.ms,
                                duration: 800.ms,
                                curve: Curves.easeOutBack,
                              ),
                          
                          const SizedBox(height: 40),
                          
                          // Action Buttons
                          if (_selectedImage == null)
                            _buildActionButton(
                              icon: Icons.add_photo_alternate_rounded,
                              label: 'Pilih Foto',
                              onTap: _showImageSourceDialog,
                              isPrimary: true,
                            )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideY(begin: 0.3, end: 0, delay: 400.ms)
                          else
                            _buildActionButton(
                              icon: Icons.refresh_rounded,
                              label: 'Ganti Foto',
                              onTap: _showImageSourceDialog,
                              isPrimary: false,
                            )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Info Card - Subtle
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary04.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary04.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary04.withOpacity(0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Gunakan foto dengan wajah terlihat jelas untuk hasil terbaik',
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF677687).withOpacity(0.9),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 500.ms),
                          
                          const SizedBox(height: 100),
                        ],
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
                        : AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _selectedImage != null ? _handleContinue : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: _selectedImage != null
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.primary04,
                                              AppColors.primary04.withOpacity(0.8),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          )
                                        : null,
                                    color: _selectedImage == null
                                        ? const Color(0xFFF0F0F0)
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _selectedImage != null
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary04.withOpacity(0.4),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: _selectedImage != null
                                              ? Colors.white
                                              : const Color(0xFFAAAAAA),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Selesai & Simpan',
                                          style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedImage != null
                                                ? Colors.white
                                                : const Color(0xFFAAAAAA),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.5, end: 0, delay: 400.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary04.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary04.withOpacity(0.3)
              : const Color(0xFFE8E8E8),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isPrimary ? AppColors.primary04 : const Color(0xFF677687),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.primary04 : const Color(0xFF677687),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

