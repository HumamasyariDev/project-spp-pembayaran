import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../widgets/common/custom_text_field.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisnController = TextEditingController();
  final _teleponController = TextEditingController();
  final _alamatController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  String? _selectedKelas;
  String? _selectedJurusan;
  String? _selectedJenisKelamin;
  
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _jurusanList = [];

  @override
  void initState() {
    super.initState();
    _fetchKelasJurusan();
  }

  @override
  void dispose() {
    _nisnController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // Fetch Kelas & Jurusan dari API
  Future<void> _fetchKelasJurusan() async {
    try {
      print('🔄 Fetching kelas & jurusan from API...');
      
      final kelasResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kelas'),
        headers: ApiConfig.headers(),
      );
      
      final jurusanResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/jurusan'),
        headers: ApiConfig.headers(),
      );

      if (kelasResponse.statusCode == 200 && jurusanResponse.statusCode == 200) {
        final kelasData = jsonDecode(kelasResponse.body);
        final jurusanData = jsonDecode(jurusanResponse.body);

        setState(() {
          _kelasList = List<Map<String, dynamic>>.from(kelasData['data']);
          _jurusanList = List<Map<String, dynamic>>.from(jurusanData['data']);
          _isLoadingData = false;
        });

        print('✓ Kelas loaded: ${_kelasList.length} items');
        print('✓ Jurusan loaded: ${_jurusanList.length} items');
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('❌ Error fetching kelas/jurusan: $e');
      setState(() {
        _isLoadingData = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data kelas & jurusan: ${e.toString()}'),
            backgroundColor: AppColors.destructive02,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Kelas wajib dipilih'),
          backgroundColor: AppColors.destructive02,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedJurusan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Jurusan wajib dipilih'),
          backgroundColor: AppColors.destructive02,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedJenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Jenis kelamin wajib dipilih'),
          backgroundColor: AppColors.destructive02,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ VALIDASI NISN KE BACKEND SEBELUM LANJUT
      final nisn = _nisnController.text.trim();
      print('🔍 Validating NISN: $nisn');
      
      final validationResult = await AuthService.validateNisn(nisn);
      
      if (!validationResult['success']) {
        // ❌ NISN TIDAK VALID
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${validationResult['message']}'),
              backgroundColor: AppColors.destructive02,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      print('✅ NISN valid! Student data: ${validationResult['data']}');
      
      // Simpan data profile sementara ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final profileData = {
        'nisn': nisn,
        'telepon': _teleponController.text,
        'alamat': _alamatController.text,
        'kelas': _selectedKelas,
        'jurusan': _selectedJurusan,
        'jenis_kelamin': _selectedJenisKelamin,
      };
      
      await prefs.setString('temp_profile', jsonEncode(profileData));
      
      print('✓ Profile data saved temporarily');
      print('✓ NISN: $nisn');
      print('✓ Kelas: $_selectedKelas');
      print('✓ Jurusan: $_selectedJurusan');

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Redirect ke halaman profile photo (final step)
        Navigator.pushNamed(context, '/profile-photo');
      }
    } catch (e) {
      print('❌ Error: $e');
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
                                'Langkah 2 dari 3',
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
                            
                            // Title
                            const Text(
                              'Lengkapi Data Diri',
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
                              'Isi data pribadi dan sekolah Anda dengan lengkap',
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

                            // Data Pribadi Section
                            _buildSectionTitle('Data Pribadi', Icons.person_outline_rounded)
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideX(begin: -0.1, end: 0, delay: 300.ms),

                        const SizedBox(height: 16),

                        // NISN Field
                        CustomTextField(
                          controller: _nisnController,
                          label: 'NISN',
                          hintText: 'Masukkan NISN',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'NISN tidak boleh kosong';
                            }
                            if (value.length < 10) {
                              return 'NISN minimal 10 digit';
                            }
                            return null;
                          },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 600.ms)
                            .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 600.ms),

                        const SizedBox(height: 16),

                        // Telepon Field
                        CustomTextField(
                          controller: _teleponController,
                          label: 'No. Telepon / WhatsApp',
                          hintText: 'Contoh: 08123456789',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor telepon tidak boleh kosong';
                            }
                            if (value.length < 10) {
                              return 'Nomor telepon minimal 10 digit';
                            }
                            return null;
                          },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 700.ms)
                            .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 700.ms),

                        const SizedBox(height: 16),

                        // Alamat Field
                        CustomTextField(
                          controller: _alamatController,
                          label: 'Alamat Lengkap',
                          hintText: 'Jalan, RT/RW, Kelurahan, Kecamatan',
                          prefixIcon: Icons.home_outlined,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat tidak boleh kosong';
                            }
                            return null;
                          },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 800.ms)
                            .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 800.ms),

                        const SizedBox(height: 16),

                        // Jenis Kelamin Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jenis Kelamin *',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF677687),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedJenisKelamin != null
                                      ? AppColors.primary04
                                      : const Color(0xFFCBD1D8),
                                  width: 1,
                                ),
                                boxShadow: _selectedJenisKelamin != null
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary04.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedJenisKelamin,
                                decoration: InputDecoration(
                                  hintText: 'Pilih Jenis Kelamin',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF677687).withOpacity(0.6),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.people_outline_rounded,
                                    size: 20,
                                    color: _selectedJenisKelamin != null
                                        ? AppColors.primary04
                                        : const Color(0xFF677687),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary04,
                                  size: 24,
                                ),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: 'L',
                                    child: Row(
                                      children: [
                                        Icon(Icons.male, color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Laki-laki',
                                          style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF021326),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'P',
                                    child: Row(
                                      children: [
                                        Icon(Icons.female, color: Colors.pink, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Perempuan',
                                          style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF021326),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJenisKelamin = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 850.ms)
                            .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 850.ms),

                        const SizedBox(height: 32),

                        // Data Sekolah Section
                        _buildSectionTitle('Data Sekolah', Icons.school_outlined)
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideX(begin: -0.1, end: 0, delay: 600.ms),

                        const SizedBox(height: 16),

                        // Kelas Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  color: AppColors.primary04,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Kelas',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF677687),
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedKelas != null
                                      ? AppColors.primary04
                                      : const Color(0xFFCBD1D8),
                                  width: 1,
                                ),
                                boxShadow: _selectedKelas != null
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary04.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedKelas,
                                decoration: InputDecoration(
                                  hintText: 'Pilih Kelas',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF677687).withOpacity(0.6),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.class_outlined,
                                    size: 20,
                                    color: _selectedKelas != null
                                        ? AppColors.primary04
                                        : const Color(0xFF677687),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary04,
                                  size: 24,
                                ),
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                items: _isLoadingData 
                                  ? <DropdownMenuItem<String>>[]
                                  : _kelasList.map((kelas) {
                                      return DropdownMenuItem<String>(
                                        value: kelas['nama'],
                                        child: Text(
                                          'Kelas ${kelas['nama']} - ${kelas['keterangan']}',
                                          style: const TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF021326),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                selectedItemBuilder: (BuildContext context) {
                                  return _kelasList.map((kelas) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Kelas ${kelas['nama']} - ${kelas['keterangan']}',
                                        style: const TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF021326),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih kelas';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedKelas = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 1000.ms)
                            .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 1000.ms),

                        const SizedBox(height: 12),

                        // Jurusan Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.business_center_rounded,
                                  color: AppColors.primary04,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Jurusan',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF677687),
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedJurusan != null
                                      ? AppColors.primary04
                                      : const Color(0xFFCBD1D8),
                                  width: 1,
                                ),
                                boxShadow: _selectedJurusan != null
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary04.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedJurusan,
                                decoration: InputDecoration(
                                  hintText: 'Pilih Jurusan',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF677687).withOpacity(0.6),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.work_outline_rounded,
                                    size: 20,
                                    color: _selectedJurusan != null
                                        ? AppColors.primary04
                                        : const Color(0xFF677687),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary04,
                                  size: 24,
                                ),
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                items: _isLoadingData 
                                  ? <DropdownMenuItem<String>>[]
                                  : _jurusanList.map((jurusan) {
                                      return DropdownMenuItem<String>(
                                        value: jurusan['kode'],
                                        child: Text(
                                          '${jurusan['kode']} - ${jurusan['nama']}',
                                          style: const TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF021326),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                selectedItemBuilder: (BuildContext context) {
                                  return _jurusanList.map((jurusan) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${jurusan['kode']} - ${jurusan['nama']}',
                                        style: const TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF021326),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih jurusan';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJurusan = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 1100.ms)
                            .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 1100.ms),

                        const SizedBox(height: 24),
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
                              onTap: _handleSubmit,
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
                      .fadeIn(delay: 700.ms)
                      .slideY(begin: 0.5, end: 0, delay: 700.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary04.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary04,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF021326),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

