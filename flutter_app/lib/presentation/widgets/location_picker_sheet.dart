import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/services/location_service.dart';

void showLocationPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required UserLocation currentLocation,
  required AppStrings tr,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  tr.culinaryLocation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${tr.isId ? "Saat ini" : "Current"}: ${currentLocation.displayLabel} (${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)})',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Max 10 km Delivery Radius Guarantee Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderRed),
              ),
              child: Row(
                children: [
                  const Text('🛵', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr.isId
                          ? 'Radius Rekomendasi: Maksimal 10 km dari lokasimu agar makanan lezat cepat sampai dan hemat ongkir Gojek / Grab.'
                          : 'Recommendation Radius: Max 10 km from your location for warm delivery and affordable courier rates.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: Text(
                  tr.detectGpsNow,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await ref.read(userLocationProvider.notifier).detectCurrentLocation();
                },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr.isId ? 'DKI Jakarta (5 Kota Administratif)' : 'DKI Jakarta (5 Administrative Cities)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCityChip(ctx, ref, 'Jakarta Utara', -6.1384, 106.8640),
                _buildCityChip(ctx, ref, 'Jakarta Pusat', -6.1754, 106.8272),
                _buildCityChip(ctx, ref, 'Jakarta Selatan', -6.2297, 106.8580),
                _buildCityChip(ctx, ref, 'Jakarta Barat', -6.1683, 106.7588),
                _buildCityChip(ctx, ref, 'Jakarta Timur', -6.2250, 106.9004),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              tr.isId ? 'Bodetabek & Kota Lain' : 'Greater Jakarta & Other Cities',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCityChip(ctx, ref, 'Tangerang / BSD', -6.3015, 106.6527),
                _buildCityChip(ctx, ref, 'Bekasi', -6.2383, 106.9756),
                _buildCityChip(ctx, ref, 'Depok', -6.4025, 106.7942),
                _buildCityChip(ctx, ref, 'Bogor', -6.5971, 106.8060),
                _buildCityChip(ctx, ref, 'Bandung', -6.9175, 107.6191),
                _buildCityChip(ctx, ref, 'Surabaya', -7.2575, 112.7521),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildCityChip(BuildContext ctx, WidgetRef ref, String name, double lat, double lng) {
  return ActionChip(
    label: Text(name, style: const TextStyle(fontSize: 12)),
    backgroundColor: AppColors.surfaceVariant,
    onPressed: () {
      ref.read(userLocationProvider.notifier).setManualLocation(
            latitude: lat,
            longitude: lng,
            cityName: name,
          );
      Navigator.of(ctx).pop();
    },
  );
}
