import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';

class VoucherCountdownDialog extends ConsumerWidget {
  final String merchantName;
  final String? googleMapsUrl;

  const VoucherCountdownDialog({
    super.key,
    required this.merchantName,
    this.googleMapsUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voucherState = ref.watch(activeVoucherProvider);
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    tr.voucherFlash15,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Merchant Name
            Text(
              merchantName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              voucherState.discountText ?? (tr.isId ? 'Diskon Spesial 15%' : 'Special Discount 15%'),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Live Countdown Circle / Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    tr.remainingTime,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      voucherState.formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Voucher Code Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.isId ? 'KODE VOUCHER KASIR' : 'CASHIER VOUCHER CODE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voucherState.voucherCode ?? 'MOOD15',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                    tooltip: tr.copyCode,
                    onPressed: () {
                      final code = voucherState.voucherCode ?? '';
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr.codeCopied),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Disclaimer Note
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.voucherInstruction,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                if (googleMapsUrl != null && googleMapsUrl!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: Text(tr.routeMaps, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final uri = Uri.parse(googleMapsUrl!);
                        try {
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            await launchUrl(uri, mode: LaunchMode.platformDefault);
                          }
                        } catch (_) {
                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                        }
                      },
                    ),
                  ),
                if (googleMapsUrl != null && googleMapsUrl!.isNotEmpty)
                  const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr.understood, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                ref.read(activeVoucherProvider.notifier).cancelVoucher();
                Navigator.of(context).pop();
              },
              child: Text(
                tr.isId ? 'Batalkan Voucher' : 'Cancel / Discard Voucher',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
