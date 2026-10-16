import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/models/roulette_model.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/presentation/screens/results/results_screen.dart';
import 'package:moodeats_app/data/services/location_service.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/data/services/device_info_service.dart';
import 'package:moodeats_app/data/services/preferences_service.dart';
import 'package:moodeats_app/data/services/app_cache_service.dart';
import 'package:moodeats_app/presentation/widgets/bouncy_tap.dart';

class BiteRouletteScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const BiteRouletteScreen({super.key, this.isTab = false});

  @override
  ConsumerState<BiteRouletteScreen> createState() => _BiteRouletteScreenState();
}

class _BiteRouletteScreenState extends ConsumerState<BiteRouletteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _spinAnimation;
  double _currentRotation = 0.0;
  bool _isSpinning = false;
  RouletteItemModel? _selectedItem;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
  }

  void _spin(List<RouletteItemModel> items) {
    if (_isSpinning || items.isEmpty) return;

    final random = Random();
    final chosenIndex = random.nextInt(items.length);
    final targetItem = items[chosenIndex];

    final sliceAngle = (2 * pi) / items.length;
    final extraSpins = 5 + random.nextInt(3);
    final targetRotation = _currentRotation +
        (extraSpins * 2 * pi) +
        (items.length - chosenIndex) * sliceAngle;

    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    setState(() {
      _isSpinning = true;
      _selectedItem = null;
    });

    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _currentRotation = targetRotation % (2 * pi);
        _isSpinning = false;
        _selectedItem = targetItem;
      });
    });
  }

  Future<void> _searchForSelected(RouletteItemModel item, AppStrings tr) async {
    final itemLabel = item.displayLabel(tr.isId);
    final moodBenefit = item.displayMoodBenefit(tr.isId);
    final prompt = tr.isId
        ? 'Lagi bingung mau makan apa, hasil roulette: $itemLabel (${item.searchKeyword}). $moodBenefit'
        : 'Undecided what to eat, roulette result: $itemLabel (${item.searchKeyword}). $moodBenefit';
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(tr.isId
                    ? 'Mencari tempat terbaik sesuai roulette...'
                    : 'Finding best spots from roulette...'),
              ],
            ),
          ),
        ),
      ),
    );

    final userLoc = ref.read(userLocationProvider);
    final authUser = ref.read(firebaseAuthServiceProvider).currentUser;
    final telemetry = await DeviceInfoService.getTelemetry();
    final prefs = ref.read(userPreferencesProvider);
    try {
      final res = await ref.read(apiServiceProvider).getRecommendation(
        prompt: prompt,
        city: userLoc.cityName,
        lat: userLoc.latitude,
        lng: userLoc.longitude,
        userId: authUser?.id,
        isHalalOnly: prefs.isHalalOnly,
        dietaryType: prefs.dietaryType,
        allergies: prefs.allergies,
        onlyOpenNow: prefs.isOpenNowOnly,
        deviceOs: telemetry.os,
        appVersion: telemetry.appVersion,
      );

      // Refresh history state so new roulette result immediately appears in History tab
      ref.read(historyNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(response: res, userPrompt: prompt),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.isId ? 'Gagal: $e' : 'Failed: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rouletteAsync = ref.watch(rouletteItemsProvider);
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                '${tr.navRoulette} 🎲',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0.5,
              automaticallyImplyLeading: false,
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
          child: rouletteAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) {
              final cached = AppCacheService.getCachedRouletteItems();
              if (cached.isNotEmpty) {
                return _buildRouletteContent(cached, tr, isDesktop);
              }
              return Center(
                child: Text(tr.isId ? 'Gagal memuat roulette: $err' : 'Failed to load roulette: $err'),
              );
            },
            data: (items) {
              final effectiveItems = items.isNotEmpty ? items : AppCacheService.getCachedRouletteItems();
              if (effectiveItems.isEmpty) {
                return Center(child: Text(tr.isId ? 'Daftar roulette kosong' : 'Roulette list is empty'));
              }
              return _buildRouletteContent(effectiveItems, tr, isDesktop);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRouletteContent(List<RouletteItemModel> items, AppStrings tr, [bool isDesktop = false]) {
    return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Text(
                  tr.rouletteTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr.rouletteSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Roulette Wheel Stack
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Wheel
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            final angle = _isSpinning
                                ? _spinAnimation.value
                                : _currentRotation;
                            return Transform.rotate(
                              angle: angle,
                              child: _buildRouletteWheel(items, tr.isId),
                            );
                          },
                        ),
                      ),
                      // Center Emblem Button
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(color: AppColors.border, width: 3),
                          ),
                          child: const Center(
                            child: Text('🎲', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                      // Pointer at top of wheel
                      const Positioned(
                        top: 0,
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 46,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Spin Button
                BouncyTap(
                  scaleFactor: 0.95,
                  onTap: _isSpinning ? null : () => _spin(items),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSpinning ? null : () => _spin(items),
                      child: Text(
                        _isSpinning
                            ? (tr.isId ? 'Sedang Memutar...' : 'Spinning...')
                            : tr.spinWheelBtn,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Selected Item Card Result
                if (_selectedItem != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _selectedItem!.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedItem!.displayLabel(tr.isId),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedItem!.displayMoodBenefit(tr.isId),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: BouncyTap(
                            scaleFactor: 0.95,
                            onTap: () => _searchForSelected(_selectedItem!, tr),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _searchForSelected(_selectedItem!, tr),
                              child: Text(
                                tr.isId
                                    ? 'Cari Tempat Kuliner Ini Sekarang!'
                                    : 'Find Places for This Now!',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
  }

  Widget _buildRouletteWheel(List<RouletteItemModel> items, bool isId) {
    return Container(
      width: 290,
      height: 290,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _WheelPainter(items, isId),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<RouletteItemModel> items;
  final bool isId;

  _WheelPainter(this.items, this.isId);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = items.length;
    final sweepAngle = (2 * pi) / total;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < total; i++) {
      final startAngle = (i * sweepAngle) - (pi / 2);

      Color color;
      try {
        final hex = items[i].colorHex.replaceFirst('#', '0xFF');
        color = Color(int.parse(hex));
      } catch (_) {
        color = i % 2 == 0 ? AppColors.primary : AppColors.primaryDark;
      }

      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius * 0.68;
      final x = center.dx + textRadius * cos(textAngle);
      final y = center.dy + textRadius * sin(textAngle);

      final itemText = items[i].displayLabel(isId);
      final textSpan = TextSpan(
        text: '${items[i].emoji}\n$itemText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 70);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(textAngle + (pi / 2));
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
