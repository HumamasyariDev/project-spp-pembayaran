import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        print('👤 Full User Data: $userData'); // Debugging
        print('👤 Jurusan Value: ${userData['jurusan']}'); // Debugging
        
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Lighter background
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary05))
          : _userData == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildMainProfileCard(),
                      _buildInfoSection(),
                      _buildActionSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Data profil tidak ditemukan'),
        ],
      ),
    );
  }

  // 1. Header Section (Background & AppBar)
  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF16A085), // Primary Teal
                const Color(0xFF0B5345), // Deep Bold Teal
              ],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A085).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        // Decorative Pattern
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        // Custom App Bar Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  'Profil Saya',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                    onPressed: () {
                      // Settings
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Main Profile Card (Floating)
  Widget _buildMainProfileCard() {
    final name = _userData!['name'] ?? 'Siswa';
    final kelas = _userData!['kelas'] ?? '-';
    final jurusan = _userData!['jurusan'];
    final nisn = _userData!['nisn'] ?? '-';

    // Logic display kelas & jurusan
    String classMajorText = kelas;
    if (jurusan != null && jurusan.toString().isNotEmpty && jurusan.toString() != '-') {
      classMajorText = '$kelas • $jurusan';
    }

    return Transform.translate(
      offset: const Offset(0, -50), // Pull up to overlap header
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // The Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D3436).withOpacity(0.15), // Stronger shadow
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFF16A085).withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A085),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Name
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF16A085).withOpacity(0.3)),
                    ),
                    child: const Text(
                      'SISWA AKTIF',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A085),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Stats Grid (NISN & Class)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'NISN',
                          nisn,
                          Icons.fingerprint,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Kelas / Jurusan',
                          classMajorText,
                          Icons.school_outlined,
                          isWide: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF16A085)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Information List
  Widget _buildInfoSection() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pribadi',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    Icons.email_outlined,
                    'Email',
                    _userData!['email'] ?? '-',
                  ),
                  _buildDivider(),
                  if (_userData!['telepon'] != null) ...[
                    _buildInfoTile(
                      Icons.phone_outlined,
                      'Telepon',
                      _userData!['telepon'],
                    ),
                    _buildDivider(),
                  ],
                  if (_userData!['alamat'] != null)
                    _buildInfoTile(
                      Icons.location_on_outlined,
                      'Alamat',
                      _userData!['alamat'],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A085).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF16A085), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5), indent: 60, endIndent: 20);
  }

  // 4. Action Buttons (Settings)
  Widget _buildActionSection() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Akun',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            _buildActionButton(
              'Ubah Password',
              Icons.lock_outline,
              Colors.white,
              const Color(0xFF2D3436),
              () {
                // TODO: Change password
              },
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              'Keluar Aplikasi',
              Icons.logout_rounded,
              const Color(0xFFFFEBEE), // Light red bg
              const Color(0xFFE74C3C), // Red text
              () async {
                 final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color bgColor, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: bgColor == Colors.white 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] 
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
