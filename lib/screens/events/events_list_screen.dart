import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:tugas_sekolah/screens/events/event_detail_screen.dart';
import 'package:tugas_sekolah/services/event_service.dart';
import '../../config/api_config.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({Key? key}) : super(key: key);

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await EventService.getAllEvents();
      if (result['success'] == true && result['data'] is List) {
        final events = List<Map<String, dynamic>>.from(result['data']);
        setState(() {
          _events = events;
          _filteredEvents = events;
          _isLoading = false;
        });
      } else {
        throw Exception(result['message'] ?? 'Data event tidak valid');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Handle error, e.g., show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat event: $e')),
        );
      });
    }
    
    _fadeController.forward();
  }

  void _filterEvents() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredEvents = _events.where((event) {
        bool matchesCategory = _selectedCategory == 'all' || event['category'] == _selectedCategory;
        bool matchesSearch = event['title'].toString().toLowerCase().contains(query) ||
                           event['location'].toString().toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _filterEvents();
    });
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
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryTabs(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF16A085),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF16A085),
                        onRefresh: _loadEvents,
                        child: _filteredEvents.isEmpty
                            ? _buildEmptyState()
                            : FadeTransition(
                                opacity: _fadeController,
                                child: MasonryGridView.count(
                                  padding: const EdgeInsets.all(16),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  itemCount: _filteredEvents.length,
                                  itemBuilder: (context, index) {
                                    return _buildEventCard(_filteredEvents[index], index);
                                  },
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF2B2849),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Event & Ujian',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2849),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8EAED),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            color: Color(0xFF2B2849),
          ),
          decoration: InputDecoration(
            hintText: 'Cari event atau lokasi...',
            hintStyle: TextStyle(
              fontFamily: 'Lato',
              fontSize: 14,
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[500],
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'all', 'label': 'Semua', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF16A085)},
      {'id': 'ujian', 'label': 'Ujian', 'icon': Icons.quiz_rounded, 'color': const Color(0xFFE74C3C)},
      {'id': 'olahraga', 'label': 'Olahraga', 'icon': Icons.sports_soccer_rounded, 'color': const Color(0xFF3498DB)},
      {'id': 'ekskul', 'label': 'Ekskul', 'icon': Icons.palette_rounded, 'color': const Color(0xFF9B59B6)},
    ];

    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];
          final color = category['color'] as Color;

          return GestureDetector(
            onTap: () => _onCategoryChanged(category['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE8EAED),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF2B2849),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada event',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
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

    final Color categoryColor;
    final IconData categoryIcon;
    final String categoryLabel;
    
    switch (event['category']) {
      case 'ujian':
        categoryColor = const Color(0xFFE74C3C);
        categoryIcon = Icons.quiz_rounded;
        categoryLabel = 'UJIAN';
        break;
      case 'olahraga':
        categoryColor = const Color(0xFF3498DB);
        categoryIcon = Icons.sports_soccer_rounded;
        categoryLabel = 'OLAHRAGA';
        break;
      case 'ekskul':
        categoryColor = const Color(0xFF9B59B6);
        categoryIcon = Icons.palette_rounded;
        categoryLabel = 'EKSKUL';
        break;
      default:
        categoryColor = const Color(0xFF16A085);
        categoryIcon = Icons.event_rounded;
        categoryLabel = 'LAINNYA';
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  builder: (context) => EventDetailScreen(eventId: event['id']),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image with overlay
                SizedBox(
                  height: 160,
                  child: Hero(
                    tag: 'event_image_${event['id']}',
                    child: Stack(
                      children: [
                        // Event Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: hasImageFromDatabase(event['image'])
                              ? Image.network(
                                  '${ApiConfig.baseUrl}${event['image']}',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      getEventImageLocal(event['category']),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  getEventImageLocal(event['category']),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        
                        // Category Icon (Top Right)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withOpacity(0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              categoryIcon,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Date (Bottom Left)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 10,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event['date'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: categoryColor,
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
                  ),
                ),
                
                // Event Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Title
                        Text(
                          event['title'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B2849),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 11,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event['location'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Participants
                        if (event['participants_count'] != null && event['participants_count'] > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 11,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${event['participants_count']}',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: categoryColor,
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
        ),
      ),
    );
  }
}

