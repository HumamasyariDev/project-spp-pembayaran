 import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/event_service.dart';
import '../../services/announcement_service.dart';
import '../../services/banner_service.dart';
import '../../services/fcm_service.dart';
import '../../services/search_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_header.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import '../notifications/notifications_screen.dart';
import '../events/event_detail_screen.dart';
import '../announcements/announcement_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _currentUser;
  String? _profilePhotoPath;
  bool _isLoading = true;
  bool _hasNotification = false; // State untuk notifikasi (auto-update dari API)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Location state
  String _locationName = 'SMK Taruna Jaya Prawira Tuban';
  bool _isLoadingLocation = false;
  
  // SPP Banner state (loaded from API)
  List<Map<String, dynamic>> _tunggakan = [];
  
  // API Data
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _latestAnnouncements = [];
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingData = false;
  int _currentBannerIndex = 0;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentData = []; // Data awal untuk ditampilkan
  bool _isSearching = false;
  Timer? _debounce;
  
  // Filter state
  String? _selectedFilter; // null = semua, 'event', 'announcement', 'bill'

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationCount();
    _loadDashboardData();
    _initializeFCM();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // Initialize FCM (Firebase Cloud Messaging)
  Future<void> _initializeFCM() async {
    try {
      await FCMService.initialize();
      print('✅ FCM initialized in HomeScreen');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final photoPath = prefs.getString('profile_photo_path');

    setState(() {
      _currentUser = user;
      _profilePhotoPath = photoPath;
      _isLoading = false;
    });
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationService.getUnreadCount();
    setState(() {
      _hasNotification = count > 0;
    });
  }

  // Load Dashboard Data from API
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Fetch dashboard stats (including unpaid bills)
      final dashboardResult = await DashboardService.getStats();
      
      // Fetch upcoming events
      final eventsResult = await EventService.getUpcomingEvents(limit: 5);
      
      // Fetch latest announcements
      final announcementsResult = await AnnouncementService.getLatestAnnouncements(limit: 5);
      
      // Fetch active banners
      final bannersResult = await BannerService.getActiveBanners();

      if (mounted) {
        setState(() {
          // Update tunggakan from API (include ALL bills with status)
          if (dashboardResult['success'] == true && dashboardResult['data'] != null) {
            final allBills = dashboardResult['data']['unpaid_bills']['bills'] as List;
            _tunggakan = allBills.map((bill) {
              return {
                'id': bill['id'],
                'bulan': '${bill['bulan']} ${bill['tahun']}', // Combine month + year
                'jumlah': bill['jumlah'],
                'terbayar': bill['terbayar'] ?? 0,
                'remaining': bill['remaining'] ?? bill['jumlah'],
                'status': bill['status'],
                'checked': false,
              };
            }).toList();
          }

          // Update events from API
          if (eventsResult['success'] == true && eventsResult['data'] != null) {
            _upcomingEvents = (eventsResult['data'] as List).map((event) {
              return event as Map<String, dynamic>;
            }).toList();
          }

          // Update announcements from API
          if (announcementsResult['success'] == true && announcementsResult['data'] != null) {
            _latestAnnouncements = (announcementsResult['data'] as List).map((announcement) {
              return announcement as Map<String, dynamic>;
            }).toList();
          }

          // Update banners from API
          if (bannersResult['success'] == true && bannersResult['data'] != null) {
            _banners = (bannersResult['data'] as List).map((banner) {
              return banner as Map<String, dynamic>;
            }).toList();
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Handle Pull to Refresh
  Future<void> _handleRefresh() async {
    try {
      // Reload user data
      await _loadUserData();
      
      // Reload notification count
      await _loadNotificationCount();
      
      // Reload dashboard data
      await _loadDashboardData();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diperbarui'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF16A085),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationName = 'Layanan Lokasi Tidak Aktif';
          _isLoadingLocation = false;
        });
        _showLocationError('Harap aktifkan layanan lokasi');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationName = 'Izin Lokasi Ditolak';
            _isLoadingLocation = false;
          });
          _showLocationError('Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationName = 'Izin Lokasi Ditolak Permanen';
          _isLoadingLocation = false;
        });
        _showLocationError('Harap aktifkan izin lokasi di pengaturan');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates (reverse geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationText = '';
        
        // Format lokasi: [Desa/Kelurahan], [Kecamatan], [Kota/Kabupaten]
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationText = place.subLocality!;
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          locationText = place.locality!;
        }
        
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          if (locationText.isNotEmpty) locationText += ', ';
          locationText += place.subAdministrativeArea!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (locationText.isNotEmpty) locationText += ', ';
          locationText += place.administrativeArea!;
        }

        setState(() {
          _locationName = locationText.isNotEmpty ? locationText : 'Lokasi Tidak Diketahui';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _locationName = 'Tidak Dapat Mendapatkan Lokasi';
        _isLoadingLocation = false;
      });
      _showLocationError('Gagal mendapatkan lokasi: ${e.toString()}');
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- SEARCH LOGIC ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query.length > 2) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      print('Performing search for: $query');
      final result = await SearchService.search(query);
      print('Search result received: $result');
      
      if (result['data'] != null) {
        final searchData = List<Map<String, dynamic>>.from(result['data']);
        print('Search data count: ${searchData.length}');
        setState(() {
          _searchResults = searchData;
        });
      } else {
        print('No data field in result');
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      // Handle error silently in UI
      print('Search error: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Load recent data untuk ditampilkan saat search kosong
  Future<void> _loadRecentData() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final result = await SearchService.getRecentData();
      if (result['data'] != null) {
        setState(() {
          _recentData = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      print('Error loading recent data: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
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
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: _buildDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          children: [
                  RefreshIndicator(
                    color: const Color(0xFF16A085),
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                  // Elegant Teal Background Container
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A085), // Elegant turquoise teal
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(33),
                        bottomRight: Radius.circular(33),
                      ),
                    ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                                const SizedBox(height: 20),

                                // Search Bar
                                _buildSearchBar(),

                              const SizedBox(height: 20),

                              // Category Pills
                              _buildCategories(),
                              
                              const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                          // Banner Carousel
                          _buildBannerCarousel(),
                          
                          const SizedBox(height: 24),
                          
                          // Tagihan SPP Banner
                          _buildSppBanner(),
                          
                          const SizedBox(height: 24),
                          
                          // Upcoming Section
                          _buildSection('Event & Ujian Mendatang', 'Lihat Semua'),
                          const SizedBox(height: 10),
                          _buildUpcomingCards(),
                          
                          const SizedBox(height: 24),
                          
                          // Nearby Section
                          _buildSection('Pengumuman Terbaru', 'Lihat Semua'),
                          const SizedBox(height: 10),
                          _buildNearbyCards(),

                          const SizedBox(height: 70), // Reduced from 80 to 70
                  ],
                ),
              ),
            ),

            // Bottom Navigation
                  _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: CustomHeader(
        scaffoldKey: _scaffoldKey,
        locationName: _locationName,
        isLoadingLocation: _isLoadingLocation,
        onLocationTap: _isLoadingLocation ? () {} : _getCurrentLocation,
        hasNotification: _hasNotification,
        onNotificationTap: () {
          // Navigate to notifications screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ).then((_) {
            // Reload notification count when coming back
            _loadNotificationCount();
          });
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        _showSearchBottomSheet();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 32.14,
      child: Row(
        children: [
              // Search Icon (Exact Figma: 24x24)
              const Icon(
                Icons.search,
                color: Colors.white,
              size: 24,
            ),
              
              const SizedBox(width: 10),
              
              // Vertical Line
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.3),
              ),

          const SizedBox(width: 12),

              // Search Text (Exact Figma)
          Expanded(
                child: Text(
                  'Cari...',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 20.33,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: -1,
                    height: 1.3,
                  ),
                ),
              ),
            
            // Filters Button
            GestureDetector(
              onTap: _showFilterBottomSheet,
              child: Container(
              height: 32.14,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
        children: [
                  // Custom Filter Icon - 3 lines decreasing
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A085).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Line 1 (longest)
                          Container(
                            width: 10,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A085),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                const SizedBox(height: 2),
                          // Line 2 (medium)
                          Container(
                            width: 7,
                            height: 1.5,
        decoration: BoxDecoration(
                              color: const Color(0xFF16A085),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Line 3 (shortest)
                          Container(
                            width: 4,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A085),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // "Filters" Text
                const Text(
                    'Filters',
                  style: TextStyle(
                    fontFamily: 'Lato',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF16A085),
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
    );
  }

  // Bottom Sheet untuk Filter
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Filter Berdasarkan',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2849),
                ),
              ),
            ),
            
            // Filter options
            _buildFilterOption('Semua', null),
            _buildFilterOption('Event', 'event'),
            _buildFilterOption('Pengumuman', 'announcement'),
            _buildFilterOption('Tagihan SPP', 'bill'),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterOption(String label, String? filterType) {
    final isSelected = _selectedFilter == filterType;
    
    return ListTile(
      leading: Icon(
        filterType == null ? Icons.grid_view : 
        filterType == 'event' ? Icons.event :
        filterType == 'announcement' ? Icons.campaign :
        Icons.payment,
        color: isSelected ? const Color(0xFF16A085) : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lato',
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFF16A085) : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF16A085)) : null,
      onTap: () {
        setState(() {
          _selectedFilter = filterType;
        });
        Navigator.pop(context);
        print('Filter applied: $filterType');
      },
    );
  }

  // Bottom Sheet untuk Search
  void _showSearchBottomSheet() {
    // Reset search state
    _searchController.clear();
    _searchResults = [];
    
    // Load recent data saat bottom sheet dibuka
    _loadRecentData();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Search TextField
          Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari event, pengumuman, atau tagihan...',
                    hintStyle: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF16A085),
                      size: 24,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              
              // Divider
              Divider(height: 1, color: Colors.grey[200]),
              
              // Search Results
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary05))
                    : _searchController.text.isEmpty
                        ? _buildSearchResultsList(controller, useRecentData: true)
                        : _searchResults.isEmpty
                            ? const Center(child: Text('Tidak ada hasil ditemukan'))
                            : _buildSearchResultsList(controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(ScrollController controller, {bool useRecentData = false}) {
    // Gunakan recent data jika search kosong, atau search results jika ada query
    var dataSource = useRecentData ? _recentData : _searchResults;
    
    // Apply filter if selected
    if (_selectedFilter != null) {
      dataSource = dataSource.where((item) => item['type'] == _selectedFilter).toList();
    }
    
    final events = dataSource.where((r) => r['type'] == 'event').toList();
    final announcements = dataSource.where((r) => r['type'] == 'announcement').toList();
    final bills = dataSource.where((r) => r['type'] == 'bill').toList();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        if (events.isNotEmpty)
          _buildSearchSection('Event Mendatang', events.map((item) => _buildSearchResultItem(
            icon: Icons.event,
            iconColor: const Color(0xFF6C63FF),
            title: item['text'],
            subtitle: 'Ketuk untuk melihat detail',
            onTap: () {
              Navigator.pop(context); // Close search
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(eventId: item['id']),
                ),
              );
            },
          )).toList()),
        if (announcements.isNotEmpty)
          _buildSearchSection('Pengumuman', announcements.map((item) => _buildSearchResultItem(
            icon: Icons.campaign,
            iconColor: const Color(0xFFFFC107),
            title: item['text'],
            subtitle: 'Ketuk untuk melihat detail',
            onTap: () {
              Navigator.pop(context); // Close search
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnouncementDetailScreen(announcementId: item['id']),
                ),
              );
            },
          )).toList()),
        if (bills.isNotEmpty)
          _buildSearchSection('Tagihan SPP', bills.map((item) => _buildSearchResultItem(
            icon: Icons.payment,
            iconColor: const Color(0xFF16A085),
            title: item['text'],
            subtitle: 'Ketuk untuk melihat detail',
            onTap: () {
              Navigator.pop(context); // Close search
              Navigator.pushNamed(context, '/billing');
            },
          )).toList()),
      ],
    );
  }

  Widget _buildSearchSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildSearchResultItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
              Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'label': 'Antrian', 'color': const Color(0xFFFF6B9D), 'icon': Icons.confirmation_number_outlined},
      {'label': 'Tagihan', 'color': const Color(0xFFFFC107), 'icon': Icons.receipt_long_outlined},
      {'label': 'Riwayat', 'color': const Color(0xFF00BCD4), 'icon': Icons.history},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == categories.length - 1 ? 0 : 6,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (cat['label'] == 'Antrian') {
                      Navigator.pushNamed(context, '/queue');
                    } else if (cat['label'] == 'Tagihan') {
                      Navigator.pushNamed(context, '/billing');
                    } else if (cat['label'] == 'Riwayat') {
                      Navigator.pushNamed(context, '/history');
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (cat['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              cat['label'] as String,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection(String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF120D26).withOpacity(0.84),
              height: 1.89,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate based on section title
              if (title == 'Event & Ujian Mendatang') {
                Navigator.pushNamed(context, '/events');
              } else if (title == 'Pengumuman Terbaru') {
                Navigator.pushNamed(context, '/announcements');
              }
            },
            child: Row(
      children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF747688),
                  height: 1.64,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 9,
                color: const Color(0xFF747688).withOpacity(0.5),
              ),
            ],
          ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCards() {
    // Use API data if available, otherwise show loading or empty state
    if (_isLoadingData) {
      return const SizedBox(
        height: 255,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16A085),
          ),
        ),
      );
    }

    if (_upcomingEvents.isEmpty) {
      return SizedBox(
        height: 255,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
      children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada event mendatang',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _upcomingEvents.length,
        itemBuilder: (context, index) {
          final event = _upcomingEvents[index];
          
          // Get event image - priority: database URL > local default
          String getEventImageLocal(String? category) {
            switch (category) {
              case 'ujian':
                return 'assets/images/event_exam.jpg';
              case 'olahraga':
                return 'assets/images/event_sports.jpg';
              case 'ekskul':
                return 'assets/images/event_extracurricular.jpg';
              default:
                return 'assets/images/event_general.jpg';
            }
          }
          
          bool hasImageFromDatabase(dynamic image) {
            return image != null && 
                   image.toString().isNotEmpty && 
                   (image.toString().startsWith('http') || image.toString().startsWith('/storage'));
          }
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(eventId: event['id']),
                ),
              );
            },
            child: Container(
              width: 280,
              margin: EdgeInsets.only(right: index == _upcomingEvents.length - 1 ? 0 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF505588).withOpacity(0.06),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with Hero animation
                      Hero(
                        tag: 'event_image_${event['id']}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: hasImageFromDatabase(event['image'])
                              ? Image.network(
                                  event['image'].toString().startsWith('http')
                                      ? event['image']
                                      : 'http://localhost:8000${event['image']}',
                                  width: 280,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      getEventImageLocal(event['category']),
                                      width: 280,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  getEventImageLocal(event['category']),
                                  width: 280,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 280,
                                      height: 180,
                                      color: const Color(0xFF16A085).withOpacity(0.1),
                                      child: const Icon(Icons.event, size: 48, color: Color(0xFF16A085)),
                                    );
                                  },
                                ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title']! as String,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2849),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Avatars stack
                                SizedBox(
                                  width: 56,
                                  height: 24,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary04,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.person, size: 12, color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        left: 16,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary06,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.person, size: 12, color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        left: 32,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary02,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.person, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${event['participants_count'] ?? 0} Siswa',
                                  style: const TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3F38DD),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: const Color(0xFF2B2849).withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event['location']! as String,
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF2B2849).withOpacity(0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Date Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event['formatted_date']?['date'] ?? '??',
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEB5757),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event['formatted_date']?['month'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEB5757),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyCards() {
    // Use API data if available, otherwise show loading or empty state
    if (_isLoadingData) {
      return const SizedBox(
        height: 255,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16A085),
          ),
        ),
      );
    }

    if (_latestAnnouncements.isEmpty) {
      return SizedBox(
        height: 255,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada pengumuman terbaru',
                style: TextStyle(
              fontFamily: 'Lato',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _latestAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = _latestAnnouncements[index];
          
          // Get announcement image - priority: database URL > local default
          String getAnnouncementImageLocal(String? category) {
            switch (category) {
              case 'libur':
                return 'assets/images/announcement_holiday.jpg';
              case 'ekstrakurikuler':
                return 'assets/images/event_extracurricular.jpg';
              default:
                return 'assets/images/announcement_general.jpg';
            }
          }
          
          bool hasAnnouncementImageFromDatabase(dynamic image) {
            return image != null && 
                   image.toString().isNotEmpty && 
                   (image.toString().startsWith('http') || image.toString().startsWith('/storage'));
          }
          
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnnouncementDetailScreen(announcementId: announcement['id']),
          ),
        );
      },
      child: Container(
            width: 280,
            margin: EdgeInsets.only(right: index == _latestAnnouncements.length - 1 ? 0 : 16),
      decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
                  color: const Color(0xFF505588).withOpacity(0.06),
                  blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image - 1:1 square (from database or local)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: hasAnnouncementImageFromDatabase(announcement['image'])
                        ? Image.network(
                            announcement['image'].toString().startsWith('http')
                              ? announcement['image']
                              : 'http://localhost:8000${announcement['image']}',
                            width: 280,
                            height: 180,
                fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to local if network fails
                              return Image.asset(
                                getAnnouncementImageLocal(announcement['category']),
                                width: 280,
                                height: 180,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            getAnnouncementImageLocal(announcement['category']),
                            width: 280,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 280,
                                height: 180,
                                color: const Color(0xFFFFB74D).withOpacity(0.2),
                                child: const Icon(Icons.campaign, size: 48, color: Color(0xFFFFB74D)),
                              );
                            },
                          ),
                    ),
          // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                            Text(
                              announcement['title']! as String,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF120D26),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  announcement['is_important'] == true 
                                    ? Icons.priority_high 
                                    : Icons.info_outline,
                                  size: 14,
                                  color: announcement['is_important'] == true
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF2B2849).withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    announcement['category'] == 'libur' 
                                      ? 'Libur Nasional'
                                      : announcement['category'] == 'ekstrakurikuler'
                                        ? 'Ekstrakurikuler'
                                        : 'Pengumuman Umum',
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF2B2849).withOpacity(0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                                color: AppColors.primary04.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                  ),
                              child: Text(
                                announcement['formatted_date'] ?? announcement['publish_date'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primary04,
                    ),
                  ),
                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
          );
        },
      ),
    );
  }

  Widget _buildBannerCarousel() {
    if (_isLoadingData) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16A085),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink(); // Hide if no banners
    }

    // Get banner image - priority: database URL > local default
    String getBannerImageLocal(String? imageKey) {
      switch (imageKey) {
        case 'banner_welcome':
          return 'assets/images/banner_welcome.jpg';
        case 'banner_promo':
          return 'assets/images/banner_promo.jpg';
        case 'banner_queue':
          return 'assets/images/banner_queue.jpg';
        default:
          return 'assets/images/banner_welcome.jpg';
      }
    }
    
    bool hasBannerImageFromDatabase(dynamic image) {
      return image != null && 
             image.toString().isNotEmpty && 
             (image.toString().startsWith('http') || image.toString().startsWith('/storage'));
    }

    return Column(
      children: [
        // Banner Carousel
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Image (from database or local)
                      hasBannerImageFromDatabase(banner['image'])
                        ? Image.network(
                            banner['image'].toString().startsWith('http')
                              ? banner['image']
                              : 'http://localhost:8000${banner['image']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to local if network fails
                              return Image.asset(
                                getBannerImageLocal(banner['image']),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error2, stackTrace2) {
                                  return Container(
                                    color: const Color(0xFF16A085).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Color(0xFF16A085),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : Image.asset(
                            getBannerImageLocal(banner['image']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF16A085).withOpacity(0.1),
                                child: const Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Color(0xFF16A085),
                                ),
                              );
                            },
                          ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Text Content
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['title'] ?? '',
                              style: const TextStyle(
                    fontFamily: 'Lato',
                                fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (banner['description'] != null) ...[
                              const SizedBox(height: 4),
                Text(
                                banner['description'],
                  style: TextStyle(
                    fontFamily: 'Lato',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Indicator Dots
        if (_banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentBannerIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index
                      ? const Color(0xFF16A085)
                      : const Color(0xFF16A085).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSppBanner() {
    // Calculate statistics
    const int totalBillsInYear = 12; // Fixed: 12 months in a year
    final paidBills = _tunggakan.where((item) => 
      item['status'] == 'paid' || item['status'] == 'lunas'
    ).toList();
    // Unpaid includes both 'unpaid' and 'partial' status
    final unpaidBills = _tunggakan.where((item) => 
      item['status'] != 'paid' && item['status'] != 'lunas'
    ).toList();
    
    final paidCount = paidBills.length;
    final unpaidCount = unpaidBills.length;
    final totalPaid = paidBills.fold(0, (sum, item) => sum + (item['jumlah'] as int));
    // Use 'remaining' for unpaid/partial bills to show actual amount still owed
    final totalUnpaid = unpaidBills.fold(0, (sum, item) => sum + ((item['remaining'] ?? item['jumlah']) as int));
    final percentage = (paidCount / totalBillsInYear * 100).toInt(); // Calculate from 12 months
    
    // Get current time WIB
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB = UTC+7
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    
    // Selected bills for payment - use remaining for partial payments
    int selectedTotal = unpaidBills.where((item) => item['checked'] == true).fold(0, (sum, item) => sum + ((item['remaining'] ?? item['jumlah']) as int));
    int selectedCount = unpaidBills.where((item) => item['checked'] == true).length;
    
    // Always show banner (even if all paid), hide only if no data
    if (_tunggakan.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        // Main Card - Summary
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with icon and expand button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: percentage >= 100 
                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                        : (percentage >= 50 
                          ? const Color(0xFF16A085).withOpacity(0.15)
                          : const Color(0xFFFFC107).withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      percentage >= 100 
                        ? Icons.check_circle
                        : (percentage >= 50 
                          ? Icons.account_balance_wallet
                          : Icons.warning_amber_rounded),
                      color: percentage >= 100 
                        ? const Color(0xFF4CAF50)
                        : (percentage >= 50 
                          ? const Color(0xFF16A085)
                          : const Color(0xFFFFC107)),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Pembayaran SPP',
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF747688),
                          ),
                        ),
                        Text(
                          'Sudah Lunas: $paidCount dari $totalBillsInYear Bulan',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF120D26),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: percentage >= 100 
                            ? const Color(0xFF4CAF50)
                            : (percentage >= 50 
                              ? const Color(0xFF16A085)
                              : const Color(0xFFE53935)),
                        ),
                      ),
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF747688),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE8E8E8),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 100 
                          ? const Color(0xFF4CAF50)
                          : (percentage >= 50 
                            ? const Color(0xFF16A085)
                            : const Color(0xFFE53935)),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              // Divider
              Container(
                height: 1,
                color: const Color(0xFFE8E8E8),
              ),
              const SizedBox(height: 16),
              
              // Summary Stats
              Row(
                children: [
                  // Sudah Bayar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sudah Bayar',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF747688),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${totalPaid.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          '$paidCount bulan',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF747688),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Vertical divider
                  Container(
                    width: 1,
                    height: 50,
                    color: const Color(0xFFE8E8E8),
                  ),
                  
                  // Kurang
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Kurang',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF747688),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rp ${totalUnpaid.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              Text(
                                '$unpaidCount bulan',
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF747688),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return CustomBottomNav(
      selectedIndex: _selectedIndex,
      onItemTapped: (index) {
        if (index == 1) {
          // Navigate to Information screen
          Navigator.pushNamed(context, '/information');
        } else if (index == 3) {
          // Navigate to Billing screen
          Navigator.pushNamed(context, '/billing');
        } else if (index == 4) {
          // Navigate to Profile screen
          Navigator.pushNamed(context, '/profile');
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }

  // Helper for coming soon dialog
  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$featureName Segera Hadir',
          style: const TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Fitur ini sedang dalam tahap pengembangan. Nantikan update selanjutnya!',
          style: TextStyle(fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // Helper for about dialog (Modern Bottom Sheet)
  void _showAboutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 2. Modern Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A085).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: Color(0xFF16A085),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SPP Sekolah',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v1.0.0 Beta',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 3. Info List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'INFORMASI',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAboutListItem(
                    icon: Icons.code,
                    title: 'Developer',
                    value: 'Team IT',
                  ),
                  _buildAboutListItem(
                    icon: Icons.calendar_today,
                    title: 'Tahun Rilis',
                    value: '2025',
                  ),
                  _buildAboutListItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Lisensi',
                    value: 'Free Version',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'KONTAK & SUPPORT',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAboutListItem(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    value: 'support@sekolah.sch.id',
                    isLink: true,
                  ),
                  _buildAboutListItem(
                    icon: Icons.language,
                    title: 'Website',
                    value: 'www.sekolah.sch.id',
                    isLink: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Description Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: const Text(
                      'Aplikasi ini dirancang untuk memudahkan manajemen pembayaran SPP dan distribusi informasi akademik di SMK Taruna Jaya Prawira Tuban.',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13,
                        color: Color(0xFF636E72),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A085),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutListItem({
    required IconData icon,
    required String title,
    required String value,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF16A085)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isLink ? const Color(0xFF16A085) : const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
          if (isLink)
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header dengan warna teal subtle
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF16A085),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Profile Photo - Visible on teal background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _profilePhotoPath != null && File(_profilePhotoPath!).existsSync()
                      ? ClipOval(
                          child: Image.file(
                            File(_profilePhotoPath!),
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: const Color(0xFF16A085),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  _currentUser?.name ?? 'Siswa',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  _currentUser?.email ?? '',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),

            // Menu Items - Simple list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Profil Saya',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment,
                    title: 'Riwayat Pembayaran',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.event_note,
                    title: 'Event & Ujian',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/information');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    badge: _hasNotification ? '•' : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ).then((_) {
                        _loadNotificationCount();
                      });
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog('Pengaturan');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Bantuan',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog('Bantuan');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'Tentang',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Keluar',
                    iconColor: const Color(0xFFE74C3C),
                    textColor: const Color(0xFFE74C3C),
                    onTap: () => _handleSignOut(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Handle Sign Out with confirmation
  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar dari Akun?',
              style: TextStyle(
                fontFamily: 'Lato',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Lato',
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
              ),
              ),
            ),
          ],
      ),
    );

    if (confirm == true) {
      // Close drawer first
      Navigator.pop(context);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
          ),
        ),
      );

      try {
        // Call logout API
        await AuthService.logout();
        
        // Clear local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        // Navigate to signin screen and clear all routes
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/signin',
            (route) => false,
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal keluar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final defaultIconColor = const Color(0xFF16A085);
    final defaultTextColor = const Color(0xFF2C3E50);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor ?? defaultIconColor,
            ),
            // Red dot badge on icon
            if (badge != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4444).withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Lato',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? defaultTextColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: Colors.grey[400],
      ),
    );
  }
}
