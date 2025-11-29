import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tugas_sekolah/config/api_config.dart';
import 'package:tugas_sekolah/services/event_service.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  String? _error;
  Future<List<Map<String, dynamic>>>? _similarEventsFuture;
  bool _isReminding = false;
  bool _reminderSet = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    try {
      final result = await EventService.getEventDetail(widget.eventId);
      if (result['success'] == true && result['data'] != null) {
        if (mounted) {
          setState(() {
            _event = result['data'];
            _isLoading = false;
          });
          _loadSimilarEvents();
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to load event details');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _loadSimilarEvents() {
    if (_event == null) return;
    setState(() {
      _similarEventsFuture = _fetchSimilarEvents();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSimilarEvents() async {
    if (_event == null) return [];
    try {
      final result = await EventService.getSimilarEvents(_event!['id']);
      if (result['success'] == true && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Robust Parsing Utilities ---
  String _parseAndFormatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final dateString = dateStr.trim();
    
    final formats = [
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'MM/dd/yyyy',
      'yyyy/MM/dd',
    ];

    for (var format in formats) {
      try {
        final parsedDate = DateFormat(format).parse(dateString);
        return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(parsedDate);
      } catch (_) {}
    }

    try {
      final parsedDate = DateTime.parse(dateString); // ISO 8601
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(parsedDate);
    } catch (_) {}

    print('Could not parse date: $dateString');
    return dateString; // Fallback
  }

  String _parseAndFormatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    final timeString = timeStr.trim();

    try {
      DateTime parsedTime;
      if (timeString.length > 5) {
        parsedTime = DateFormat('HH:mm:ss').parse(timeString);
      } else {
        parsedTime = DateFormat('HH:mm').parse(timeString);
      }
      return '${DateFormat('HH:mm').format(parsedTime)} WIB';
    } catch (e) {
      print('Could not parse time: $timeString');
      return timeString; // Fallback
    }
  }

  String _formatEventDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final dateString = dateStr.trim();
    
    final formats = ['yyyy-MM-dd', 'dd-MM-yyyy', 'MM/dd/yyyy', 'yyyy/MM/dd'];
    
    for (var format in formats) {
      try {
        final parsedDate = DateFormat(format).parse(dateString);
        return DateFormat('dd MMM', 'id_ID').format(parsedDate);
      } catch (_) {}
    }
    
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd MMM', 'id_ID').format(parsedDate);
    } catch (_) {}
    
    return dateString; // Fallback to original string
  }

  String getEventImageLocal(String? category) {
    switch (category) {
      case 'ujian': return 'assets/images/event_exam.jpg';
      case 'olahraga': return 'assets/images/event_sports.jpg';
      case 'ekskul': return 'assets/images/event_extracurricular.jpg';
      default: return 'assets/images/event_general.jpg';
    }
  }

  bool hasImageFromDatabase(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null';
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
        actions: [
          if (_event != null)
            Padding(
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
                    Icons.share,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () { /* Share logic */ },
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _event != null ? _buildCtaButton() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Error: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    if (_event == null) {
      return const Center(child: Text('Event tidak ditemukan.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageHeader(),
          _buildContentBody(),
          _buildSimilarEventsSection(),
          const SizedBox(height: 100), // Space for CTA button
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    final imageUrl = _event!['image'];
    final hasImage = hasImageFromDatabase(imageUrl);
    final category = _event!['category'];
    
    return Stack(
      children: [
        // Hero Image
        Container(
          height: 380,
          width: double.infinity,
          child: hasImage
              ? Image.network(
                  imageUrl.toString().startsWith('http')
                    ? imageUrl
                    : '${ApiConfig.baseUrl}$imageUrl',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      getEventImageLocal(category),
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Image.asset(
                  getEventImageLocal(category),
                  fit: BoxFit.cover,
                ),
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
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A085),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A085).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        category?.toUpperCase() ?? 'EVENT',
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
                const SizedBox(height: 16),
                // Title
                Text(
                  _event!['title'] ?? 'Tanpa Judul',
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
                const SizedBox(height: 16),
                // Date & Location
                Row(
                  children: [
                    Expanded(
                      child: Row(
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
                          Expanded(
                            child: Text(
                              _parseAndFormatDate(_event!['event_date']),
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_event!['location'] != null && _event!['location'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _event!['location'],
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildOldImageHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Hero(
        tag: 'event_image_${_event!['id']}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: hasImageFromDatabase(_event!['image'])
                ? Image.network(
                    '${ApiConfig.baseUrl}${_event!['image']}',
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    getEventImageLocal(_event!['category']),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody() {
    final String formattedTime = _parseAndFormatTime(_event!['event_time']);

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
                  Icons.description,
                  color: Color(0xFF16A085),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Event',
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
          if (_event!['event_time'] != null && _event!['event_time'].toString().isNotEmpty) ...[
            _buildDetailRow(Icons.access_time, 'Waktu', formattedTime),
            const SizedBox(height: 16),
          ],
          if (_event!['participants_count'] != null && _event!['participants_count'] > 0) ...[
            _buildDetailRow(Icons.people, 'Partisipan', '${_event!['participants_count']} Siswa'),
            const SizedBox(height: 20),
          ],
          const Divider(),
          const SizedBox(height: 20),
          Text(
            _event!['description'] ?? 'Tidak ada deskripsi.',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF16A085).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF16A085)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2849),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarEventsSection() {
    if (_similarEventsFuture == null) return const SizedBox.shrink();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _similarEventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Event Serupa', style: TextStyle(fontFamily: 'Lato', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2B2849))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                padding: const EdgeInsets.only(left: 24),
                itemBuilder: (context, index) => _buildSimilarEventCard(snapshot.data![index]),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSimilarEventCard(Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: event['id']))),
      child: Container(
        width: 220,
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
                width: 80,
                height: double.infinity,
                child: hasImageFromDatabase(event['image'])
                  ? Image.network('${ApiConfig.baseUrl}${event['image']}', fit: BoxFit.cover)
                  : Image.asset(getEventImageLocal(event['category']), fit: BoxFit.cover),
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
                      event['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatEventDate(event['event_date']),
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
  
  Widget _buildCtaButton() {
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
        onPressed: _reminderSet || _isReminding ? null : _handleSetReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _reminderSet ? Colors.grey : const Color(0xFF16A085),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: const Color(0xFF16A085).withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isReminding)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            else
              Icon(
                _reminderSet ? Icons.check_circle : Icons.notifications_active,
                size: 22,
              ),
            const SizedBox(width: 12),
            Text(
              _reminderSet ? 'Pengingat Aktif' : 'Ingatkan Saya',
              style: const TextStyle(
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

  void _handleSetReminder() async {
    if (_event == null) return;
    setState(() {
      _isReminding = true;
    });

    try {
      final result = await EventService.setReminder(_event!['id']);
      if (result['status'] == true) {
        setState(() {
          _reminderSet = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pengingat berhasil diaktifkan!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Gagal mengatur pengingat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isReminding = false;
      });
    }
  }

  // Helper Widgets... (Same as before)
  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontFamily: 'Lato', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2B2849))),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
   Color _getCategoryColor(String? category) {
    switch (category) {
      case 'ujian': return const Color(0xFFC32525);
      case 'olahraga': return const Color(0xFF25A2C3);
      case 'ekskul': return const Color(0xFFC3A225);
      default: return Colors.grey;
    }
  }
  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'ujian': return Icons.school;
      case 'olahraga': return Icons.sports_soccer;
      case 'ekskul': return Icons.palette;
      default: return Icons.event;
    }
  }
}
