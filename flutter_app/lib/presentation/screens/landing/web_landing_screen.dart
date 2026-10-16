import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/auth/google_auth_helper.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/presentation/screens/auth/complete_profile_screen.dart';
import 'package:moodeats_app/presentation/screens/auth/login_screen.dart';
import 'package:moodeats_app/presentation/screens/main_navigation_screen.dart';
import 'package:moodeats_app/presentation/screens/roulette/bite_roulette_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class WebLandingScreen extends ConsumerStatefulWidget {
  const WebLandingScreen({super.key});

  @override
  ConsumerState<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends ConsumerState<WebLandingScreen> {
  bool _isLoggingInGoogle = false;

  Future<void> _handleGoogleSignInWeb(AppStrings tr) async {
    setState(() => _isLoggingInGoogle = true);
    try {
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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CompleteProfileScreen(allowSkip: true)),
            );
          }
        }
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingInGoogle = false);
    }
  }

  void _navigateToApp({int tabIndex = 0}) {
    ref.read(mainTabProvider.notifier).state = tabIndex;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final authUser = ref.watch(authUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildNavbar(context, tr, lang, authUser, isDesktop),

            // Hero Section
            _buildHeroSection(context, tr, isDesktop),

            // Value Propositions / Feature Pillars
            _buildFeaturesSection(context, tr, isDesktop),

            // How It Works Section
            _buildHowItWorksSection(context, tr, isDesktop),

            // Call to Action Banner
            _buildBottomCta(context, tr, isDesktop),

            // Footer
            _buildFooter(context, tr, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(
    BuildContext context,
    AppStrings tr,
    AppLanguage lang,
    UserModel? authUser,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Brand Logo
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/images/moodeats_mascot.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoodEats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Hyperlocal Sentiment Commerce',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Language Switcher
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ref.read(appLanguageProvider.notifier).toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(width: 12),

          // User info or Login Buttons
          if (authUser != null) ...[
            TextButton.icon(
              onPressed: () => _navigateToApp(tabIndex: 3),
              icon: const Icon(Icons.account_circle, color: AppColors.primary),
              label: Text(
                authUser.displayName.isNotEmpty ? authUser.displayName : 'Akun',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _navigateToApp(tabIndex: 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Buka Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            if (isDesktop)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  tr.isId ? 'Masuk' : 'Sign In',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _navigateToApp(tabIndex: 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                tr.isId ? 'Mulai Eksplorasi' : 'Explore Now',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, AppStrings tr, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: isDesktop ? 64 : 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFEF2F2), // Light Crimson / Red tint
            Color(0xFFFAFAFA),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Mascot Character
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/moodeats_mascot.png',
                  width: isDesktop ? 130 : 95,
                  height: isDesktop ? 130 : 95,
                  fit: BoxFit.contain,
                ),
              ),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      tr.isId
                          ? 'AI Builder Cup 2026 • Hyperlocal Sentiment Commerce'
                          : 'AI Builder Cup 2026 • Hyperlocal Sentiment Commerce',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                tr.isId
                    ? 'Bingung Mau Makan Apa?\nCurhatkan Suasana Hatimu.'
                    : 'Unsure What to Eat?\nExpress Your Mood and Craving.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 48 : 30,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.15,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  tr.isId
                      ? 'MoodEats mengubah perasaan, lelah, dan curhatanmu menjadi rekomendasi kuliner lezat di sekitarmu secara instan dengan kecerdasan Gemini Flash AI dan GPS terintegrasi.'
                      : 'MoodEats transforms your emotions, fatigue, and cravings into instant local culinary discoveries powered by Gemini Flash AI and real-time GPS tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Mood Pills Preview
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMoodChip('🥺 Lagi Sedih Butuh Manis', 'Lagi sedih dan stres kerja, butuh dessert manis yang lembut.'),
                  _buildMoodChip('🔥 Pengen yang Pedas Gurih', 'Lagi geregetan, pengen makan yang pedas berkuah gurih.'),
                  _buildMoodChip('☕ Mau Kopi Buat Nugas', 'Butuh kopi susu dingin dan tempat tenang buat nugas.'),
                  _buildMoodChip('🍲 Badan Lemas Pengen Sup', 'Badan lagi kurang fit, pengen sup hangat berkuah segar.'),
                ],
              ),
              const SizedBox(height: 36),

              // Main CTA Buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  // Primary Button: Mulai Eksplorasi
                  ElevatedButton.icon(
                    onPressed: () => _navigateToApp(tabIndex: 0),
                    icon: const Icon(Icons.explore_rounded, size: 20),
                    label: Text(
                      tr.isId ? 'Mulai Eksplorasi Kuliner' : 'Start Culinary Discovery',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                  ),

                  // Google Sign-In Popup Button
                  OutlinedButton.icon(
                    onPressed: _isLoggingInGoogle ? null : () => _handleGoogleSignInWeb(tr),
                    icon: _isLoggingInGoogle
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 18, color: AppColors.primary),
                          ),
                    label: Text(
                      _isLoggingInGoogle
                          ? (tr.isId ? 'Membuka Google...' : 'Opening Google...')
                          : (tr.isId ? 'Masuk dengan Google' : 'Sign in with Google'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                  // Bite Roulette Shortcut
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BiteRouletteScreen()),
                      );
                    },
                    icon: const Text('🎰', style: TextStyle(fontSize: 16)),
                    label: Text(
                      tr.isId ? 'Putar Bite Roulette' : 'Spin Bite Roulette',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(String label, String prompt) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _navigateToApp(tabIndex: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, AppStrings tr, bool isDesktop) {
    final features = [
      {
        'icon': '🎭',
        'title': tr.isId ? 'Curhat Emosi & Voice AI' : 'Emotion & Voice Reasoning',
        'desc': tr.isId
            ? 'Ketik atau bicara langsung. Agentic ADK memetakan suasana hati ke profil rasa makanan (pedas, manis, asin, gurih).'
            : 'Type or speak your mood. Agentic ADK maps sentiment to flavor profiles (spicy, sweet, comforting umami).',
      },
      {
        'icon': '📍',
        'title': tr.isId ? 'Hyperlocal GPS & Status Buka' : 'Hyperlocal GPS & Live Hours',
        'desc': tr.isId
            ? 'Radius rekomendasi 10 km terintegrasi Google Places & OSM. Hanya menampilkan resto yang saat ini buka.'
            : '10km radius curation with Google Places & OSM fallback. Automatically filters restaurants open right now.',
      },
      {
        'icon': '🎰',
        'title': tr.isId ? 'Bite Roulette Gamification' : 'Bite Roulette Gamification',
        'desc': tr.isId
            ? 'Solusi ampuh saat bingung mau makan apa. Putar roda keberuntungan dan dapatkan menu rekomendasi seketika.'
            : 'Eliminates meal indecision. Spin the wheel to decide your next meal with fun audio-tactile excitement.',
      },
      {
        'icon': '🎟️',
        'title': tr.isId ? 'Voucher Diskon Presisi' : 'Precision Dynamic Voucher',
        'desc': tr.isId
            ? 'Klaim voucher merchant terdekat dengan timer hitung mundur riil untuk menghemat pengeluaran jajanmu.'
            : 'Claim exclusive local merchant discounts with real countdown timers to maximize your dining savings.',
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                tr.isId ? 'Mengapa Memilih MoodEats?' : 'Why MoodEats?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr.isId
                    ? 'Ekosistem kuliner pintar yang mengerti kebutuhan fisik dan emosionalmu.'
                    : 'An intelligent culinary ecosystem attuned to your physical cravings and emotional needs.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 36),

              // Feature Grid
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: features.map((f) {
                  return Container(
                    width: isDesktop ? 250 : double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['icon']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 16),
                        Text(
                          f['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          f['desc']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context, AppStrings tr, bool isDesktop) {
    final steps = [
      {
        'step': '01',
        'title': tr.isId ? 'Curhatkan Mood-mu' : 'Express Your Mood',
        'desc': tr.isId
            ? 'Ketik curhatan, gunakan perintah suara, atau unggah foto makanan yang kamu dambakan.'
            : 'Type your thoughts, speak directly, or snap a photo of foods you are daydreaming about.',
      },
      {
        'step': '02',
        'title': tr.isId ? 'AI Menemukan Resto' : 'AI Reasoning & Match',
        'desc': tr.isId
            ? 'Gemini Flash mencocokkan emosimu dengan menu & restoran terdekat yang sedang buka.'
            : 'Gemini Flash matches your sentiment with optimal flavors and verified open local venues.',
      },
      {
        'step': '03',
        'title': tr.isId ? 'Klaim Voucher & Nikmati' : 'Claim Voucher & Enjoy',
        'desc': tr.isId
            ? 'Dapatkan potongan harga eksklusif dan kunjungi merchant favoritmu tanpa ribet.'
            : 'Redeem high-value merchant vouchers and treat yourself without dining hesitation.',
      },
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                tr.isId ? '3 Langkah Mudah' : '3 Simple Steps',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 32,
                runSpacing: 24,
                children: steps.map((s) {
                  return Container(
                    width: isDesktop ? 290 : double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['step']!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s['desc']!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context, AppStrings tr, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 48,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                tr.isId
                    ? 'Siap Menemukan Makanan yang Pas untuk Mood-mu?'
                    : 'Ready to Discover the Perfect Food for Your Mood?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr.isId
                    ? 'Buka aplikasi sekarang dan nikmati rekomendasi kuliner pintar tanpa hambatan.'
                    : 'Launch the application now and experience effortless autonomous culinary suggestions.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => _navigateToApp(tabIndex: 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
                child: Text(
                  tr.isId ? 'Buka MoodEats Sekarang 🚀' : 'Launch MoodEats Now 🚀',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppStrings tr, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A), // Dark Slate
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 32,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/moodeats_mascot.png', width: 28, height: 28, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text(
                'MoodEats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Autonomous Hyperlocal Sentiment Commerce & Culinary Discovery Engine',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => _navigateToApp(tabIndex: 0),
                child: const Text('Aplikasi Web', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              TextButton(
                onPressed: () {
                  launchUrl(Uri.parse('http://localhost:8081'), mode: LaunchMode.externalApplication);
                },
                child: const Text('Admin Portal (8081)', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BiteRouletteScreen()),
                  );
                },
                child: const Text('Bite Roulette', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 MoodEats • AI Builder Cup 2026',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
