import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/models/history_session_model.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/data/services/app_cache_service.dart';
import 'package:moodeats_app/presentation/screens/results/results_screen.dart';
import 'package:moodeats_app/presentation/widgets/voucher_countdown_dialog.dart';
import 'package:moodeats_app/presentation/widgets/bouncy_tap.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ctrl = ref.read(historyScrollControllerProvider);
        ctrl.removeListener(_onScroll);
        ctrl.addListener(_onScroll);
        ref.read(historyNotifierProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    final ctrl = ref.read(historyScrollControllerProvider);
    ctrl.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final ctrl = ref.read(historyScrollControllerProvider);
    if (ctrl.hasClients &&
        ctrl.position.pixels >=
            ctrl.position.maxScrollExtent - 200) {
      ref.read(historyNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _pickDateRange(HistoryState historyState, bool isId) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: historyState.startDate != null && historyState.endDate != null
          ? DateTimeRange(start: historyState.startDate!, end: historyState.endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(historyNotifierProvider.notifier).filterDateRange(picked.start, picked.end);
    }
  }

    Future<void> _confirmClearHistory(WidgetRef ref, AppLanguage lang) async {
    final isId = lang == AppLanguage.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              isId ? 'Hapus Riwayat Pencarian?' : 'Clear Search History?',
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
                  ? 'Sesuai UU Pelindungan Data Pribadi (UU PDP No. 27/2022 Pasal 43):'
                  : 'In compliance with Data Protection Law (UU PDP No. 27/2022):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              isId
                  ? '''- Seluruh riwayat pencarian Anda akan diputus (unlinked, user_id = NULL) dari profil akun Anda di server.\n- File cache offline pada penyimpanan perangkat akan langsung dihapus.\n- Metrik tren rekomendasi mitra tetap akurat secara agregat anonim.'''
                  : '''- Your search history will be unlinked (user_id = NULL) on the server.\n- Offline cache files on this device will be immediately wiped.\n- Merchant aggregate trend metrics remain preserved anonymously.''',
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isId ? 'Hapus & Bersihkan Cache' : 'Delete & Clear Cache',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final user = ref.read(authUserProvider);
      final api = ref.read(apiServiceProvider);
      if (user != null) {
        await api.clearHistory(user.id);
      } else {
        AppCacheService.purgeHistory('guest');
      }
      ref.read(historyNotifierProvider.notifier).clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isId
                ? 'Riwayat berhasil dihapus & cache offline dibersihkan!'
                : 'History cleared & offline cache purged successfully!',
          ),
          backgroundColor: AppColors.happyGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucherState = ref.watch(activeVoucherProvider);
    final historyState = ref.watch(historyNotifierProvider);
    final historyScrollController = ref.watch(historyScrollControllerProvider);
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
                tr.historyTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: false,
              actions: [
                if (historyState.items.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textSecondary),
                    tooltip: lang == AppLanguage.id ? 'Hapus Riwayat' : 'Clear History',
                    onPressed: () => _confirmClearHistory(ref, lang),
                  ),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 960 : double.infinity),
            child: SingleChildScrollView(
              controller: historyScrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 20.0,
                vertical: isDesktop ? 28.0 : 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('📜', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Text(
                              tr.historyTitle,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (historyState.items.isNotEmpty)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.borderRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                            label: Text(lang == AppLanguage.id ? 'Hapus Riwayat' : 'Clear History'),
                            onPressed: () => _confirmClearHistory(ref, lang),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
              // Active Voucher Section (if any)
              if (voucherState.isActive) ...[
                Text(
                  tr.activeVoucherSection,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => VoucherCountdownDialog(
                        merchantName: voucherState.merchantName ?? 'Restoran Pilihan',
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🎟️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                voucherState.merchantName ?? 'Voucher Spesial Mood',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                voucherState.formattedTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kode: ${voucherState.voucherCode ?? "MOOD15"} • ${voucherState.discountText ?? "Diskon 15%"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr.isId
                              ? 'Ketuk untuk melihat detail countdown atau salin kode kasir.'
                              : 'Tap to view countdown details or copy cashier code.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Header & Refresh Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.recentRecommendations,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (historyState.total > 0)
                          Text(
                            tr.isId
                                ? '${historyState.items.length} dari ${historyState.total} riwayat'
                                : '${historyState.items.length} of ${historyState.total} records',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      ref.read(historyNotifierProvider.notifier).refresh();
                      final user = ref.read(authUserProvider);
                      if (user != null && user.id.isNotEmpty) {
                        ref.read(activeVoucherProvider.notifier).fetchUserVouchers(user.id, force: true);
                        ref.invalidate(userVouchersProvider);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Date Filter Bar (Hari Ini, Rentang Tanggal, Semua)
              _buildDateFilterBar(historyState, tr.isId),
              const SizedBox(height: 16),

              // Content Section
              if (historyState.isLoading && historyState.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (historyState.error != null && historyState.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          tr.isId ? 'Gagal memuat riwayat' : 'Failed to load history',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.read(historyNotifierProvider.notifier).refresh(),
                          child: Text(tr.isId ? 'Coba Lagi' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (historyState.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        Text(
                          historyState.isTodayOnly
                              ? (tr.isId ? 'Belum ada konsultasi hari ini' : 'No consultations today')
                              : tr.noHistoryYet,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          historyState.isTodayOnly
                              ? (tr.isId
                                  ? 'Coba cek hari lain melalui filter tanggal di atas.'
                                  : 'Try checking other dates using the filter above.')
                              : tr.emptyHistorySub,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Column(
                  children: historyState.items.map((item) {
                    final timeStr = _formatTimeAgo(item.createdAt, tr.isId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryCard(
                        item: item,
                        timeAgo: timeStr,
                        isId: tr.isId,
                        onTap: () {
                          final rec = item.toRecommendationResponse();
                          if (rec != null) {
                            // Replay cached recommendation directly: 0 AI API call, 0 latency!
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResultsScreen(
                                  response: rec,
                                  userPrompt: item.title,
                                ),
                              ),
                            );
                          } else {
                            // Fallback if legacy record had no cached payload
                            ref.read(recommendationProvider.notifier).searchMood(prompt: item.title);
                            ref.read(mainTabProvider.notifier).state = 0;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),

                // Lazy Loading Indicator or Button
                if (historyState.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                      ),
                    ),
                  )
                else if (historyState.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.borderRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: Text(tr.isId ? 'Muat Lebih Banyak' : 'Load More'),
                        onPressed: () => ref.read(historyNotifierProvider.notifier).loadMore(),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const Text('🍜', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 10),
                    Text(
                      tr.isId ? 'Mau rekomendasi kuliner baru?' : 'Want new food recommendations?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr.emptyHistorySub,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: Text(tr.isId ? 'Cari Kuliner Mood Baru' : 'Find New Mood Food'),
                      onPressed: () {
                        ref.read(mainTabProvider.notifier).state = 0;
                      },
                    ),
                  ],
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

  Widget _buildDateFilterBar(HistoryState historyState, bool isId) {
    String rangeLabel;
    if (historyState.startDate != null && historyState.endDate != null) {
      final s = historyState.startDate!;
      final e = historyState.endDate!;
      rangeLabel = '${s.day}/${s.month} - ${e.day}/${e.month}';
    } else {
      rangeLabel = isId ? 'Pilih Rentang' : 'Date Range';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Hari Ini Filter Pill
          _buildFilterChip(
            label: isId ? 'Hari Ini' : 'Today',
            icon: Icons.today_rounded,
            isSelected: historyState.isTodayOnly,
            onTap: () => ref.read(historyNotifierProvider.notifier).filterToday(),
          ),
          const SizedBox(width: 8),

          // Date Range Filter Pill
          _buildFilterChip(
            label: rangeLabel,
            icon: Icons.calendar_month_outlined,
            isSelected: !historyState.isTodayOnly && historyState.startDate != null,
            onTap: () => _pickDateRange(historyState, isId),
          ),
          const SizedBox(width: 8),

          // Semua Filter Pill
          _buildFilterChip(
            label: isId ? 'Semua' : 'All',
            icon: Icons.all_inclusive_rounded,
            isSelected: !historyState.isTodayOnly && historyState.startDate == null,
            onTap: () => ref.read(historyNotifierProvider.notifier).filterAll(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleFactor: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required HistorySessionModel item,
    required String timeAgo,
    required bool isId,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleFactor: 0.96,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.redBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.detectedMood,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          if (item.hasCachedResponse) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on_rounded, size: 11, color: Colors.green.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    isId ? 'Hasil Siap' : 'Instant',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.restaurant,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    if (item.hasVoucher) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.confirmation_number_outlined, size: 13, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        isId ? 'Voucher' : 'Voucher',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }

  String _formatTimeAgo(DateTime? dt, bool isId) {
    if (dt == null) return isId ? 'Baru saja' : 'Just now';
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return isId ? 'Baru saja' : 'Just now';
    if (diff.inMinutes < 60) return isId ? '${diff.inMinutes} menit lalu' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isId ? '${diff.inHours} jam lalu' : '${diff.inHours}h ago';
    return isId ? '${diff.inDays} hari lalu' : '${diff.inDays}d ago';
  }
}
