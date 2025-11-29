import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/notification_service.dart';

// Define color constants for this screen
const Color _primaryColor = Color(0xFF16A085);
const Color _surfaceColor = Color(0xFFF8F9FA);
const Color _textPrimary = Color(0xFF2C3E50);
const Color _textSecondary = Color(0xFF7F8C8D);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getNotifications(_selectedFilter);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _surfaceColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterTabs(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      )
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _primaryColor,
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(_notifications[index]);
                              },
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Semua pemberitahuan Anda',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await NotificationService.markAllAsRead();
                _loadNotifications();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Semua notifikasi telah dibaca'),
                        ],
                      ),
                      backgroundColor: _primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Handle error
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.done_all_rounded,
                    size: 16,
                    color: _primaryColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tandai Semua',
                    style: TextStyle(
                      fontSize: 12,
                      color: _primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'name': 'Semua', 'icon': Icons.inbox_rounded},
      {'name': 'Pembayaran', 'icon': Icons.account_balance_wallet_rounded},
      {'name': 'Acara', 'icon': Icons.event_rounded},
      {'name': 'Pengumuman', 'icon': Icons.campaign_rounded},
      {'name': 'Sistem', 'icon': Icons.settings_rounded},
    ];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['name'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedFilter = filter['name'] as String);
                  _loadNotifications();
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [_primaryColor, Color(0xFF1ABC9C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : _surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : _textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
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
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.05),
                  _primaryColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 50,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = notification['is_read'] == false || notification['is_read'] == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnread 
              ? _primaryColor.withOpacity(0.3) 
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isUnread ? 0.04 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (isUnread) {
              await NotificationService.markAsRead(notification['id']);
              _loadNotifications();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification['type'], isUnread),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryColor, Color(0xFF1ABC9C)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'BARU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatTime(notification['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _buildNotificationType(notification['type']),
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

  Widget _buildNotificationIcon(String? type, bool isUnread) {
    IconData icon;
    List<Color> gradientColors;
    
    switch (type) {
      case 'Pembayaran':
        icon = Icons.account_balance_wallet_rounded;
        gradientColors = [const Color(0xFF27AE60), const Color(0xFF2ECC71)];
        break;
      case 'Acara':
        icon = Icons.event_rounded;
        gradientColors = [const Color(0xFFE67E22), const Color(0xFFF39C12)];
        break;
      case 'Pengumuman':
        icon = Icons.campaign_rounded;
        gradientColors = [const Color(0xFF3498DB), const Color(0xFF5DADE2)];
        break;
      case 'Sistem':
        icon = Icons.settings_rounded;
        gradientColors = [const Color(0xFF8E44AD), const Color(0xFF9B59B6)];
        break;
      default:
        icon = Icons.notifications_active_rounded;
        gradientColors = [_primaryColor, const Color(0xFF1ABC9C)];
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnread 
              ? gradientColors 
              : [Colors.grey[300]!, Colors.grey[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationType(String? type) {
    if (type == null) return const SizedBox();
    
    Color bgColor;
    Color textColor;
    
    switch (type) {
      case 'Pembayaran':
        bgColor = const Color(0xFF27AE60).withOpacity(0.1);
        textColor = const Color(0xFF27AE60);
        break;
      case 'Acara':
        bgColor = const Color(0xFFE67E22).withOpacity(0.1);
        textColor = const Color(0xFFE67E22);
        break;
      case 'Pengumuman':
        bgColor = const Color(0xFF3498DB).withOpacity(0.1);
        textColor = const Color(0xFF3498DB);
        break;
      case 'Sistem':
        bgColor = const Color(0xFF8E44AD).withOpacity(0.1);
        textColor = const Color(0xFF8E44AD);
        break;
      default:
        bgColor = _primaryColor.withOpacity(0.1);
        textColor = _primaryColor;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    
    try {
      final now = DateTime.now();
      final notifTime = DateTime.parse(dateTime);
      final diff = now.difference(notifTime);
      
      if (diff.inDays > 0) {
        return '${diff.inDays} hari lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} menit lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateTime;
    }
  }
}
