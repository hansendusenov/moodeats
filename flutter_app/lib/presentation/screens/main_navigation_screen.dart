import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
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

    return PopScope(
      canPop: currentTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentTab != 0) {
          // Pressing Android back button on other tabs returns smoothly to Home (Tab 0)
          ref.read(mainTabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        body: Stack(
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentTab,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.redBg,
          elevation: 4,
          onDestinationSelected: (idx) {
            HapticFeedback.lightImpact();
            if (idx == 0 && currentTab == 0) {
              // Re-tapping Home when scrolled down scrolls smoothly to top
              final controller = ref.read(homeScrollControllerProvider);
              if (controller.hasClients && controller.offset > 0) {
                controller.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            } else if (idx == 2 && currentTab == 2) {
              // Re-tapping History when scrolled down scrolls smoothly to top (Requirement #4)
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
}

/// A wrapper widget that animates entry with a smooth, bouncy spring curve (Curves.easeOutBack)
/// and preserves full page state in memory without re-instantiation.
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
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        opacity: isSelected ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 320),
          curve: isSelected ? Curves.easeOutBack : Curves.easeInCubic,
          scale: isSelected ? 1.0 : 0.94,
          child: TickerMode(
            enabled: isSelected,
            child: child,
          ),
        ),
      ),
    );
  }
}
