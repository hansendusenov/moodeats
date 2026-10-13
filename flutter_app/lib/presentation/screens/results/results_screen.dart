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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                            data.detectedMood.toUpperCase(),
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
                    data.rationale,
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
    );
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
                            place.category,
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
