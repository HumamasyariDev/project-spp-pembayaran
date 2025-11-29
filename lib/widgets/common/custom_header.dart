import 'package:flutter/material.dart';
import 'dart:io';

class CustomHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String locationName;
  final bool isLoadingLocation;
  final VoidCallback onLocationTap;
  final bool hasNotification;
  final VoidCallback onNotificationTap;

  const CustomHeader({
    super.key,
    required this.scaffoldKey,
    required this.locationName,
    required this.isLoadingLocation,
    required this.onLocationTap,
    required this.hasNotification,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            // Hamburger Menu Icon
            InkWell(
              onTap: () => scaffoldKey.currentState?.openDrawer(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 24,
                  height: 19.2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 2.4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 2.4,
                          width: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                      Container(
                        height: 2.4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Location Info - Flexible untuk avoid overflow
            Expanded(
              child: GestureDetector(
                onTap: onLocationTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Baris 1: "Lokasi Saat Ini"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lokasi Saat Ini',
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFFCFCFC).withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(width: 3),
                        if (isLoadingLocation)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFFCFCFC).withOpacity(0.9),
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 10,
                            color: const Color(0xFFFCFCFC).withOpacity(0.9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Baris 2: Icon location + Nama lokasi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFF4F4FE),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationName,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFF4F4FE),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Notification Icon
            GestureDetector(
              onTap: onNotificationTap,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Circle border putih
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                    // Bell icon
                    Positioned(
                      left: 10.5,
                      top: 9.67,
                      child: Image.asset(
                        'assets/icons/notification_bell.png',
                        width: 15,
                        height: 16.67,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Badge dot indicator (RED)
                    if (hasNotification)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4444),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4444).withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
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

