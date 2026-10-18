import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/models/recommendation_model.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/presentation/widgets/voucher_countdown_dialog.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/data/services/preferences_service.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final RecommendationResponse response;
  final String userPrompt;

  const ResultsScreen({
    super.key,
    required this.response,
    required this.userPrompt,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late bool _filterOpenOnly;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(userPreferencesProvider);
    _filterOpenOnly = prefs.isOpenNowOnly;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.response.data;
    final userPrompt = widget.userPrompt;
    final allPlaces = data.places;
    final places = _filterOpenOnly
        ? allPlaces.where((p) => p.isOpen).toList()
        : allPlaces;
    final voucherState = ref.watch(activeVoucherProvider);
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          tr.resultsTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32.0 : 16.0,
              vertical: isDesktop ? 24.0 : 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Offline Mode Notice (if served from cache or offline)
            if (widget.response.status == 'offline_mode' || widget.response.status == 'success_cached') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Text('📶', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr.isId
                            ? 'Mode Offline Cerdas: Server tidak dapat dihubungi, menampilkan rekomendasi tersimpan dari cache perangkat.'
                            : 'Smart Offline Mode: Server unreachable, showing cached culinary recommendations.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // User Query Bubble
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💭', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.yourQuery,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '"$userPrompt"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Rationale Empathy Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderRed),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getLocalizedMood(data.detectedMood, userPrompt, tr.isId).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            tr.aiAnalysis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getLocalizedRationale(data.rationale, widget.userPrompt, tr.isId),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr.recommendedPlaces,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        tr.isId ? 'Maks 10 km' : 'Max 10 km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Open Now Interactive Filter Chip
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _filterOpenOnly = !_filterOpenOnly;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _filterOpenOnly ? const Color(0xFFEFF6FF) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _filterOpenOnly ? const Color(0xFF3B82F6) : AppColors.border,
                        width: _filterOpenOnly ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _filterOpenOnly ? '🕒' : '⚪',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tr.isId ? 'Buka Saja' : 'Open Only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _filterOpenOnly ? FontWeight.w800 : FontWeight.bold,
                            color: _filterOpenOnly ? const Color(0xFF1D4ED8) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Text(
                  '${places.length} ${tr.locationsCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Places List
            if (places.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        _filterOpenOnly && allPlaces.isNotEmpty
                            ? (tr.isId
                                ? 'Semua restoran rekomendasi sedang tutup saat ini.\nKlik tombol "Buka Saja" di atas untuk melihat semua restoran.'
                                : 'All recommended places are currently closed at this hour.\nTap "Open Only" above to see all restaurants.')
                            : tr.noPlacesFound,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...places.map((place) => _buildPlaceCard(context, ref, place, voucherState, tr)),

            // Home Recipes Section (if available)
            if (data.homeRecipes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                tr.homeCookingIdeas,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.homeRecipes
                      .map((recipe) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 16, color: AppColors.happyGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recipe,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  ),
  );
  }

  bool _isEnglishText(String text) {
    if (text.trim().isEmpty) return false;
    final lower = ' ${text.toLowerCase()} ';
    final enMarkers = [
      ' i ', "i'm", "im ", "my ", "me ", "we ", "you ", "want", "craving", "need",
      "feel", "feeling", "hungry", "tired", "sad", "happy", "stress", "stressed",
      "cold", "warm", "hot", "good", "bad", "eat", "food", "late", "work", "working",
      "night", "dinner", "lunch", "breakfast", "something", "recommend", "recommendation",
      "soup", "coffee", "sweet", "spicy", "give", "please", "search", "best", "where",
      "comfort", "relax", "exhausted", "burnout", "overwhelmed", "after", "long", "day"
    ];
    int score = 0;
    for (final marker in enMarkers) {
      if (lower.contains(marker)) score++;
    }
    final idMarkers = [
      ' saya ', ' aku ', ' gue ', ' gw ', ' lagi ', ' pengen ', ' mau ', ' butuh ',
      ' lapar ', ' laper ', ' lelah ', ' capek ', ' cape ', ' stres ', ' sedih ',
      ' senang ', ' dingin ', ' anget ', ' hangat ', ' makan ', ' malam ', ' siang ',
      ' sarapan ', ' kerja ', ' lembur ', ' cari ', ' rekomendasi ', ' dong '
    ];
    int idScore = 0;
    for (final marker in idMarkers) {
      if (lower.contains(marker)) idScore++;
    }
    return score > idScore;
  }

  String _getLocalizedMood(String mood, String userPrompt, bool isId) {
    final shouldBeEnglish = !isId || _isEnglishText(userPrompt);
    if (!shouldBeEnglish) return mood;

    final lower = mood.toLowerCase();
    if (lower.contains('lelah') || lower.contains('capek') || lower.contains('exhaust') || lower.contains('lembur')) {
      return 'Overworked & Exhausted';
    }
    if (lower.contains('stres') || lower.contains('stress') || lower.contains('teriak')) {
      return 'Stressed & Overwhelmed';
    }
    if (lower.contains('sedih') || lower.contains('mellow') || lower.contains('galau') || lower.contains('sad')) {
      return 'Mellow & Seeking Comfort';
    }
    if (lower.contains('senang') || lower.contains('happy') || lower.contains('gembira')) {
      return 'Celebratory & Joyful';
    }
    if (lower.contains('bosan') || lower.contains('bored')) {
      return 'Bored & Seeking Adventure';
    }
    if (lower.contains('hangat') || lower.contains('comfort')) {
      return 'Warm Comfort Seeking';
    }
    if (lower.contains('lapar') || lower.contains('hungry')) {
      return 'Hungry & Seeking Comfort';
    }
    return mood;
  }

  String _getLocalizedRationale(String rationale, String userPrompt, bool isId) {
    final shouldBeEnglish = !isId || _isEnglishText(userPrompt);
    if (!shouldBeEnglish) return rationale;

    final lowerR = rationale.toLowerCase();
    final lowerP = userPrompt.toLowerCase();
    final hasIndonesianWords = lowerR.contains('bekerja') ||
        lowerR.contains('tubuh') ||
        lowerR.contains('makanan') ||
        lowerR.contains('menenangkan') ||
        lowerR.contains('menguras') ||
        lowerR.contains('kehangatan') ||
        lowerR.contains('sehingga') ||
        lowerR.contains('lelah') ||
        lowerR.contains('rasa') ||
        lowerR.contains('energi') ||
        lowerR.contains('suasana') ||
        lowerR.contains('hati') ||
        lowerR.contains('membantu') ||
        lowerR.contains('pilihan') ||
        lowerR.contains('untuk') ||
        lowerR.contains('yang');

    if (!hasIndonesianWords) return rationale;

    if (lowerP.contains('late') || lowerP.contains('tired') || lowerP.contains('exhaust') || lowerR.contains('lelah') || lowerR.contains('lembur') || lowerR.contains('menguras')) {
      return 'Working late and fatigue deplete mental stamina and energy reserves. Warm, restorative savory dishes calm your nervous system, replenishing vitality and comforting your senses.';
    }
    if (lowerP.contains('stress') || lowerR.contains('stres') || lowerR.contains('tekanan')) {
      return 'Elevated stress triggers mental fatigue and sensory burnout. Rich flavors and savory aromas help stimulate endorphin release, melting away tension and restoring balanced focus.';
    }
    if (lowerP.contains('sad') || lowerP.contains('mellow') || lowerP.contains('down') || lowerR.contains('sedih') || lowerR.contains('galau')) {
      return 'During gentle, reflective moments, wholesome comfort food boosts serotonin and provides emotional warmth, wrapping your mood in tender satisfaction.';
    }
    if (lowerP.contains('cold') || lowerP.contains('rain') || lowerR.contains('dingin') || lowerR.contains('hangat')) {
      return 'Chilly weather calls for steaming broth and gentle spices. Warm, nourishing soups soothe the body and elevate your core temperature with pure comforting delight.';
    }
    if (lowerP.contains('happy') || lowerP.contains('celebrat') || lowerR.contains('senang') || lowerR.contains('gembira')) {
      return 'Celebratory moments call for vibrant, festive culinary delights that amplify positive energy and make sharing memorable meals a pure joy.';
    }
    return 'Your current mood is best complemented by authentic comfort food crafted to satisfy cravings and bring balanced warmth to your day.';
  }

  String _getLocalizedBadge(String badge, String userPrompt, bool isId) {
    final shouldBeEnglish = !isId || _isEnglishText(userPrompt);
    if (!shouldBeEnglish) return badge;

    String text = badge.trim();
    final lower = text.toLowerCase();

    // High priority phrase matches
    if (lower.contains('comfort food malam') || lower.contains('kuliner malam')) {
      return 'Late-Night Comfort Food';
    }
    if (lower.contains('kuah hangat rempah')) {
      return 'Spiced Warm Broth';
    }
    if (lower.contains('kuah hangat')) {
      return 'Soothing Warm Broth';
    }
    if (lower.contains('makan malam')) {
      return 'Cozy Dinner';
    }
    if (lower.contains('makan siang')) {
      return 'Hearty Lunch';
    }
    if (lower.contains('sarapan pagi') || lower.contains('sarapan ringan') || lower.contains('sarapan')) {
      return 'Morning Breakfast';
    }
    if (lower.contains('camilan sore') || lower.contains('cemilan sore')) {
      return 'Afternoon Bites';
    }
    if (lower.contains('pedas menggelegar')) {
      return 'Fiery Spicy Kick';
    }
    if (lower.contains('manis creamy')) {
      return 'Sweet & Creamy';
    }
    if (lower.contains('minuman penenang')) {
      return 'Soothing Drink';
    }
    if (lower.contains('rekomendasi sponsor')) {
      return 'Sponsored Pick';
    }

    // Word-level replacements
    text = text.replaceAll(RegExp(r'\bmalam\b', caseSensitive: false), 'Late-Night');
    text = text.replaceAll(RegExp(r'\bsiang\b', caseSensitive: false), 'Lunch');
    text = text.replaceAll(RegExp(r'\bpagi\b', caseSensitive: false), 'Morning');
    text = text.replaceAll(RegExp(r'\bsore\b', caseSensitive: false), 'Afternoon');
    text = text.replaceAll(RegExp(r'\bkuah\b', caseSensitive: false), 'Broth');
    text = text.replaceAll(RegExp(r'\bhangat\b', caseSensitive: false), 'Warm');
    text = text.replaceAll(RegExp(r'\bpedas\b', caseSensitive: false), 'Spicy');
    text = text.replaceAll(RegExp(r'\bmanis\b', caseSensitive: false), 'Sweet');
    text = text.replaceAll(RegExp(r'\brempah\b', caseSensitive: false), 'Spices');
    text = text.replaceAll(RegExp(r'\bgorengan\b', caseSensitive: false), 'Crispy Snacks');
    text = text.replaceAll(RegExp(r'\bkopi\b', caseSensitive: false), 'Coffee');
    text = text.replaceAll(RegExp(r'\bsusu\b', caseSensitive: false), 'Milk');
    text = text.replaceAll(RegExp(r'\bsegar\b', caseSensitive: false), 'Fresh');
    text = text.replaceAll(RegExp(r'\bkenyang\b', caseSensitive: false), 'Hearty');
    text = text.replaceAll(RegExp(r'\bcamilan\b', caseSensitive: false), 'Snacks');
    text = text.replaceAll(RegExp(r'\bcemilan\b', caseSensitive: false), 'Snacks');
    text = text.replaceAll(RegExp(r'\brekomendasi\b', caseSensitive: false), 'Recommended');
    text = text.replaceAll(RegExp(r'\bkuliner\b', caseSensitive: false), 'Culinary');

    // Clean up awkward combinations
    if (text.toLowerCase().contains('comfort food late-night') ||
        text.toLowerCase().contains('comfort food night')) {
      return 'Late-Night Comfort Food';
    }

    return text;
  }

  String _getLocalizedCategory(String category, String userPrompt, bool isId) {
    final shouldBeEnglish = !isId || _isEnglishText(userPrompt);
    if (!shouldBeEnglish) return category;

    final lower = category.toLowerCase();
    if (lower.contains('kuliner nusantara') || lower.contains('indonesian')) {
      return 'Indonesian Cuisine';
    }
    if (lower.contains('warung makan') || lower.contains('warteg')) {
      return 'Local Comfort Eatery';
    }
    if (lower.contains('kedai kopi') || lower.contains('kafe') || lower.contains('cafe')) {
      return 'Coffee & Cafe';
    }
    if (lower.contains('cepat saji') || lower.contains('fast food')) {
      return 'Fast Food';
    }
    if (lower.contains('restoran')) {
      return category.replaceAll(RegExp(r'restoran', caseSensitive: false), 'Restaurant');
    }
    return category;
  }

  Widget _buildPlaceCard(
    BuildContext context,
    WidgetRef ref,
    PlaceModel place,
    ActiveVoucherState voucherState,
    AppStrings tr,
  ) {
    final hasVoucher = place.voucher.hasVoucher;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: place.isSponsored ? AppColors.primaryLight : AppColors.border,
          width: place.isSponsored ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sponsored Banner Ribbon (wrapped in Expanded to prevent any overflow)
          if (place.isSponsored)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr.sponsoredMerchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Restaurant Photo Cover with Gradient Overlay & Status Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: place.isSponsored ? Radius.zero : const Radius.circular(17),
                  topRight: place.isSponsored ? Radius.zero : const Radius.circular(17),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 155,
                  child: Image.network(
                    place.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.redBg,
                      child: const Center(
                        child: Text('🍲', style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient Shade at Bottom of Photo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Floating Mood / Category Badge
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _getLocalizedBadge(place.moodBadge, widget.userPrompt, tr.isId),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Open/Closed Status
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: place.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        place.isOpen
                            ? (tr.isId ? 'Buka' : 'Open')
                            : (tr.isId ? 'Tutup' : 'Closed'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocalizedCategory(place.category, widget.userPrompt, tr.isId),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address & Distance
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${place.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                // Opening Hours & Open Status Badge
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: place.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: place.isOpen ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: place.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.isOpen
                                ? (tr.isId ? 'Buka Sekarang' : 'Open Now')
                                : (tr.isId ? 'Tutup' : 'Closed'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: place.isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (place.openingHours != null && place.openingHours!.isNotEmpty)
                      Text(
                        place.openingHours!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mood Matching Badge & Price
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.moodBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      place.priceRange,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Dynamic Flash Voucher Claim Button
                if (hasVoucher) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎟️', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.voucher.discountText ?? 'Diskon Flash 15%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              Text(
                                tr.valid15Min,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final mId = place.voucher.merchantId ?? place.id;
                            final authUser = ref.read(firebaseAuthServiceProvider).currentUser;
                            try {
                              await ref
                                  .read(activeVoucherProvider.notifier)
                                  .claimVoucher(
                                    merchantId: mId,
                                    merchantName: place.name,
                                    userId: authUser?.id,
                                  );

                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => VoucherCountdownDialog(
                                    merchantName: place.name,
                                    googleMapsUrl: place.actionLinks.googleMaps,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Voucher: $e'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(tr.claimVoucher, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                // Action Links (Google Maps & Delivery)
                Row(
                  children: [
                    if (place.actionLinks.googleMaps != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: Text(tr.openMaps, style: const TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final mapsUrl = place.actionLinks.googleMaps;
                            if (mapsUrl != null && mapsUrl.isNotEmpty) {
                              final uri = Uri.parse(mapsUrl);
                              try {
                                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                                }
                              } catch (_) {
                                await launchUrl(uri, mode: LaunchMode.platformDefault);
                              }
                            }
                          },
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AA13), // GoFood Green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.delivery_dining, size: 16),
                        label: Text(tr.orderDelivery, style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final deliveryUrl = (place.actionLinks.deliveryApp != null &&
                                  place.actionLinks.deliveryApp!.isNotEmpty &&
                                  !place.actionLinks.deliveryApp!.contains('gofood.link'))
                              ? place.actionLinks.deliveryApp!
                              : 'https://gofood.co.id/jakarta/search?q=${Uri.encodeComponent(place.name)}';
                          final uri = Uri.parse(deliveryUrl);
                          try {
                            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                              await launchUrl(uri, mode: LaunchMode.platformDefault);
                            }
                          } catch (_) {
                            try {
                              await launchUrl(uri, mode: LaunchMode.platformDefault);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr.isId
                                          ? 'Gagal membuka layanan pesan antar: $deliveryUrl'
                                          : 'Failed to open delivery app: $deliveryUrl',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
