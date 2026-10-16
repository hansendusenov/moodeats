import 'package:flutter/foundation.dart';
import 'package:moodeats_app/data/services/auth/google_auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/presentation/screens/auth/complete_profile_screen.dart';
import 'package:moodeats_app/presentation/screens/auth/google_oauth_screen.dart';
import 'package:moodeats_app/presentation/screens/auth/register_screen.dart';
import 'package:moodeats_app/presentation/screens/main_navigation_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AppStrings tr) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.fillAllFields), backgroundColor: AppColors.primary),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authUserProvider.notifier).signIn(
            email: email,
            password: password,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.loginSuccess), backgroundColor: AppColors.happyGreen),
        );

        if (user.isProfileComplete) {
          ref.read(mainTabProvider.notifier).state = 0;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CompleteProfileScreen(allowSkip: true)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn(AppStrings tr) async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final res = await GoogleAuthPlatformHelper.signInWithPopup();
        if (res['success'] == true) {
          final idToken = res['idToken'] as String? ?? '';
          final email = res['email'] as String? ?? '';
          final displayName = res['displayName'] as String? ?? '';
          final localId = res['localId'] as String? ?? '';

          final user = await ref.read(firebaseAuthServiceProvider).signInWithWebPopupResult(
                idToken: idToken,
                email: email,
                displayName: displayName,
                localId: localId,
              );
          ref.read(authUserProvider.notifier).setLoggedInUser(user);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tr.welcomeBack}, ${user.displayName}!'),
                backgroundColor: AppColors.happyGreen,
              ),
            );

            if (user.isProfileComplete) {
              ref.read(mainTabProvider.notifier).state = 0;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr.pleaseCompleteProfile),
                  backgroundColor: AppColors.primary,
                ),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CompleteProfileScreen(allowSkip: true)),
                (route) => false,
              );
            }
          }
          return;
        } else {
          final errorMsg = (res['errorMessage'] ?? '').toString();
          if (!errorMsg.contains('popup-closed-by-user') && !errorMsg.contains('cancelled')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg.isNotEmpty ? errorMsg : 'Login Google dibatalkan.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          }
          return;
        }
      }

      final result = await Navigator.of(context).push<AuthResult>(
        MaterialPageRoute(
          builder: (_) => const GoogleOAuthScreen(),
          fullscreenDialog: true,
        ),
      );

      if (result != null && mounted) {
        if (result.user.isProfileComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tr.welcomeBack}, ${result.user.displayName}!'),
              backgroundColor: AppColors.happyGreen,
            ),
          );
          ref.read(mainTabProvider.notifier).state = 0;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.pleaseCompleteProfile),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CompleteProfileScreen(allowSkip: true)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop
          ? _buildSplitScreen(context, tr, lang)
          : _buildMobileLayout(context, tr, lang),
    );
  }

  /// Desktop / Web 2-Column Split Layout
  Widget _buildSplitScreen(BuildContext context, AppStrings tr, AppLanguage lang) {
    return Row(
      children: [
        // LEFT COLUMN: Brand Banner & Showcase
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDC2626), // Brand Red
                  Color(0xFF991B1B), // Deep Crimson
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back to Web Home Button
                InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      ref.read(mainTabProvider.notifier).state = 0;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          tr.isId ? 'Kembali ke Beranda' : 'Back to Home',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Brand Emblem
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/moodeats_mascot.png', width: 36, height: 36, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MoodEats',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Autonomous Sentiment Commerce',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Big Headline
                Text(
                  tr.isId
                      ? 'Ubah Rasa Lapar & Emosimu\nMenjadi Pengalaman Kuliner.'
                      : 'Transform Your Mood & Cravings\nInto Curated Culinary Journeys.',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  tr.isId
                      ? 'Rekomendasi makanan cerdas radius 10 km terintegrasi Google Places, Overpass OSM, dan Gemini Flash AI.'
                      : 'Intelligent hyperlocal food discovery within 10km radius powered by Google Places, OSM, and Gemini Flash AI.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Feature Highlights Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildBannerFeature(
                        '🎭',
                        tr.isId ? 'Curhat Emosi & Suara' : 'Emotion & Voice Curation',
                        tr.isId ? 'AI mengenali mood dan merekomendasikan rasa yang pas.' : 'AI maps emotions directly to optimal flavor profiles.',
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      _buildBannerFeature(
                        '📍',
                        tr.isId ? 'Hyperlocal GPS & Tempat Buka' : 'Hyperlocal & Live Venues',
                        tr.isId ? 'Hanya menampilkan merchant yang sedang buka di sekitarmu.' : 'Filters exclusively restaurants currently open near you.',
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      _buildBannerFeature(
                        '🎟️',
                        tr.isId ? 'Dynamic Voucher Presisi' : 'Precision Dynamic Voucher',
                        tr.isId ? 'Klaim diskon eksklusif dengan hitung mundur riil.' : 'Redeem exclusive discounts with real countdown timers.',
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Footer tag
                const Text(
                  '© 2026 MoodEats • AI Builder Cup 2026',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // RIGHT COLUMN: Clean Login Form
        Expanded(
          flex: 6,
          child: Container(
            height: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(
              children: [
                // Top Right Language Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => ref.read(appLanguageProvider.notifier).toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language, size: 14, color: AppColors.textPrimary),
                            const SizedBox(width: 4),
                            Text(
                              lang == AppLanguage.id ? 'ID' : 'EN',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Centered Form Container
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildFormContent(tr),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile layout (Single column, neat and centered)
  Widget _buildMobileLayout(BuildContext context, AppStrings tr, AppLanguage lang) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          ref.read(mainTabProvider.notifier).state = 0;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                          );
                        }
                      },
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => ref.read(appLanguageProvider.notifier).toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language, size: 14, color: AppColors.textPrimary),
                            const SizedBox(width: 4),
                            Text(
                              lang == AppLanguage.id ? 'ID' : 'EN',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'assets/images/moodeats_mascot.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _buildFormContent(tr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerFeature(String emoji, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(AppStrings tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          tr.loginTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr.loginSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Google Sign-In Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _handleGoogleSignIn(tr),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  tr.googleSignIn,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                (tr.isId ? 'atau masuk dengan email' : 'or sign in with email'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(height: 20),

        // Email Label & Field
        Text(
          tr.email,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'nama@email.com',
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Label & Field
        Text(
          tr.password,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleLogin(tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    tr.loginBtn,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Continue as Guest Option
        Center(
          child: TextButton(
            onPressed: () {
              ref.read(mainTabProvider.notifier).state = 0;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            },
            child: Text(
              tr.isId ? 'Lanjutkan sebagai Tamu →' : 'Continue as Guest →',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Register link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tr.noAccount,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  tr.registerNow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
