import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/presentation/screens/auth/complete_profile_screen.dart';
import 'package:moodeats_app/presentation/screens/auth/google_oauth_screen.dart';
import 'package:moodeats_app/presentation/screens/main_navigation_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(AppStrings tr) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.fillAllFields), backgroundColor: AppColors.primary),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.invalidEmail), backgroundColor: AppColors.primary),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.passwordMinLength), backgroundColor: AppColors.primary),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.passwordMismatch), backgroundColor: AppColors.primary),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authUserProvider.notifier).signUp(
            email: email,
            password: password,
            fullName: name,
          );

      if (mounted) {
        // Point 2: "Untuk lengkapi profil itu bisa nanti setelah daftar"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.registerCompleteProfileLater),
            backgroundColor: AppColors.happyGreen,
          ),
        );

        // Langsung masuk ke aplikasi, profil bisa dilengkapi nanti di tab Akun
        ref.read(mainTabProvider.notifier).state = 0;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
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
        if (result.isNewUser) {
          // Point 2: "Untuk lengkapi profil itu bisa nanti setelah daftar"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.registerCompleteProfileLater),
              backgroundColor: AppColors.happyGreen,
            ),
          );
          ref.read(mainTabProvider.notifier).state = 0;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          // Point 3: "Untuk login jika belum update profil baru bisa di arahkan bisa lengkapin profil."
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
              // Top Bar with Back Button & Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
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
              const SizedBox(height: 14),

              // Title & Subtitle
              Center(
                child: Text(
                  tr.registerTitle,
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
                  tr.registerSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form: Full Name
              Text(
                tr.fullName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: tr.fullNameHint,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
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
              const SizedBox(height: 12),

              // Form: Email
              Text(
                tr.email,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              const SizedBox(height: 12),

              // Form: Password
              Text(
                tr.password,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              const SizedBox(height: 12),

              // Form: Confirm Password
              Text(
                tr.confirmPassword,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: tr.passwordHint,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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

              // Register Button (Primary Red)
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
                  onPressed: _isLoading ? null : () => _handleRegister(tr),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          tr.registerBtn,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider "atau daftar dengan"
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
                        tr.googleSignUp,
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

              // Already have account prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr.alreadyHaveAccount,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      tr.loginNow,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
