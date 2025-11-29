import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Ambil Antrian\nTanpa Ribet',
      description: 'Dapatkan nomor antrian pembayaran SPP secara digital tanpa harus menunggu lama',
      illustration: 'assets/illustrations/onboarding_1.png',
      background: 'assets/illustrations/onboarding_bg_1.png',
    ),
    OnboardingData(
      title: 'Bayar SPP\nLebih Mudah',
      description: 'Pantau tagihan dan bayar SPP dengan mudah langsung dari aplikasi',
      illustration: 'assets/illustrations/onboarding_2.png',
      background: 'assets/illustrations/onboarding_bg_2.png',
    ),
    OnboardingData(
      title: 'Notifikasi\nReal-Time',
      description: 'Dapatkan pemberitahuan langsung saat antrian sudah dekat atau pembayaran berhasil',
      illustration: 'assets/illustrations/onboarding_3.png',
      background: 'assets/illustrations/onboarding_bg_3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Add haptic feedback for premium feel
    HapticFeedback.lightImpact();
  }

  void _navigateToAuth() {
    // ✅ Use pushNamed instead of pushReplacementNamed to keep onboarding in stack
    Navigator.pushNamed(context, '/signin');
  }

  void _skipToAuth() {
    // ✅ Use pushNamed instead of pushReplacementNamed to keep onboarding in stack
    Navigator.pushNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // Swipe ke kiri (next page)
              if (details.primaryVelocity! < -500) {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
              // Swipe ke kanan (previous page)
              else if (details.primaryVelocity! > 500) {
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            child: Stack(
              children: [
                // Background Full Screen dengan PageView & Gradient Overlay
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    physics: const NeverScrollableScrollPhysics(), // Disable default swipe
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
          children: [
                          Image.asset(
                            _pages[index].background,
                            fit: BoxFit.cover,
                          ),
                          // Subtle gradient overlay untuk depth
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Floating decorative elements
                Positioned(
                  top: 100,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary04.withOpacity(0.08),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        duration: 3000.ms,
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                      ),
                ),
                Positioned(
                  bottom: 200,
                  left: -40,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary04.withOpacity(0.06),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        duration: 3500.ms,
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.25, 1.25),
                      ),
                ),
                // Content di atas background
                Column(
                children: [
                  // Header - Logo and Skip
                  SizedBox(
                    height: 62,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Logo di tengah
                          Center(child: _buildLogo()),
                          // Skip button di kanan
                          Positioned(
                            right: 0,
                            child: TextButton(
                    onPressed: _skipToAuth,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.paraMediumMedium.copyWith(
                                  color: AppColors.primary01,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                  ),
                  // Illustration Area - Modern animated illustration dengan parallax
            Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow background effect
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary04.withOpacity(0.12),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                .scale(
                                  duration: 2500.ms,
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1.1, 1.1),
                                ),
                            // Main illustration with shadow
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary04.withOpacity(0.15),
                                    blurRadius: 50,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                _pages[_currentPage].illustration,
                                height: 280,
                                fit: BoxFit.contain,
                              ),
                            )
                                .animate(key: ValueKey('illustration_$_currentPage'))
                                .fadeIn(
                                  duration: 600.ms,
                                  curve: Curves.easeOut,
                                )
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0),
                                  duration: 850.ms,
                                  curve: Curves.easeOutBack,
                                )
                                .slideY(
                                  begin: 0.12,
                                  end: 0,
                                  duration: 750.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .then()
                                .shimmer(
                                  duration: 2000.ms,
                                  delay: 500.ms,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                          ],
                        ),
                ),
              ),
            ),
                  // Modern Divider with gradient
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.dark.withOpacity(0.6),
                          AppColors.dark,
                          AppColors.dark.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title - Modern gradient text dengan shadow
            Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            const Color(0xFF292F2E),
                            const Color(0xFF292F2E).withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          _pages[_currentPage].title,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.8,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: AppColors.primary04.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(key: ValueKey('title_$_currentPage'))
                          .fadeIn(
                            duration: 550.ms,
                            delay: 100.ms,
                            curve: Curves.easeOut,
                          )
                          .slideX(
                            begin: 0.2,
                            end: 0,
                            duration: 700.ms,
                            delay: 100.ms,
                            curve: Curves.easeOutCubic,
                          )
                          .then()
                          .shimmer(
                            duration: 1800.ms,
                            delay: 300.ms,
                            color: AppColors.primary04.withOpacity(0.15),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description dengan backdrop
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary04.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _pages[_currentPage].description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: const Color(0xFF292F2E).withOpacity(0.85),
                        ),
                      ),
                    )
                        .animate(key: ValueKey('desc_$_currentPage'))
                        .fadeIn(
                          duration: 550.ms,
                          delay: 250.ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: 650.ms,
                          delay: 250.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.0, 1.0),
                          duration: 700.ms,
                          delay: 250.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                  const SizedBox(height: 40),
                  // Bottom section - Dots and Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Indicators - Smooth animated dots
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(right: 6),
                              width: index == _currentPage ? 24 : 6,
                              height: index == _currentPage ? 8 : 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: index == _currentPage
                                    ? AppColors.primary04
                                    : const Color(0xFFD4D4D4),
                                boxShadow: index == _currentPage
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary04.withOpacity(0.3),
                                          blurRadius: 6,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                        // Next/Get Started Button - Premium gradient button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary04,
                                AppColors.primary04.withOpacity(0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary04.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                child: ElevatedButton(
                  onPressed: () {
                              HapticFeedback.mediumImpact();
                    if (_currentPage == _pages.length - 1) {
                      _navigateToAuth();
                    } else {
                      _pageController.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                    _currentPage == _pages.length - 1
                        ? 'Mulai Sekarang'
                                      : 'Lanjut',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .shimmer(
                              duration: 2500.ms,
                              color: Colors.white.withOpacity(0.3),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
        children: [
        Image.asset(
          'assets/images/splash_logo_1.png',
          width: 22,
          height: 18,
        ),
        const SizedBox(width: 4),
        const Text(
          'SmartQueue',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1.2,
          ),
        ),
      ],
    );
  }

}

class OnboardingData {
  final String title;
  final String description;
  final String illustration;
  final String background;

  OnboardingData({
    required this.title,
    required this.description,
    required this.illustration,
    required this.background,
  });
}

