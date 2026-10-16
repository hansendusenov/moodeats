import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/presentation/screens/home/home_screen.dart';
import 'package:moodeats_app/presentation/screens/roulette/bite_roulette_screen.dart';
import 'package:moodeats_app/presentation/screens/history/history_screen.dart';
import 'package:moodeats_app/presentation/screens/account/account_screen.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(mainTabProvider);
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final authUser = ref.watch(authUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return PopScope(
      canPop: currentTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentTab != 0) {
          ref.read(mainTabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        // If Desktop: Top Navigation Header (no bottom bar).
        // If Mobile: Standard AppBar handled by inner screens, with BottomNavigationBar.
        appBar: isDesktop
            ? _buildWebHeader(context, ref, currentTab, tr, lang, authUser)
            : null,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1200 : double.infinity,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BouncyTabScreen(
                  key: const ValueKey('tab_home'),
                  isSelected: currentTab == 0,
                  child: const HomeScreen(),
                ),
                _BouncyTabScreen(
                  key: const ValueKey('tab_roulette'),
                  isSelected: currentTab == 1,
                  child: const BiteRouletteScreen(isTab: true),
                ),
                _BouncyTabScreen(
                  key: const ValueKey('tab_history'),
                  isSelected: currentTab == 2,
                  child: const HistoryScreen(),
                ),
                _BouncyTabScreen(
                  key: const ValueKey('tab_account'),
                  isSelected: currentTab == 3,
                  child: const AccountScreen(),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: currentTab,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.redBg,
                elevation: 4,
                onDestinationSelected: (idx) {
                  HapticFeedback.lightImpact();
                  if (idx == 0 && currentTab == 0) {
                    final controller = ref.read(homeScrollControllerProvider);
                    if (controller.hasClients && controller.offset > 0) {
                      controller.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  } else if (idx == 2 && currentTab == 2) {
                    final historyController = ref.read(historyScrollControllerProvider);
                    if (historyController.hasClients && historyController.offset > 0) {
                      historyController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  } else {
                    ref.read(mainTabProvider.notifier).state = idx;
                  }
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home, color: AppColors.primary),
                    label: tr.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.casino_outlined),
                    selectedIcon: const Icon(Icons.casino, color: AppColors.primary),
                    label: tr.navRoulette,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.history_outlined),
                    selectedIcon: const Icon(Icons.history, color: AppColors.primary),
                    label: tr.navHistory,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person, color: AppColors.primary),
                    label: tr.navAccount,
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildWebHeader(
    BuildContext context,
    WidgetRef ref,
    int currentTab,
    AppStrings tr,
    AppLanguage lang,
    UserModel? authUser,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // Brand Logo
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => ref.read(mainTabProvider.notifier).state = 0,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/images/moodeats_mascot.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MoodEats',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Sentiment Commerce',
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

                  const SizedBox(width: 40),

                  // Center Navigation Tabs
                  _buildWebTabItem(ref, 0, currentTab, Icons.explore_rounded, tr.navHome),
                  const SizedBox(width: 8),
                  _buildWebTabItem(ref, 1, currentTab, Icons.casino_rounded, tr.navRoulette),
                  const SizedBox(width: 8),
                  _buildWebTabItem(ref, 2, currentTab, Icons.receipt_long_rounded, tr.navHistory),
                  const SizedBox(width: 8),
                  _buildWebTabItem(ref, 3, currentTab, Icons.person_rounded, tr.navAccount),

                  const Spacer(),

                  // Language Switcher
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ref.read(appLanguageProvider.notifier).toggleLanguage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  const SizedBox(width: 16),

                  // Active User Profile Badge
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => ref.read(mainTabProvider.notifier).state = 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentTab == 3 ? const Color(0xFFFEF2F2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: currentTab == 3 ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              authUser?.displayName.isNotEmpty == true
                                  ? authUser!.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            authUser?.displayName.isNotEmpty == true
                                ? authUser!.displayName
                                : 'Pengguna',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
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
        ),
      ),
    );
  }

  Widget _buildWebTabItem(
    WidgetRef ref,
    int index,
    int currentTab,
    IconData icon,
    String label,
  ) {
    final isSelected = currentTab == index;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(mainTabProvider.notifier).state = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncyTabScreen extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  const _BouncyTabScreen({
    super.key,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isSelected,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        opacity: isSelected ? 1.0 : 0.0,
        child: TickerMode(
          enabled: isSelected,
          child: child,
        ),
      ),
    );
  }
}
