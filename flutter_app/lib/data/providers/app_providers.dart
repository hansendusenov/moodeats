import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';
import '../models/menu_model.dart';
import '../models/recommendation_model.dart';
import '../models/roulette_model.dart';
import '../models/history_session_model.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/app_cache_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final homeScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final historyScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final res = await api.getBanners();
    if (res.isNotEmpty) return res;
  } catch (_) {}
  return AppCacheService.getCachedBanners();
});

final defaultMenusProvider = FutureProvider<List<MenuModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final res = await api.getDefaultMenus();
    if (res.isNotEmpty) return res;
  } catch (_) {}
  return AppCacheService.getCachedDefaultMenus();
});

final rouletteItemsProvider = FutureProvider<List<RouletteItemModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final res = await api.getRouletteItems();
    if (res.isNotEmpty) return res;
  } catch (_) {}
  return AppCacheService.getCachedRouletteItems();
});

class HistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<HistorySessionModel> items;
  final int total;
  final bool hasMore;
  final int offset;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isTodayOnly;

  const HistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.offset = 0,
    this.startDate,
    this.endDate,
    this.isTodayOnly = true,
  });

  HistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<HistorySessionModel>? items,
    int? total,
    bool? hasMore,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
    bool? isTodayOnly,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isTodayOnly: isTodayOnly ?? this.isTodayOnly,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final ApiService _api;
  final String? _userId;

  HistoryNotifier(this._api, this._userId) : super(const HistoryState()) {
    loadInitial();
  }

  String _formatDate(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null, offset: 0);
    try {
      final now = DateTime.now();
      final todayStr = _formatDate(now);
      final res = await _api.getHistorySessionsPage(
        userId: _userId,
        startDate: state.isTodayOnly
            ? todayStr
            : (state.startDate != null ? _formatDate(state.startDate!) : null),
        endDate: state.isTodayOnly
            ? todayStr
            : (state.endDate != null ? _formatDate(state.endDate!) : null),
        offset: 0,
        limit: 10,
      );
      state = state.copyWith(
        isLoading: false,
        items: res.items,
        total: res.total,
        hasMore: res.hasMore,
        offset: res.items.length,
      );
    } catch (e) {
      final cached = AppCacheService.getCachedHistory(_userId);
      state = state.copyWith(
        isLoading: false,
        error: cached.items.isNotEmpty ? null : e.toString(),
        items: cached.items.isNotEmpty ? cached.items : state.items,
        total: cached.items.isNotEmpty ? cached.total : state.total,
        hasMore: false,
      );
    }
  }

  Future<void> filterToday() async {
    state = const HistoryState(isTodayOnly: true, startDate: null, endDate: null);
    await loadInitial();
  }

  Future<void> filterDateRange(DateTime start, DateTime end) async {
    state = HistoryState(isTodayOnly: false, startDate: start, endDate: end);
    await loadInitial();
  }

  Future<void> filterAll() async {
    state = const HistoryState(isTodayOnly: false, startDate: null, endDate: null);
    state = state.copyWith(isLoading: true, error: null, offset: 0);
    try {
      final res = await _api.getHistorySessionsPage(
        userId: _userId,
        startDate: 'ALL',
        offset: 0,
        limit: 10,
      );
      state = state.copyWith(
        isLoading: false,
        items: res.items,
        total: res.total,
        hasMore: res.hasMore,
        offset: res.items.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final now = DateTime.now();
      final todayStr = _formatDate(now);
      final res = await _api.getHistorySessionsPage(
        userId: _userId,
        startDate: state.isTodayOnly
            ? todayStr
            : (state.startDate != null ? _formatDate(state.startDate!) : null),
        endDate: state.isTodayOnly
            ? todayStr
            : (state.endDate != null ? _formatDate(state.endDate!) : null),
        offset: state.offset,
        limit: 10,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...res.items],
        total: res.total,
        hasMore: res.hasMore,
        offset: state.offset + res.items.length,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> clearAll() async {
    state = const HistoryState(items: [], total: 0, hasMore: false);
  }
}

final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final user = ref.watch(authUserProvider);
  return HistoryNotifier(api, user?.id);
});

final historySessionsProvider =
    FutureProvider<List<HistorySessionModel>>((ref) async {
  final state = ref.watch(historyNotifierProvider);
  return state.items;
});

final userVouchersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final authUser = ref.watch(authUserProvider);
  if (authUser == null || authUser.id.isEmpty) return [];
  return api.getMyVouchers(authUser.id);
});

// Recommendation State
class RecommendationState {
  final bool isLoading;
  final String? error;
  final RecommendationResponse? response;
  final String? prompt;

  const RecommendationState({
    this.isLoading = false,
    this.error,
    this.response,
    this.prompt,
  });

  RecommendationState copyWith({
    bool? isLoading,
    String? error,
    RecommendationResponse? response,
    String? prompt,
  }) {
    return RecommendationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
      prompt: prompt ?? this.prompt,
    );
  }
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final ApiService _apiService;

  RecommendationNotifier(this._apiService) : super(const RecommendationState());

  Future<void> searchMood({
    required String prompt,
    double? lat,
    double? lng,
    String? city,
  }) async {
    state = state.copyWith(isLoading: true, error: null, prompt: prompt);
    try {
      final res = await _apiService.getRecommendation(
        prompt: prompt,
        lat: lat,
        lng: lng,
        city: city,
      );
      state = state.copyWith(isLoading: false, response: res);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clear() {
    state = const RecommendationState();
  }
}

final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return RecommendationNotifier(api);
});

// 15-Minute Countdown Voucher State
class ActiveVoucherState {
  final bool isActive;
  final String? merchantId;
  final String? merchantName;
  final String? voucherCode;
  final String? discountText;
  final int secondsRemaining;

  const ActiveVoucherState({
    this.isActive = false,
    this.merchantId,
    this.merchantName,
    this.voucherCode,
    this.discountText,
    this.secondsRemaining = 900,
  });

  String get formattedTime {
    final days = secondsRemaining ~/ 86400;
    final hours = (secondsRemaining % 86400) ~/ 3600;
    final minutes = (secondsRemaining % 3600) ~/ 60;
    final seconds = secondsRemaining % 60;

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    return '${days}D : $hh:$mm:$ss';
  }

  ActiveVoucherState copyWith({
    bool? isActive,
    String? merchantId,
    String? merchantName,
    String? voucherCode,
    String? discountText,
    int? secondsRemaining,
  }) {
    return ActiveVoucherState(
      isActive: isActive ?? this.isActive,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      voucherCode: voucherCode ?? this.voucherCode,
      discountText: discountText ?? this.discountText,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}

class ActiveVoucherNotifier extends StateNotifier<ActiveVoucherState> {
  final ApiService _apiService;
  Timer? _timer;

  ActiveVoucherNotifier(this._apiService) : super(const ActiveVoucherState());

  Future<void> claimVoucher({
    required String merchantId,
    required String merchantName,
    String? userId,
  }) async {
    try {
      final res = await _apiService.claimVoucher(
        merchantId: merchantId,
        userId: userId,
      );
      
      final voucherCode = res['voucher_code'] ?? 'MOOD15';
      final discount = res['discount_text'] ?? 'Diskon 15%';
      final remaining = (res['seconds_remaining'] as num?)?.toInt() ?? 900;

      _timer?.cancel();
      state = ActiveVoucherState(
        isActive: true,
        merchantId: merchantId,
        merchantName: merchantName,
        voucherCode: voucherCode,
        discountText: discount,
        secondsRemaining: remaining,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.secondsRemaining <= 1) {
          timer.cancel();
          state = const ActiveVoucherState(isActive: false, secondsRemaining: 0);
        } else {
          state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchUserVouchers(String userId, {bool force = false}) async {
    try {
      if (state.isActive && !force) return;
      final list = await _apiService.getMyVouchers(userId);
      if (list.isNotEmpty) {
        final top = list.first;
        final secondsLeft = (top['seconds_remaining'] as num?)?.toInt() ?? 0;
        if (secondsLeft > 0) {
          _timer?.cancel();
          state = ActiveVoucherState(
            isActive: true,
            merchantId: top['merchant_id']?.toString(),
            merchantName: top['merchant_name']?.toString() ?? 'MoodEats Special Promo',
            voucherCode: top['voucher_code']?.toString() ?? 'VIP',
            discountText: top['discount_description']?.toString() ?? 'Diskon Spesial',
            secondsRemaining: secondsLeft,
          );

          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (state.secondsRemaining <= 1) {
              timer.cancel();
              state = const ActiveVoucherState(isActive: false, secondsRemaining: 0);
            } else {
              state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetchUserVouchers: $e');
    }
  }

  void activateVoucherDirectly({
    required String merchantName,
    required String voucherCode,
    required String discountText,
    required int secondsRemaining,
    String? merchantId,
  }) {
    _timer?.cancel();
    state = ActiveVoucherState(
      isActive: true,
      merchantId: merchantId,
      merchantName: merchantName,
      voucherCode: voucherCode,
      discountText: discountText,
      secondsRemaining: secondsRemaining,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining <= 1) {
        timer.cancel();
        state = const ActiveVoucherState(isActive: false, secondsRemaining: 0);
      } else {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      }
    });
  }

  void cancelVoucher() {
    _timer?.cancel();
    state = const ActiveVoucherState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeVoucherProvider =
    StateNotifierProvider<ActiveVoucherNotifier, ActiveVoucherState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ActiveVoucherNotifier(api);
});

/// Global Main Navigation Bottom Bar Active Tab (0: Home, 1: Roulette, 2: History, 3: Account)
final mainTabProvider = StateProvider<int>((ref) => 0);
