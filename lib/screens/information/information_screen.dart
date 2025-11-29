import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/event_service.dart';
import '../../services/announcement_service.dart';
import '../events/event_detail_screen.dart';
import '../announcements/announcement_detail_screen.dart';
import 'package:intl/intl.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({Key? key}) : super(key: key);

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Events data
  List<Map<String, dynamic>> _events = [];
  bool _isLoadingEvents = true;
  
  // Announcements data
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final result = await EventService.getAllEvents();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(result['data']);
          _isLoadingEvents = false;
        });
      } else {
        setState(() => _isLoadingEvents = false);
      }
    } catch (e) {
      setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      print('📢 Loading announcements...');
      final result = await AnnouncementService.getAllAnnouncements();
      print('📢 Announcement result: $result');
      if (result['success'] == true && result['data'] != null) {
        final announcements = List<Map<String, dynamic>>.from(result['data']);
        print('📢 Found ${announcements.length} announcements');
        setState(() {
          _announcements = announcements;
          _isLoadingAnnouncements = false;
        });
      } else {
        print('📢 No announcements or failed: ${result['message']}');
        setState(() => _isLoadingAnnouncements = false);
      }
    } catch (e) {
      print('📢 Error loading announcements: $e');
      setState(() => _isLoadingAnnouncements = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary05,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Informasi Sekolah',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: innerBoxIsScrolled ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary05,
                            AppColors.primary05.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Tagline text
                    Positioned(
                      bottom: 80,
                      left: 24,
                      right: 24,
                      child: Column(
                        children: [
                          Text(
                            'Tetap Update!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jangan lewatkan informasi penting sekolah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary05,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: AppColors.primary05,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 20),
                            const SizedBox(width: 8),
                            Text('Event'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign, size: 20),
                            const SizedBox(width: 8),
                            Text('Pengumuman'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsTab(),
            _buildAnnouncementsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_isLoadingEvents) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary05),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada event',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppColors.primary05,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) => _buildEventCard(_events[index]),
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    if (_isLoadingAnnouncements) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary05),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada pengumuman',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      color: AppColors.primary05,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) => _buildAnnouncementCard(_announcements[index]),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    String formatDate(String? dateStr) {
      if (dateStr == null) return '';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      } catch (e) {
        return dateStr;
      }
    }
    
    String getEventImage(String? category) {
      switch (category) {
        case 'ujian': return 'assets/images/event_exam.jpg';
        case 'olahraga': return 'assets/images/event_sports.jpg';
        case 'ekstrakurikuler': return 'assets/images/event_extracurricular.jpg';
        default: return 'assets/images/event_general.jpg';
      }
    }
    
    bool hasImageFromDatabase(dynamic image) {
      return image != null && 
             image.toString().isNotEmpty && 
             image != 'null' &&
             (image.toString().startsWith('http') || image.toString().startsWith('/storage'));
    }

    return Hero(
      tag: 'event_${event['id']}',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event['id']),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary05.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Image
                hasImageFromDatabase(event['image'])
                  ? Image.network(
                      event['image'].toString().startsWith('http')
                        ? event['image']
                        : 'http://192.168.1.8:8000${event['image']}',
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          getEventImage(event['category']),
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      getEventImage(event['category']),
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                // Gradient Overlay
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Category Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary05,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary05.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          event['category'] ?? 'Event',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content at Bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? 'Tanpa Judul',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal Event',
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatDate(event['event_date']),
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (event['location'] != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi',
                                      style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      event['location'],
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    String formatDate(String? dateStr) {
      if (dateStr == null) return '';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      } catch (e) {
        return dateStr;
      }
    }
    
    String getAnnouncementImage(String? category) {
      switch (category) {
        case 'libur': return 'assets/images/announcement_holiday.jpg';
        case 'ekstrakurikuler': return 'assets/images/event_extracurricular.jpg';
        default: return 'assets/images/announcement_general.jpg';
      }
    }
    
    bool hasImageFromDatabase(dynamic image) {
      return image != null && 
             image.toString().isNotEmpty && 
             image != 'null' &&
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF505588).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: hasImageFromDatabase(announcement['image'])
                ? Image.network(
                    announcement['image'].toString().startsWith('http')
                      ? announcement['image']
                      : 'http://192.168.1.8:8000${announcement['image']}',
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        getAnnouncementImage(announcement['category']),
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    getAnnouncementImage(announcement['category']),
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.campaign, size: 14, color: Color(0xFFFFC107)),
                              const SizedBox(width: 4),
                              Text(
                                announcement['category'] ?? 'Umum',
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (announcement['is_important'] == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE74C3C).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.priority_high, size: 12, color: Color(0xFFE74C3C)),
                                const SizedBox(width: 2),
                                const Text(
                                  'PENTING',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE74C3C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      announcement['title'] ?? 'Tanpa Judul',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2849),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement['content'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(announcement['publish_date']),
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
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
