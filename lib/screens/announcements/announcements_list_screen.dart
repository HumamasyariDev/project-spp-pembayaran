import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import 'package:tugas_sekolah/screens/announcements/announcement_detail_screen.dart';
import '../../services/announcement_service.dart';

class AnnouncementsListScreen extends StatefulWidget {
  const AnnouncementsListScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _filteredAnnouncements = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _searchController.addListener(_filterAnnouncements);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final result = await AnnouncementService.getLatestAnnouncements();
      if (mounted && result['success'] == true && result['data'] is List) {
        final announcements = List<Map<String, dynamic>>.from(result['data']);
        setState(() {
          _announcements = announcements;
          _filterAnnouncements();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAnnouncements() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredAnnouncements = _announcements.where((announcement) {
        bool matchesCategory = _selectedCategory == 'all' || announcement['category'] == _selectedCategory;
        bool matchesSearch = announcement['title'].toString().toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _filterAnnouncements();
    });
  }
  
  String getAnnouncementImageLocal(String? category) {
    switch (category) {
      case 'libur': return 'assets/images/announcement_holiday.jpg';
      case 'ekstrakurikuler': return 'assets/images/event_extracurricular.jpg';
      default: return 'assets/images/announcement_general.jpg';
    }
  }

  bool hasImageFromDatabase(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null';
  }

  String buildImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    final uri = Uri.parse(ApiConfig.baseUrl);
    final storageBaseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
    return '$storageBaseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          onRefresh: _loadAnnouncements,
          color: const Color(0xFF16A085),
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              _buildSliverPersistentHeader(),
              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF16A085))))
                  : _filteredAnnouncements.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : _buildAnnouncementsList(),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      pinned: true,
      floating: true,
      elevation: 0.5,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: const Text(
        'Pengumuman',
        style: TextStyle(fontFamily: 'Lato', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2B2849)),
      ),
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF2B2849)),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: _buildSearchBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontFamily: 'Lato', fontSize: 14, color: Color(0xFF2B2849)),
        decoration: InputDecoration(
          hintText: 'Cari pengumuman...',
          hintStyle: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500], size: 20),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  SliverPersistentHeader _buildSliverPersistentHeader() {
    return SliverPersistentHeader(
      delegate: _SliverHeaderDelegate(
        child: _buildCategoryTabs(),
        height: 50,
      ),
      pinned: true,
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'all', 'label': 'Semua'},
      {'id': 'pengumuman_umum', 'label': 'Umum'},
      {'id': 'ekstrakurikuler', 'label': 'Ekskul'},
      {'id': 'libur', 'label': 'Libur'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];
          return GestureDetector(
            onTap: () => _onCategoryChanged(category['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF16A085) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF16A085) : Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  category['label'] as String,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF2B2849),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final announcement = _filteredAnnouncements[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAnnouncementCard(announcement, index),
            );
          },
          childCount: _filteredAnnouncements.length,
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: Opacity(opacity: scale, child: child));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnouncementDetailScreen(announcementId: announcement['id']),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardImage(announcement),
                  const SizedBox(width: 12),
                  _buildCardContent(announcement),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(Map<String, dynamic> announcement) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: const Color(0xFF16A085).withOpacity(0.1),
        child: hasImageFromDatabase(announcement['image'])
            ? Image.network(
                buildImageUrl(announcement['image']),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, color: Color(0xFF16A085)),
              )
            : Image.asset(
                getAnnouncementImageLocal(announcement['category']),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.campaign, color: Color(0xFF16A085)),
              ),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> announcement) {
    final bool isImportant = announcement['is_important'] == true;
    final String formattedDate = _formatDate(announcement['publish_date']);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImportant) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.priority_high_rounded, color: Colors.red, size: 12),
                  SizedBox(width: 4),
                  Text('PENTING', style: TextStyle(fontFamily: 'Lato', color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            announcement['title'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Lato', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2B2849)),
          ),
          const SizedBox(height: 4),
          Text(
            announcement['content'] ?? '',
            maxLines: isImportant ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(fontFamily: 'Lato', fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF16A085).withOpacity(0.1),
                  const Color(0xFF1ABC9C).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              size: 50,
              color: Color(0xFF16A085),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada pengumuman',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2849),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengumuman akan muncul di sini',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes} menit yang lalu';
        }
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari yang lalu';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

// Helper delegate for SliverPersistentHeader
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _SliverHeaderDelegate({required this.child, required this.height});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: child);
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}
