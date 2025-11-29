import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransWebViewScreen extends StatefulWidget {
  final String snapToken;
  final String redirectUrl;

  const MidtransWebViewScreen({
    Key? key,
    required this.snapToken,
    required this.redirectUrl,
  }) : super(key: key);

  @override
  State<MidtransWebViewScreen> createState() => _MidtransWebViewScreenState();
}

class _MidtransWebViewScreenState extends State<MidtransWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false; // Prevent double pop

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Prevent loading example.com after payment success
            if (request.url.contains('example.com')) {
              print('🚫 Preventing navigation to example.com');
              _checkUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkUrl(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _checkUrl(String url) {
    // Prevent processing if already popped
    if (_hasPopped) {
      print('⏭️ Already popped, skipping URL check');
      return;
    }

    print('');
    print('═══════════════════════════════════════════════════');
    print('🔍 WebView URL CHANGED: $url');
    print('═══════════════════════════════════════════════════');
    
    // Check for success/failure URLs
    if (url.contains('status_code=200') || 
        url.contains('transaction_status=settlement') ||
        url.contains('status=success') ||
        (url.contains('example.com') && url.contains('order_id'))) {
      
      // Payment success detected
      print('');
      print('✅✅✅ PAYMENT SUCCESS DETECTED! ✅✅✅');
      
      // Extract payment type from URL if available
      String? paymentType;
      try {
        final uri = Uri.parse(url);
        paymentType = uri.queryParameters['payment_type'];
      } catch (e) {
        print('⚠️ Error parsing URL: $e');
      }
      
      print('💳 Payment type: $paymentType');
      print('🔒 Mounted status: $mounted');
      print('🔒 Has popped: $_hasPopped');
      
      final result = {
        'status': 'success',
        'payment_type': paymentType ?? 'Midtrans',
      };
      
      print('🚀 READY TO POP WITH RESULT: $result');
      
      // Mark as popped BEFORE calling Navigator.pop
      _hasPopped = true;
      
      // Pop with result
      if (mounted) {
        print('✅ Calling Navigator.pop()...');
        Navigator.pop(context, result);
        print('✅ Navigator.pop() COMPLETED!');
      } else {
        print('❌ NOT mounted! Cannot pop!');
      }
      print('═══════════════════════════════════════════════════');
      
    } else if (url.contains('status_code=201') || url.contains('transaction_status=pending')) {
      // Payment pending
      print('⏳ Payment PENDING detected in WebView');
      _hasPopped = true;
      if (mounted) {
        Navigator.pop(context, {'status': 'pending'});
      }
    } else if (url.contains('status_code=202') || 
               url.contains('transaction_status=deny') ||
               url.contains('status=failed')) {
      // Payment denied/failed
      print('❌ Payment FAILED detected in WebView');
      _hasPopped = true;
      if (mounted) {
        Navigator.pop(context, {'status': 'failed'});
      }
    } else {
      print('ℹ️ URL tidak match dengan kondisi apapun');
      print('   Checking if contains example.com: ${url.contains('example.com')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // ✅ FIXED: Only allow back if payment already succeeded
        // If _hasPopped is true, it means _checkUrl already handled the navigation
        if (_hasPopped) {
          print('⏭️ Payment already processed, allowing back navigation');
          return;
        }
        
        // Otherwise show cancel dialog (user trying to close without completing payment)
        _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
        title: const Text(
          'Pembayaran SPP',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF16A085),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 14,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ), // Close PopScope
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFE74C3C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Batalkan Pembayaran?',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pembayaran SPP ini?',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF555555),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tidak',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {'status': 'cancelled'}); // Close webview
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF16A085).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFF16A085),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bantuan Pembayaran',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              '1',
              'Pilih metode pembayaran yang tersedia',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '2',
              'Ikuti instruksi pembayaran yang muncul',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '3',
              'Selesaikan pembayaran sesuai batas waktu',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '4',
              'Pembayaran akan diverifikasi otomatis',
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A085),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF16A085),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF555555),
            ),
          ),
        ),
      ],
    );
  }
}

