import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/landing/web_landing_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: could not load .env: $e");
  }

  // Initialize Supabase if keys provided
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Warning: could not initialize Supabase: $e");
    }
  }

  runApp(const ProviderScope(child: MoodEatsApp()));
}

class MoodEatsApp extends StatelessWidget {
  const MoodEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodEats - Autonomous Emotion & Hyperlocal Commerce',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // On Web: launch directly into the Web Landing Page (no mobile splashscreen)
      // On Mobile: launch into the animated SplashScreen
      home: kIsWeb ? const WebLandingScreen() : const SplashScreen(),
    );
  }
}
