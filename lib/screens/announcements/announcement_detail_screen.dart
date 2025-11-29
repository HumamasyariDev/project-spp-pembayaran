import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tugas_sekolah/services/announcement_service.dart';
import '../../config/api_config.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final int announcementId;

  const AnnouncementDetailScreen({Key? key, required this.announcementId}) : super(key: key);

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  Map<String, dynamic>? _announcement;
  bool _isLoading = true;
  String? _errorMessage;
  late Future<List<Map<String, dynamic>>> _otherAnnouncementsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncementDetails();
    _loadOtherAnnouncements();
  }
  
  Future<void> _fetchAnnouncementDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AnnouncementService.getAnnouncementDetail(widget.announcementId);
      print('📢 Announcement Detail Result: $result');
      if (result['success'] == true && result['data'] != null) {
        print('📷 Image URL: ${result['data']['image']}');
        setState(() {
          _announcement = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat detail pengumuman';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  void _loadOtherAnnouncements() {
    _otherAnnouncementsFuture = _fetchOtherAnnouncements();
  }

  Future<List<Map<String, dynamic>>> _fetchOtherAnnouncements() async {
    try {
      final result = await AnnouncementService.getOtherAnnouncements(widget.announcementId);
      if (result['success'] == true && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  IconData getCategoryIcon(String? category) {
    switch (category) {
      case 'libur': return Icons.event_available_rounded;
      case 'ekstrakurikuler': return Icons.palette_rounded;
      default: return Icons.campaign_rounded;
    }
  }
  
  Color getCategoryColor(String? category) {
     switch (category) {
      case 'libur': return const Color(0xFFE74C3C);
      case 'ekstrakurikuler': return const Color(0xFF9B59B6);
      default: return const Color(0xFF3498DB);
    }
  }

  bool hasImageFromDatabase(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null';
  }

  String buildImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final uri = Uri.parse(ApiConfig.baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A085)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAnnouncementDetails,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroImageHeader(),
                      _buildContentBody(),
                      _buildOtherAnnouncements(context),
                      const SizedBox(height: 100), // Space for CTA button
                    ],
                  ),
                ),
      bottomNavigationBar: _isLoading || _errorMessage != null ? null : _buildShareButton(context),
    );
  }

  Widget _buildHeroImageHeader() {
    final imageUrl = _announcement!['image'];
    final hasImage = hasImageFromDatabase(imageUrl);
    final categoryColor = getCategoryColor(_announcement!['category']);
    final categoryIcon = getCategoryIcon(_announcement!['category']);
    final String categoryLabel = _announcement!['category'] == 'libur' ? 'LIBUR' 
        : _announcement!['category'] == 'ekstrakurikuler' ? 'EKSKUL' 
        : 'UMUM';
    final bool isImportant = _announcement!['is_important'] == true;
    
    return Stack(
      children: [
        // Hero Image
        Container(
          height: 380,
          width: double.infinity,
          child: hasImage
              ? Image.network(
                  buildImageUrl(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildLocalImageFallback();
                  },
                )
              : _buildLocalImageFallback(),
        ),
        // Gradient Overlay
        Container(
          height: 380,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        // Content Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            categoryLabel,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isImportant) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE74C3C).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.priority_high, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'PENTING',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  _announcement!['title'] ?? 'Tanpa Judul',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(_announcement!['publish_date'])),
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocalImageFallback() {
    final category = _announcement!['category'];
    String getAnnouncementImageLocal(String? category) {
      switch (category) {
        case 'libur': return 'assets/images/announcement_holiday.jpg';
        case 'ekstrakurikuler': return 'assets/images/event_extracurricular.jpg'; // Use event image as fallback
        default: return 'assets/images/announcement_general.jpg';
      }
    }
    
    return Image.asset(
      getAnnouncementImageLocal(category),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // If local asset also fails, show icon fallback
        return _buildFallbackHeader();
      },
    );
  }
  
  Widget _buildFallbackHeader() {
    final categoryColor = getCategoryColor(_announcement!['category']);
    return Container(
      decoration: BoxDecoration(color: categoryColor.withOpacity(0.1)),
      child: Center(
        child: Icon(getCategoryIcon(_announcement!['category']), color: categoryColor, size: 60),
      ),
    );
  }

  Widget _buildContentBody() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF505588).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A085).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article,
                  color: Color(0xFF16A085),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Isi Pengumuman',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2849),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _announcement!['content'] ?? 'Tidak ada deskripsi.',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'Lato', color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(children: [
      Icon(icon, color: Colors.grey[600], size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontFamily: 'Lato', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2B2849))),
          ],
        ),
      ),
    ]);
  }

  Widget _buildShareButton(BuildContext context) {
    final String title = _announcement!['title'] ?? 'Pengumuman';
    final String content = _announcement!['content'] ?? 'Lihat selengkapnya di aplikasi sekolah.';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Share.share('PENGUMUMAN PENTING:\n\n*$title*\n\n$content');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A085),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: const Color(0xFF16A085).withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.share, size: 22),
            SizedBox(width: 12),
            Text(
              'Bagikan Pengumuman',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherAnnouncements(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _otherAnnouncementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF16A085)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final otherAnnouncements = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Pengumuman Lainnya', style: TextStyle(fontFamily: 'Lato', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2B2849))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: otherAnnouncements.length,
                padding: const EdgeInsets.only(left: 20),
                itemBuilder: (context, index) => _buildOtherAnnouncementCard(otherAnnouncements[index]),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildOtherAnnouncementImage(String? category) {
    print('🎨 Building other announcement image for category: $category');
    
    String getAnnouncementImageLocal(String? category) {
      switch (category) {
        case 'libur': return 'assets/images/announcement_holiday.jpg';
        case 'ekstrakurikuler': return 'assets/images/event_extracurricular.jpg'; // Use event image as fallback
        default: 
          print('⚠️ Using default image for category: $category');
          return 'assets/images/announcement_general.jpg';
      }
    }
    
    final imagePath = getAnnouncementImageLocal(category);
    print('📁 Image path: $imagePath');
    
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Failed to load image: $imagePath, error: $error');
        // If local asset also fails, show icon fallback
        return Container(
          color: getCategoryColor(category).withOpacity(0.1),
          child: Icon(getCategoryIcon(category), color: getCategoryColor(category), size: 30),
        );
      },
    );
  }
  
  Widget _buildOtherAnnouncementCard(Map<String, dynamic> otherAnnouncement) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AnnouncementDetailScreen(announcementId: otherAnnouncement['id'])),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: double.infinity,
                child: hasImageFromDatabase(otherAnnouncement['image'])
                  ? Image.network(
                      buildImageUrl(otherAnnouncement['image']), 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to local image if network fails
                        return _buildOtherAnnouncementImage(otherAnnouncement['category']);
                      },
                    )
                  : _buildOtherAnnouncementImage(otherAnnouncement['category']),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      otherAnnouncement['title'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(otherAnnouncement['publish_date'])),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
