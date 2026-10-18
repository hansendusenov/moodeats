import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/location_service.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:moodeats_app/presentation/screens/auth/complete_profile_screen.dart';
import 'package:moodeats_app/presentation/screens/auth/login_screen.dart';
import 'package:moodeats_app/presentation/screens/landing/web_landing_screen.dart';
import 'package:moodeats_app/presentation/widgets/voucher_countdown_dialog.dart';
import 'package:moodeats_app/presentation/widgets/dietary_preferences_modal.dart';
import 'package:moodeats_app/presentation/widgets/bouncy_tap.dart';
import 'package:moodeats_app/data/services/preferences_service.dart';
import 'package:moodeats_app/data/services/device_info_service.dart';
import 'package:moodeats_app/data/services/app_cache_service.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    AppStrings tr,
  ) async {
    if (user == null) return;
    final initialName = (user.displayName.isNotEmpty && user.displayName.toLowerCase() != 'hansendusenov')
        ? user.displayName
        : (user.email == 'hansendusenov@gmail.com' ? 'Hansen Dusenov' : user.displayName);
    final controller = TextEditingController(text: initialName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr.isId ? 'Ubah Nama Lengkap' : 'Edit Full Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.isId
                  ? 'Masukkan nama lengkap kamu untuk profil dan sapaan beranda.'
                  : 'Enter your full name for profile and greetings.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: tr.isId ? 'Nama Lengkap' : 'Full Name',
                hintText: 'Misal: Hansen Dusenov',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(tr.isId ? 'Simpan' : 'Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != user.displayName) {
      final updated = await ref.read(authUserProvider.notifier).updateDisplayName(newName);
      final telemetry = await DeviceInfoService.getTelemetry();
      final prefs = ref.read(userPreferencesProvider);
      await ref.read(apiServiceProvider).syncUserProfile(
        userId: updated.id,
        email: updated.email,
        displayName: updated.displayName,
        birthDate: updated.birthDate,
        gender: updated.gender,
        deviceModel: telemetry.model,
        deviceOs: telemetry.os,
        appVersion: telemetry.appVersion,
        isHalalOnly: prefs.isHalalOnly,
        dietaryType: prefs.dietaryType,
        allergies: prefs.allergies,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.isId
                ? 'Nama lengkap berhasil diperbarui!'
                : 'Full name updated successfully!'),
            backgroundColor: AppColors.happyGreen,
          ),
        );
      }
    }
  }

  void _handleClearCache(BuildContext context, AppLanguage lang) {
    final count = AppCacheService.purgeAllCache();
    final isId = lang == AppLanguage.id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isId
              ? 'Cache offline berhasil dibersihkan ($count file dihapus)!'
              : 'Offline cache purged successfully ($count files deleted)!',
        ),
        backgroundColor: AppColors.happyGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    AppLanguage lang,
  ) async {
    final isId = lang == AppLanguage.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            Text(
              isId ? 'Permohonan Hapus Akun' : 'Request Account Deletion',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isId
                  ? 'Sesuai UU Pelindungan Data Pribadi (UU PDP No. 27/2022 Pasal 43 Hak Penghapusan):'
                  : 'In compliance with Data Protection Law (UU PDP No. 27/2022 Article 43):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              isId
                  ? '''- Masa Tenggang 30 Hari: Akun Anda akan dinonaktifkan sementara. Anda dapat membatalkan permohonan ini kapan saja dalam 30 hari dengan login kembali.\n\n- Crypto-Shredding Permanen: Setelah 30 hari, seluruh data pribadi (nama, surel, telepon, profil) akan di-crypto-shred dan sesi analitik di-unlink permanen.\n\n- Cache Lokal: Seluruh file cache offline pada perangkat ini akan langsung dihapus.'''
                  : '''- 30-Day Grace Period: Your account will be temporarily deactivated. You can cancel this request anytime within 30 days by signing in again.\n\n- Permanent Crypto-Shredding: After 30 days, all personal identifiers will be permanently crypto-shredded and analytics unlinked.\n\n- Local Cache: All offline cache files on this device will be immediately wiped.''',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              isId ? 'Batal' : 'Cancel',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isId ? 'Ajukan Penghapusan' : 'Submit Deletion',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.requestAccountDeletion(user.id);
        ref.read(mainTabProvider.notifier).state = 0;
        await ref.read(authUserProvider.notifier).signOut();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isId
                    ? 'Permohonan penghapusan akun dicatat. Masa tenggang aktif selama 30 hari.'
                    : 'Account deletion requested. 30-day grace period is now active.',
              ),
              backgroundColor: Colors.amber.shade800,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => kIsWeb ? const WebLandingScreen() : const LoginScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref, AppStrings tr) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.logoutConfirmTitle),
        content: Text(tr.logoutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr.logout),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      ref.read(mainTabProvider.notifier).state = 0;
      await ref.read(authUserProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => kIsWeb ? const WebLandingScreen() : const LoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final user = ref.watch(authUserProvider);
    final userLocation = ref.watch(userLocationProvider);
    final voucherState = ref.watch(activeVoucherProvider);
    final userVouchersAsync = ref.watch(userVouchersProvider);
    final userPreferences = ref.watch(userPreferencesProvider);

    final rawName = user?.displayName ?? '';
    final displayName = (rawName.isNotEmpty && rawName.toLowerCase() != 'hansendusenov')
        ? rawName
        : (user?.email == 'hansendusenov@gmail.com' ? 'Hansen Dusenov' : (rawName.isNotEmpty ? rawName : (user?.email.split('@').first ?? 'Pengguna MoodEats')));
    final email = user?.email ?? '-';
    final birthDate = user?.birthDate.isNotEmpty == true ? user!.birthDate : '-';
    final gender = tr.formatGender(user?.gender);
    final isProfileComplete = user?.isProfileComplete ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                tr.accountTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: false,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 960 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 20.0,
                vertical: isDesktop ? 28.0 : 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    Row(
                      children: [
                        const Text('👤', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Text(
                          tr.accountTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
              // User Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.redBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderRed),
                          ),
                          child: const Center(
                            child: Text(
                              '👤',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                    tooltip: tr.isId ? 'Ubah Nama Lengkap' : 'Edit Full Name',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showEditNameDialog(context, ref, user, tr),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),
                    // Detail info: Tanggal Lahir & Kelamin
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.birthDate,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                birthDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: birthDate == '-' ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.gender,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                gender,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: gender == '-' ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CompleteProfileScreen(allowSkip: false),
                              ),
                            );
                          },
                          child: Text(
                            tr.editProfile,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Incomplete Profile Alert Card
              if (!isProfileComplete)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // Warm amber banner
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.profileIncomplete,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr.profileIncompleteDesc,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CompleteProfileScreen(allowSkip: false),
                            ),
                          );
                        },
                        child: Text(
                          tr.completeProfileNow,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isProfileComplete) const SizedBox(height: 16),

              // Language Switcher Section (Dedicated Card)
              Text(
                tr.languageSetting,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.languageSetting,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang == AppLanguage.id ? 'Bahasa Indonesia' : 'English',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Language Switch Buttons
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          BouncyTap(
                            scaleFactor: 0.9,
                            onTap: () {
                              ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: lang == AppLanguage.id ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇮🇩', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: lang == AppLanguage.id ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          BouncyTap(
                            scaleFactor: 0.9,
                            onTap: () {
                              ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: lang == AppLanguage.en ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇬🇧', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: lang == AppLanguage.en ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status & Info Section
              Text(
                tr.statusAndServices,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // GPS Info Card
              _buildSettingCard(
                icon: Icons.my_location_rounded,
                title: tr.activeGpsLocation,
                subtitle: userLocation.displayLabel.isEmpty
                    ? (lang == AppLanguage.id ? 'Mendeteksi...' : 'Detecting...')
                    : '${userLocation.displayLabel} (${userLocation.latitude.toStringAsFixed(3)}, ${userLocation.longitude.toStringAsFixed(3)})',
                trailing: TextButton(
                  onPressed: () {
                    ref.read(userLocationProvider.notifier).detectCurrentLocation();
                  },
                  child: Text(tr.refresh, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 10),

              // Voucher Status Card
              _buildSettingCard(
                icon: Icons.confirmation_number_outlined,
                title: lang == AppLanguage.id ? 'Voucher & Kupon Saya' : 'My Vouchers & Promos',
                subtitle: voucherState.isActive
                    ? '${voucherState.voucherCode} (${voucherState.discountText ?? ""}) • ${voucherState.formattedTime}'
                    : userVouchersAsync.when(
                        data: (list) => list.isNotEmpty
                            ? '${list.length} Kupon Aktif • ${list.first['voucher_code']} (${list.first['discount_description']})'
                            : tr.noActiveVoucher,
                        loading: () => lang == AppLanguage.id ? 'Memeriksa kupon...' : 'Checking vouchers...',
                        error: (_, __) => tr.noActiveVoucher,
                      ),
                trailing: TextButton(
                  onPressed: () => _showVouchersModal(context, ref, user, tr, lang),
                  child: Text(
                    lang == AppLanguage.id ? 'Kelola' : 'Manage',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                onTap: () => _showVouchersModal(context, ref, user, tr, lang),
              ),
              const SizedBox(height: 10),

              // Dietary & Food Preferences Card
              _buildSettingCard(
                icon: Icons.restaurant_menu_rounded,
                title: lang == AppLanguage.id ? 'Preferensi Makanan & Diet' : 'Dietary Preferences',
                subtitle: userPreferences.getSummaryText(lang),
                trailing: TextButton(
                  onPressed: () => DietaryPreferencesModal.show(context, lang),
                  child: Text(
                    lang == AppLanguage.id ? 'Ubah' : 'Edit',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                onTap: () => DietaryPreferencesModal.show(context, lang),
              ),
              const SizedBox(height: 10),

              // App Version Card
              _buildSettingCard(
                icon: Icons.info_outline_rounded,
                title: tr.appVersion,
                subtitle: 'MoodEats v1.0.0',
              ),
              const SizedBox(height: 28),

              // Privasi Data & Penyimpanan Offline (UU PDP No. 27/2022)
              Text(
                lang == AppLanguage.id ? 'Privasi Data & Penyimpanan (UU PDP)' : 'Data Privacy & Storage (PDP Law)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Bersihkan Cache Card
              _buildSettingCard(
                icon: Icons.cleaning_services_rounded,
                title: lang == AppLanguage.id ? 'Bersihkan Cache Offline' : 'Clear Offline Cache',
                subtitle: lang == AppLanguage.id
                    ? 'Hapus file cache JSON offline pada penyimpanan perangkat'
                    : 'Purge local offline JSON cache files from device storage',
                trailing: TextButton(
                  onPressed: () => _handleClearCache(context, lang),
                  child: Text(
                    lang == AppLanguage.id ? 'Bersihkan' : 'Purge',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                onTap: () => _handleClearCache(context, lang),
              ),
              const SizedBox(height: 10),

              // Hak Penghapusan Akun (Right to Erasure)
              if (user != null)
                _buildSettingCard(
                  icon: Icons.person_remove_outlined,
                  title: lang == AppLanguage.id ? 'Permohonan Hapus Akun' : 'Request Account Deletion',
                  subtitle: lang == AppLanguage.id
                      ? 'Masa tenggang 30 hari & crypto-shredding (UU PDP Pasal 43)'
                      : '30-day grace period & crypto-shredding (PDP Article 43)',
                  trailing: TextButton(
                    onPressed: () => _handleDeleteAccount(context, ref, user, lang),
                    child: Text(
                      lang == AppLanguage.id ? 'Ajukan' : 'Request',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                  onTap: () => _handleDeleteAccount(context, ref, user, lang),
                ),
              if (user != null) const SizedBox(height: 24),

              // Logout Button
              BouncyTap(
                scaleFactor: 0.96,
                onTap: () => _handleLogout(context, ref, tr),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      tr.logout,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () => _handleLogout(context, ref, tr),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ),
  );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleFactor: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showVouchersModal(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    AppStrings tr,
    AppLanguage lang,
  ) {
    if (user != null && user.id.isNotEmpty) {
      ref.invalidate(userVouchersProvider);
      ref.read(activeVoucherProvider.notifier).fetchUserVouchers(user.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Consumer(
        builder: (ctx, ref, _) {
          final vouchersAsync = ref.watch(userVouchersProvider);
          final voucherState = ref.watch(activeVoucherProvider);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.redBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == AppLanguage.id ? 'Koleksi Voucher Saya' : 'My Vouchers',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                lang == AppLanguage.id
                                    ? 'Diskon khusus & promo yang kamu miliki'
                                    : 'Your exclusive discounts & promo codes',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                        tooltip: 'Refresh',
                        onPressed: () {
                          if (user != null && user.id.isNotEmpty) {
                            ref.invalidate(userVouchersProvider);
                            ref.read(activeVoucherProvider.notifier).fetchUserVouchers(user.id, force: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Vouchers List
                Flexible(
                  child: vouchersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          lang == AppLanguage.id ? 'Gagal memuat voucher' : 'Failed to load vouchers',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    data: (vouchers) {
                      if (vouchers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.sentiment_neutral_rounded, size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                lang == AppLanguage.id ? 'Belum Ada Voucher' : 'No Vouchers Yet',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lang == AppLanguage.id
                                    ? 'Klaim voucher flash saat mencari rekomendasi kuliner atau tunggu promo spesial dari MoodEats!'
                                    : 'Claim flash vouchers during food recommendations or stay tuned for special promos!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: vouchers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (itemCtx, index) {
                          final v = vouchers[index];
                          final code = v['voucher_code']?.toString() ?? 'VIP';
                          final merchantName = v['merchant_name']?.toString() ?? 'MoodEats Special Promo';
                          final discountDesc = v['discount_description']?.toString() ?? 'Diskon Spesial';
                          final secondsRemaining = (v['seconds_remaining'] as num?)?.toInt() ?? 0;
                          final isCurrentlyActive = voucherState.isActive && voucherState.voucherCode == code;

                          String remainingStr;
                          if (secondsRemaining > 0) {
                            final days = secondsRemaining ~/ 86400;
                            final hrs = (secondsRemaining % 86400) ~/ 3600;
                            final mins = (secondsRemaining % 3600) ~/ 60;
                            final secs = secondsRemaining % 60;
                            final hh = hrs.toString().padLeft(2, '0');
                            final mm = mins.toString().padLeft(2, '0');
                            final ss = secs.toString().padLeft(2, '0');
                            remainingStr = '${days}D : $hh:$mm:$ss';
                          } else {
                            remainingStr = lang == AppLanguage.id ? 'Kedaluwarsa' : 'Expired';
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: isCurrentlyActive ? AppColors.redBg.withValues(alpha: 0.5) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrentlyActive ? AppColors.primary : Colors.grey.shade200,
                                width: isCurrentlyActive ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCurrentlyActive ? AppColors.primary : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isCurrentlyActive
                                              ? '🔥 SEDANG AKTIF (${voucherState.formattedTime})'
                                              : '🎟️ BERLAKU',
                                          style: TextStyle(
                                            color: isCurrentlyActive ? Colors.white : AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '⏱️ $remainingStr',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: secondsRemaining < 3600 ? Colors.red : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    merchantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    discountDesc,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                code,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  letterSpacing: 1.2,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: code));
                                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                                    SnackBar(
                                                      content: Text('${tr.codeCopied}: $code'),
                                                      duration: const Duration(seconds: 2),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      tr.copyCode,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isCurrentlyActive)
                                        ElevatedButton(
                                          onPressed: () {
                                            ref.read(activeVoucherProvider.notifier).activateVoucherDirectly(
                                                  merchantName: merchantName,
                                                  voucherCode: code,
                                                  discountText: discountDesc,
                                                  secondsRemaining: secondsRemaining,
                                                  merchantId: v['merchant_id']?.toString(),
                                                );
                                            Navigator.of(ctx).pop();
                                            showDialog(
                                              context: context,
                                              builder: (_) => VoucherCountdownDialog(
                                                merchantName: merchantName,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            lang == AppLanguage.id ? 'Gunakan' : 'Use',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        )
                                      else
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            showDialog(
                                              context: context,
                                              builder: (_) => VoucherCountdownDialog(
                                                merchantName: merchantName,
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.primary),
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            lang == AppLanguage.id ? 'Timer' : 'Timer',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
