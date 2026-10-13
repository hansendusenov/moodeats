import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/presentation/screens/auth/complete_profile_screen.dart';
import 'package:moodeats_app/presentation/screens/auth/login_screen.dart';
import 'package:moodeats_app/presentation/screens/main_navigation_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Check Firebase Auth state & Profile completion after splash animation
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        final authService = ref.read(firebaseAuthServiceProvider);
        Widget destination;

        if (!authService.isLoggedIn) {
          destination = const LoginScreen();
        } else if (authService.currentUser?.isProfileComplete != true) {
          destination = const CompleteProfileScreen();
        } else {
          destination = const MainNavigationScreen();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => destination,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDC2626), // Brand Red
              Color(0xFFB91C1C), // Deep Crimson
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Logo Emblem
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🍲',
                        style: TextStyle(fontSize: 54),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'MoodEats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Rekomendasi Kuliner Sesuai Suasana Hatimu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Bottom Indicator & Tag
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Autonomous Emotion & Hyperlocal Commerce',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
