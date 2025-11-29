import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9DB2D6).withOpacity(0.13),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64, // Exact dari Figma
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.info_outline, 'Info'),
                _buildAddButton(context),
                _buildNavItem(3, Icons.payment_outlined, 'Bayar'),
                _buildNavItem(4, Icons.person_outline, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = selectedIndex == index;
    return InkWell(
      onTap: () => onItemTapped(index),
      splashColor: const Color(0xFF16A085).withOpacity(0.2), // Teal theme
      highlightColor: const Color(0xFF16A085).withOpacity(0.1), // Teal theme
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 60,
        height: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: isActive 
                ? const Color(0xFF16A085) // Teal green - tema aplikasi
                : const Color(0xFF2C3550).withOpacity(0.2),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Airbnb Cereal App',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isActive 
                  ? const Color(0xFF16A085) // Teal green - tema aplikasi
                  : const Color(0xFF2C3550).withOpacity(0.2),
                height: 1.302,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -23), // Naik ke atas (exact dari visual Figma)
      child: InkWell(
        onTap: () {
          // Navigate to Queue screen
          Navigator.pushNamed(context, '/queue');
        },
        borderRadius: BorderRadius.circular(23),
        child: Container(
          width: 46, // Exact dari Figma
          height: 46, // Exact dari Figma
          decoration: BoxDecoration(
            color: const Color(0xFF16A085), // Teal green - tema aplikasi
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A085).withOpacity(0.25), // Teal shadow
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_box, // Material icon seperti Figma
            color: Color(0xFFFFFFFF), // White
            size: 20, // Exact 20x20 dari Figma
          ),
        ),
      ),
    );
  }
}

