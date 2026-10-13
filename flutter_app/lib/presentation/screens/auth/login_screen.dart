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

        // Point 3: Jika belum update profil, arahkan ke lengkapin profil
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  // Language Switcher Button
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ref.read(appLanguageProvider.notifier).toggleLanguage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang == AppLanguage.id ? '🇮🇩' : '🇬🇧', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            lang == AppLanguage.id ? 'ID' : 'EN',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.sync_alt, size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Brand Icon
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.redBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderRed),
                  ),
                  child: const Center(
                    child: Text('🍲', style: TextStyle(fontSize: 34)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Center(
                child: Text(
                  tr.loginTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  tr.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              Text(
                tr.email,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: tr.emailHint,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Password Input
              Text(
                tr.password,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: tr.passwordHint,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign In Button (Primary Red)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : () => _handleLogin(tr),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          tr.loginBtn,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider "atau masuk dengan"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      tr.orDivider,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 20),

              // DIRECT GOOGLE OAUTH FIREBASE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0.5,
                  ),
                  onPressed: _isLoading ? null : () => _handleGoogleSignIn(tr),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tr.googleSignIn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Register Prompt Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr.noAccount,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
}
