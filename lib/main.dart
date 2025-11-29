import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/complete_google_signup_screen.dart';
import 'screens/auth/profile_photo_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/queue/queue_screen.dart';
import 'screens/billing/billing_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/events/events_list_screen.dart';
import 'screens/announcements/announcements_list_screen.dart';
import 'screens/information/information_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart School',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Lato',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        // Handle route with arguments
        if (settings.name == '/complete-google-signup') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CompleteGoogleSignupScreen(
              email: args['email'],
              photoUrl: args['photoUrl'],
              displayName: args['displayName'],
            ),
          );
        }
        
        return null;
      },
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profile-photo': (context) => const ProfilePhotoScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/home': (context) => const HomeScreen(),
        '/queue': (context) => const QueueScreen(),
        '/billing': (context) => const BillingScreen(),
        '/history': (context) => const HistoryScreen(),
        '/events': (context) => const EventsListScreen(),
        '/announcements': (context) => const AnnouncementsListScreen(),
        '/information': (context) => const InformationScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      builder: (context, child) {
        return HeroControllerScope(
          controller: MaterialApp.createMaterialHeroController(),
          child: child!,
        );
      },
    );
  }
}
