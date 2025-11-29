import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  Timer? _timer;
  
  // 5 halaman splash screen dengan data dari Figma
  // Urutan: Putih → Kuning → Dark Putih → Dark Hijau → Teal
  final List<Map<String, dynamic>> _splashPages = [
    {
      'background': const Color(0xFFFFFFFF), // Splash 01 - Putih (PERTAMA)
      'textColor': const Color(0xFF17907C),
      'logo': 'assets/images/splash_logo_1.png',
      'brightness': Brightness.dark,
    },
    {
      'background': const Color(0xFFFFCC71), // Splash 02 - Kuning
      'textColor': const Color(0xFF292F2E),
      'logo': 'assets/images/splash_logo_2.png',
      'brightness': Brightness.dark,
    },
    {
      'background': const Color(0xFF292F2E), // Splash 03 - Dark Gray (text putih)
      'textColor': const Color(0xFFFFFFFF),
      'logo': 'assets/images/splash_logo_3.png',
      'brightness': Brightness.light,
    },
    {
      'background': const Color(0xFF292F2E), // Splash 04 - Dark Gray (text hijau)
      'textColor': const Color(0xFF1CAD95),
      'logo': 'assets/images/splash_logo_4.png',
      'brightness': Brightness.light,
    },
    {
      'background': const Color(0xFF1CAD95), // Splash 05 - Teal/Hijau (TERAKHIR)
      'textColor': const Color(0xFFFFFFFF),
      'logo': 'assets/images/splash_logo_5.png',
      'brightness': Brightness.light,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoTransition();
    _navigateToNext();
  }
  
  void _startAutoTransition() {
    // Delay awal 1.2 detik agar halaman pertama terlihat dulu
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      
      _timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
        if (mounted && _currentPage < _splashPages.length - 1) {
          setState(() {
            _currentPage++;
          });
        }
      });
    });
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 8));
    _timer?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade transition yang smooth
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            );

            // Scale transition yang subtle
            final scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPageData = _splashPages[_currentPage];
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: currentPageData['brightness'] as Brightness,
      ),
      child: Scaffold(
        body: Stack(
            children: [
            // Animated gradient background
            AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    currentPageData['background'] as Color,
                    (currentPageData['background'] as Color).withOpacity(0.85),
            ],
          ),
        ),
            ),
            // Animated decorative circles
            ...List.generate(3, (i) {
              return Positioned(
                top: i == 0 ? -100 : (i == 1 ? MediaQuery.of(context).size.height * 0.3 : MediaQuery.of(context).size.height * 0.7),
                right: i == 1 ? -80 : null,
                left: i != 1 ? -60 : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  width: i == 0 ? 200 : (i == 1 ? 150 : 180),
                  height: i == 0 ? 200 : (i == 1 ? 150 : 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      duration: (3000 + i * 500).ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.15, 1.15),
                    ),
              );
            }),
            // Content
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: _splashPages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final page = entry.value;
                  final isActive = index == _currentPage;
                  
                  return AnimatedOpacity(
                    key: ValueKey(index),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    opacity: isActive ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !isActive,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
      children: [
                          // Logo dengan modern animation
        Container(
                            padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
                              shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                                  color: (page['textColor'] as Color).withOpacity(0.15),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              page['logo'] as String,
                              width: 120,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          )
                              .animate(key: ValueKey('logo_$index'))
                              .fadeIn(
                                duration: 700.ms,
                                curve: Curves.easeOut,
                              )
                              .scale(
                                begin: const Offset(0.7, 0.7),
                                end: const Offset(1.0, 1.0),
                                duration: 900.ms,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .shimmer(
                                duration: 1500.ms,
                                color: Colors.white.withOpacity(0.2),
                              ),
                          const SizedBox(height: 24),
                          // Text dengan gradient & shadow
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                page['textColor'] as Color,
                                (page['textColor'] as Color).withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'SmartQueue',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: (page['textColor'] as Color).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
                            ),
                          )
                              .animate(key: ValueKey('text_$index'))
                              .fadeIn(
                                duration: 700.ms,
                                delay: 200.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                delay: 200.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .then()
                              .shimmer(
                                duration: 2000.ms,
                                delay: 400.ms,
                                color: Colors.white.withOpacity(0.4),
                              ),
                          const SizedBox(height: 8),
                          // Tagline
                          Text(
                            'Antrian SPP Digital',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              color: (page['textColor'] as Color).withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          )
                              .animate(key: ValueKey('tagline_$index'))
                              .fadeIn(
                                duration: 600.ms,
                                delay: 400.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                duration: 700.ms,
                                delay: 400.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

