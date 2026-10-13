import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/data/services/device_info_service.dart';
import 'package:moodeats_app/presentation/screens/main_navigation_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final bool allowSkip;
  const CompleteProfileScreen({super.key, this.allowSkip = true});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedBirthDate = '2000-01-01';
  String _selectedGender = 'Laki-laki';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    if (user != null) {
      if (user.displayName.isNotEmpty) {
        _nameController.text = user.displayName;
      }
      if (user.birthDate.isNotEmpty) _selectedBirthDate = user.birthDate;
      if (user.gender.isNotEmpty) _selectedGender = user.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile(AppStrings tr) async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (_selectedBirthDate.isEmpty || _selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.fillAllFields), backgroundColor: AppColors.primary),
      );
      return;
    }

    if (password.isNotEmpty) {
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
    }

    setState(() => _isLoading = true);

    try {
      final canonicalGender = tr.isFemale(_selectedGender) ? 'Perempuan' : 'Laki-laki';
      final updatedUser = await ref.read(authUserProvider.notifier).updateProfile(
            displayName: name.isNotEmpty ? name : null,
            birthDate: _selectedBirthDate,
            gender: canonicalGender,
            password: password.isNotEmpty ? password : null,
          );

      try {
        final telemetry = await DeviceInfoService.getTelemetry();
        await ref.read(apiServiceProvider).syncUserProfile(
              userId: updatedUser.id,
              email: updatedUser.email,
              displayName: updatedUser.displayName.isNotEmpty
                  ? updatedUser.displayName
                  : updatedUser.email.split('@').first,
              birthDate: updatedUser.birthDate,
              gender: updatedUser.gender,
              deviceModel: telemetry.model,
              deviceOs: telemetry.os,
              appVersion: telemetry.appVersion,
            );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.profileCompletedSuccess),
            backgroundColor: AppColors.happyGreen,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          ref.read(mainTabProvider.notifier).state = 0;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
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

  void _handleSkip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final user = ref.watch(authUserProvider);

    final email = user?.email ?? '';
    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : email.split('@').first;
    final isGoogleAuth = user?.authProvider == 'google';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Language Switcher on Top Right
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
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
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Header
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
                    child: Text('📝', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Center(
                child: Text(
                  tr.googleProfileTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  tr.googleProfileSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Current User Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.redBg,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            email,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.happyGreen, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            isGoogleAuth ? 'Google' : 'Email',
                            style: const TextStyle(
                              color: AppColors.happyGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name (Nama Lengkap)
              Text(
                tr.isId ? 'Nama Lengkap' : 'Full Name',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: tr.isId ? 'Masukkan nama lengkap kamu' : 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Date of Birth
              Text(
                tr.birthDate,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000, 1, 1),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedBirthDate =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedBirthDate,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Gender Selector
              Text(
                tr.gender,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(tr.genderMale)),
                      selected: tr.isMale(_selectedGender),
                      selectedColor: AppColors.redBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => setState(() => _selectedGender = 'Laki-laki'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(tr.genderFemale)),
                      selected: tr.isFemale(_selectedGender),
                      selectedColor: AppColors.redBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => setState(() => _selectedGender = 'Perempuan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Optional Password setup for Google users
              if (isGoogleAuth) ...[
                Text(
                  tr.setPasswordTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  tr.passwordNote,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: tr.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: tr.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : () => _handleSaveProfile(tr),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          tr.completeAndContinue,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Skip for now button
              if (widget.allowSkip)
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleSkip,
                    child: Text(
                      tr.skipForNow,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
