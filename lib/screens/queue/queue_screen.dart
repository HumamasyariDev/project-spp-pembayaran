import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/queue_service.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  // State: user sudah punya antrian atau belum (bisa multiple queues)
  List<Map<String, dynamic>> _myActiveQueues = [];
  Map<String, dynamic>? _selectedQueue; // For detail view
  bool _showServicesView = false; // Flag to show services even if has active queues
  
  // Data layanan antrian dari API
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _checkActiveQueue();
  }

  // Load services from API
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await QueueService.getServices();
      
      if (result['success'] == true) {
        setState(() {
          _services = (result['services'] as List<Map<String, dynamic>>)
              .map((service) {
                // Convert hex color to Color object
                final colorHex = service['color'] as String;
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                
                // Map icon name to IconData
                final iconName = service['icon'] as String;
                IconData icon;
                switch (iconName) {
                  case 'account_balance_wallet_outlined':
                    icon = Icons.account_balance_wallet_outlined;
                    break;
                  case 'description_outlined':
                    icon = Icons.description_outlined;
                    break;
                  case 'school_outlined':
                    icon = Icons.school_outlined;
                    break;
                  case 'admin_panel_settings_outlined':
                    icon = Icons.admin_panel_settings_outlined;
                    break;
                  default:
                    icon = Icons.help_outline;
                }
                
                // Ensure ID is integer
                return {
                  ...service,
                  'id': service['id'] is int ? service['id'] : int.tryParse(service['id'].toString()) ?? 0,
                  'color': color,
                  'icon': icon,
                };
              }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat layanan';
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

  // Check if user has active queues with real-time data from database
  Future<void> _checkActiveQueue() async {
    try {
      final result = await QueueService.getMyActiveQueues();
      
      print('DEBUG: getMyActiveQueues result: $result'); // Debug
      
      if (result['success'] == true && result['data'] != null) {
        final queuesData = result['data'] as List;
        
        print('DEBUG: Queues data from API: $queuesData'); // Debug
        
        if (mounted) {
          setState(() {
            _myActiveQueues = queuesData.map((queueData) {
              // Extract color from hex string
              final colorHex = queueData['serviceColor'] as String;
              final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
              
              // Helper to safely convert to int
              int safeInt(dynamic value) {
                if (value == null) return 0;
                if (value is int) return value;
                if (value is String) return int.tryParse(value) ?? 0;
                return 0;
              }
              
              return {
                'id': queueData['id'],
                'serviceId': queueData['serviceId'],
                'queueNumber': queueData['queueNumber'] ?? '',
                'queueNumberShort': queueData['queueNumberShort']?.toString() ?? '0',
                'qrCode': queueData['qrCode']?.toString(), // ✅ Parse unique QR code from API
                'status': queueData['status'] ?? 'menunggu',
                'name': queueData['serviceName'] ?? 'Layanan',
                'color': color,
                'location': queueData['serviceLocation'] ?? '-',
                'currentNumber': safeInt(queueData['currentNumber']),
                'queuesAhead': safeInt(queueData['queuesAhead']),
                'estimatedTime': queueData['estimatedTime']?.toString() ?? '0 menit',
                'estimatedMinutes': safeInt(queueData['estimatedMinutes']),
                'queueDate': queueData['queueDate']?.toString() ?? '',
                'createdAt': queueData['createdAt']?.toString() ?? '-',
                'userName': queueData['user']?['name']?.toString() ?? '-',
                'userNis': queueData['user']?['nis']?.toString() ?? '-',
                'userNisn': queueData['user']?['nisn']?.toString() ?? '-', // ✅ Map NISN field
                'userClass': queueData['user']?['class']?.toString() ?? '-',
                'statistics': queueData['statistics'] ?? {},
              };
            }).toList();
            
            print('DEBUG: _myActiveQueues set to: $_myActiveQueues'); // Debug
          });
        }
      } else {
        // No active queues
        print('DEBUG: No active queues found'); // Debug
        if (mounted) {
          setState(() {
            _myActiveQueues = [];
          });
        }
      }
    } catch (e) {
      print('Error checking active queues: $e');
      if (mounted) {
        setState(() {
          _myActiveQueues = [];
        });
      }
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    await Future.wait([
      _loadServices(),
      _checkActiveQueue(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _selectedQueue != null 
          ? _buildTicketDetailView()
          : (_myActiveQueues.isNotEmpty && !_showServicesView
              ? _buildActiveQueuesListView()
              : _buildServicesView()),
      ),
    );
  }

  // ==================== VIEW: BELUM PUNYA ANTRIAN - CLEAN & SIMPLE ====================
  Widget _buildServicesView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Back Button + Title
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Title
                      const Expanded(
                        child: Text(
                          'Antrian Layanan',
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      
                      // Refresh Button
                      GestureDetector(
                        onTap: _refreshData,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: Color(0xFF1E293B),
                              ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.only(left: 56),
                    child: Text(
                      'Pilih layanan yang tersedia',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Services List - CLEAN & MODERN STYLE
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF16A085),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Color(0xFFE74C3C),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadServices,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A085),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Coba Lagi',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _services.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada layanan tersedia',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshData,
                              color: const Color(0xFF16A085),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                                itemCount: _services.length,
                                itemBuilder: (context, index) {
                                  return _buildCleanServiceCard(_services[index], index);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CLEAN & MODERN CARD - MINIMALIS & PREMIUM ====================
  Widget _buildCleanServiceCard(Map<String, dynamic> service, int index) {
    final color = service['color'] as Color? ?? const Color(0xFF16A085);
    final icon = service['icon'] as IconData? ?? Icons.help_outline;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showServiceDetail(service),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Icon & Current Number Badge
                Row(
                  children: [
                    // Icon with Gradient
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    
                    const Spacer(),
                    
                    // User Queue Number Badge (if user has active queue for this service)
                    Builder(
                      builder: (context) {
                        // Find user's queue for this service
                        final userQueue = _myActiveQueues.firstWhere(
                          (q) => q['serviceId'] == service['id'],
                          orElse: () => {},
                        );
                        
                        final hasQueue = userQueue.isNotEmpty;
                        final queueNumber = hasQueue ? userQueue['queueNumberShort'].toString() : '0';
                        
                        // Debug print
                        print('DEBUG Badge: service[${service['id']}] = $queueNumber, _myActiveQueues.length = ${_myActiveQueues.length}');
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No. ',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color.withOpacity(0.7),
                                  height: 1,
                                ),
                              ),
                              Text(
                                queueNumber,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Service Name
                Text(
                  service['name'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.3,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Description
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
                
                const SizedBox(height: 14),
                
                // Stats Row
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${service['waiting']} menunggu',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service['estimatedTime'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== VIEW: MULTIPLE ACTIVE QUEUES LIST ====================
  Widget _buildActiveQueuesListView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Tiket Antrian Aktif',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _myActiveQueues.length + 1,
          itemBuilder: (context, index) {
            if (index == _myActiveQueues.length) {
              // "Ambil Antrian Lain" button
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _showServicesView = true; // Show services view (keep data for badge)
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 12),
                      const Text(
                        'Ambil Antrian Lain',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final queue = _myActiveQueues[index];
            final color = queue['color'] as Color;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedQueue = queue;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.receipt, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  queue['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  queue['location'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                    // Stats
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQueueStat('Nomor', queue['queueNumberShort'].toString(), color),
                          _buildQueueStat('Sisa', queue['queuesAhead'].toString(), color),
                          _buildQueueStat('Estimasi', queue['estimatedTime'] as String, color),
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
    );
  }

  Widget _buildQueueStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== VIEW: SINGLE TICKET DETAIL ====================
  Widget _buildTicketDetailView() {
    final color = _selectedQueue!['color'] as Color? ?? const Color(0xFF16A085);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Gradient Background Header
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildTicketDetailHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        _buildModernTicketCard(color),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetailHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedQueue = null; // Back to list
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const Expanded(
            child: Text(
              'Tiket Antrian SPP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // Refresh Button
          GestureDetector(
            onTap: _refreshData,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
            ),
          ),
        ],
      ),
    );
  }


  // ==================== VIEW: ANTRIAN AKTIF - DEPRECATED (use _buildTicketDetailView) ====================
  // This method is kept for backward compatibility but redirects to new implementation
  Widget _buildActiveQueueView() {
    return _buildTicketDetailView();
  }

  // ==================== DIALOGS ====================
  void _showServiceDetail(Map<String, dynamic> service) {
    print('DEBUG _showServiceDetail: service = $service');
    print('DEBUG _showServiceDetail: service[id] = ${service['id']} (${service['id'].runtimeType})');
    print('DEBUG _showServiceDetail: service[name] = ${service['name']}');
    
    final color = service['color'] as Color? ?? const Color(0xFF16A085);
    final icon = service['icon'] as IconData? ?? Icons.help_outline;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              service['name'] as String,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF000000),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              service['description'] as String,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Info grid
            Row(
              children: [
                Expanded(
                  child: _buildBottomSheetInfo(
                    Icons.location_on_outlined,
                    service['location'] as String,
                    color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomSheetInfo(
                    Icons.confirmation_number_outlined,
                    '${service['current']}',
                    color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBottomSheetInfo(
                    Icons.people_outline,
                    '${service['waiting']} tunggu',
                    color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomSheetInfo(
                    Icons.access_time,
                    service['estimatedTime'] as String,
                    color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Take button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _takeQueue(service);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Ambil Nomor Antrian',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetInfo(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format date helper - Figma boarding pass style
  String _formatDate(Map<String, dynamic> queue) {
    return DateFormat('MMMM dd, yyyy', 'id_ID').format(DateTime.now());
  }

  // Build detail column - Figma exact
  Widget _buildDetailColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }

  // Build detail column - FIGMA EXACT (value on top, label on bottom)
  Widget _buildDetailColumnFigma(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0x99000000), // 60% opacity
            height: 1.51,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
            height: 1.51,
          ),
        ),
      ],
    );
  }

  // Build Figma detail item - Value on top, Label on bottom (center aligned)
  Widget _buildFigmaDetailItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0x99000000), // 60% opacity
            height: 1.51,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
            height: 1.51,
          ),
        ),
      ],
    );
  }

  Future<void> _takeQueue(Map<String, dynamic> service) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengambil nomor antrian...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Call API to create queue with service ID
      print('DEBUG _takeQueue: service = $service');
      print('DEBUG _takeQueue: service[id] = ${service['id']} (${service['id'].runtimeType})');
      
      final result = await QueueService.createQueue(
        serviceId: service['id'] as int,
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (result['success'] == true) {
        // Show success message first
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Nomor antrian berhasil diambil!',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2), // 🎯 DURASI 2 DETIK
            ),
          );
          
          // Reload active queue data after showing message  
          // Wrap in try-catch to prevent error from breaking UI
          try {
            _showServicesView = false; // Reset flag to show active queues
            await _checkActiveQueue();
          } catch (e) {
            print('Error reloading queue: $e');
          }
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Gagal mengambil nomor antrian',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Terjadi kesalahan: ${e.toString()}',
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(28),
        title: const Text(
          'Batalkan Antrian?',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Anda yakin ingin membatalkan antrian ini?',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tidak',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _refreshData(); // Refresh to update queue list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Antrian dibatalkan'),
                        backgroundColor: Color(0xFFFF3B30),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Ya, Batalkan',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== MODERN HELPER METHODS ====================
  Widget _buildModernHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedQueue = null; // Back to list view
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const Expanded(
            child: Text(
              'Tiket Antrian SPP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // Refresh Button
          GestureDetector(
            onTap: _refreshData,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTicketCard(Color color) {
    // Use _selectedQueue if viewing detail, otherwise use first queue for backward compatibility
    final queue = _selectedQueue ?? (_myActiveQueues.isNotEmpty ? _myActiveQueues[0] : null);
    if (queue == null) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTicketHeader(color, queue),
          _buildInfoSection(color, queue),
          _buildDivider(),
          _buildQueueDetails(queue),
          _buildDivider(),
          _buildStudentInfo(color, queue),
          _buildDashedDivider(),
          _buildQueueNumber(color, queue),
          _buildCancelButton(queue),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(Color color, Map<String, dynamic> queue) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          // Icon kiri
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  queue['name'] ?? 'Pembayaran SPP',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(queue),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Color color, Map<String, dynamic> queue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildModernInfoItem(
            icon: Icons.access_time,
            value: queue['createdAt'] ?? '-',
            label: 'Waktu Ambil',
            color: color,
          ),
          const SizedBox(width: 8),
          _buildModernInfoItem(
            icon: Icons.timelapse,
            value: queue['estimatedTime'] ?? 'Siap',
            label: 'Estimasi',
            color: color,
          ),
          const SizedBox(width: 8),
          _buildModernInfoItem(
            icon: Icons.place,
            value: queue['location'] ?? 'Loket 1',
            label: 'Lokasi',
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 6),
            
            // Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        color: Colors.grey[200],
        thickness: 1.5,
      ),
    );
  }

  Widget _buildQueueDetails(Map<String, dynamic> queue) {
    final stats = queue['statistics'] as Map<String, dynamic>?;
    final color = queue['color'] as Color;
    
    // Safe conversion to int - handle both int and String types
    int parseToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    final currentNumber = parseToInt(queue['currentNumber']);
    final queuesAhead = parseToInt(queue['queuesAhead']);
    final completed = parseToInt(stats?['completed']);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Statistik Antrian',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // Stats Row
          Row(
            children: [
              _buildCompactDetailItem(
                label: 'Bulan',
                value: _formatMonth(queue),
                color: color,
              ),
              const SizedBox(width: 8),
              _buildCompactDetailItem(
                label: 'Sekarang',
                value: currentNumber > 0 ? currentNumber.toString() : '-',
                color: color,
              ),
              const SizedBox(width: 8),
              _buildCompactDetailItem(
                label: 'Sisa',
                value: queuesAhead.toString(),
                color: color,
              ),
              const SizedBox(width: 8),
              _buildCompactDetailItem(
                label: 'Selesai',
                value: completed.toString(),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatMonth(Map<String, dynamic> queue) {
    try {
      final queueDate = queue['queueDate'];
      if (queueDate == null) return '-';
      
      final date = DateTime.parse(queueDate);
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return monthNames[date.month - 1];
    } catch (e) {
      return '-';
    }
  }

  Widget _buildCompactDetailItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo(Color color, Map<String, dynamic> queue) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  queue['userName'] ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${queue['userClass'] ?? '-'} • NISN: ${queue['userNisn'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(queue['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(queue['status']),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(queue['status']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(
          150 ~/ 3,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0 ? Colors.grey[300] : Colors.transparent,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueNumber(Color color, Map<String, dynamic> queue) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'NOMOR ANDA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatQueueNumberShort(queue['queueNumberShort']),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 8,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 2,
              ),
            ),
            child: QrImageView(
              data: queue['qrCode'] ?? 'QUEUE-${queue['queueNumber']}-${queue['id']}', // ✅ Use unique QR code from backend
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Tunjukkan QR Code ini ke petugas',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(Map<String, dynamic> queue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: _showCancelConfirmation,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE74C3C), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Batalkan Antrian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE74C3C),
            ),
          ),
        ),
      ),
    );
  }
  
  // Show cancel confirmation dialog
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFE74C3C),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Batalkan Antrian?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan antrian ini? Anda harus mengambil nomor baru jika ingin antri lagi.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelQueue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Cancel queue - call API
  Future<void> _cancelQueue() async {
    final queue = _selectedQueue ?? (_myActiveQueues.isNotEmpty ? _myActiveQueues[0] : null);
    if (queue == null) {
      print('ERROR: No active queue');
      return;
    }
    
    // Validate queue ID
    final queueId = queue['id'];
    if (queueId == null) {
      print('ERROR: Queue ID is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: ID antrian tidak valid'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
      return;
    }
    
    print('DEBUG _cancelQueue: Canceling queue ID = $queueId');
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFE74C3C)),
                SizedBox(height: 16),
                Text('Membatalkan antrian...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      final result = await QueueService.cancelQueue(queueId);
      print('DEBUG _cancelQueue: Result = $result');
      
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (result['success'] == true) {
        print('DEBUG _cancelQueue: Success! Updating state to null');
        
        // Show success message first
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Antrian berhasil dibatalkan',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Update state - remove cancelled queue and go back to list
        try {
          if (mounted) {
            setState(() {
              print('DEBUG: Removing cancelled queue from list');
              _myActiveQueues.removeWhere((q) => q['id'] == queueId);
              _selectedQueue = null; // Back to list view
            });
            print('DEBUG: State updated, ${_myActiveQueues.length} queues remaining');
          }
        } catch (e) {
          print('ERROR updating state: $e');
        }
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Gagal membatalkan antrian',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Terjadi kesalahan: ${e.toString()}',
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ==================== CUSTOM PAINTERS & CLIPPERS ====================

// Dashed line painter - FIGMA EXACT
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33000000) // 20% opacity
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom clipper for curved background - SMOOTH & NATURAL WAVE
class CurvedBackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 100);
    
    // Create smooth S-curve wave - LEBIH NATURAL & CANTIK
    final firstControlPoint = Offset(size.width * 0.2, size.height - 120);
    final firstEndPoint = Offset(size.width * 0.4, size.height - 80);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    final secondControlPoint = Offset(size.width * 0.6, size.height - 40);
    final secondEndPoint = Offset(size.width * 0.8, size.height - 60);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    final thirdControlPoint = Offset(size.width * 0.9, size.height - 80);
    final thirdEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      thirdControlPoint.dx,
      thirdControlPoint.dy,
      thirdEndPoint.dx,
      thirdEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ==================== HELPER FUNCTIONS ====================
extension _QueueScreenHelpers on _QueueScreenState {
  String _formatQueueNumberShort(dynamic queueNumber) {
    if (queueNumber == null) return 'A000';
    
    // Ensure we have a string with at least 3 digits
    String numStr = queueNumber.toString().padLeft(3, '0');
    
    // Format as A + 3 digits (e.g., A016)
    return 'A$numStr';
  }
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'menunggu':
        return const Color(0xFFF39C12); // Orange
      case 'dipanggil':
        return const Color(0xFF3498DB); // Blue
      case 'dilayani':
        return const Color(0xFF27AE60); // Green
      case 'selesai':
        return const Color(0xFF95A5A6); // Gray
      case 'dibatalkan':
        return const Color(0xFFE74C3C); // Red
      default:
        return const Color(0xFF95A5A6);
    }
  }
  
  String _getStatusText(String? status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'dipanggil':
        return 'Dipanggil';
      case 'dilayani':
        return 'Dilayani';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Aktif';
    }
  }
}
