import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/banner_model.dart';
import '../models/menu_model.dart';
import '../models/roulette_model.dart';
import '../models/history_session_model.dart';
import '../models/recommendation_model.dart';

class AppCacheService {
  static String? _baseDirPath;
  static final Map<String, dynamic> _memoryCache = {};

  static String get _storageDir {
    if (kIsWeb) return '';
    if (_baseDirPath != null) return _baseDirPath!;
    if (Platform.isAndroid) {
      final candidates = [
        '/data/user/0/com.moodeats.moodeats_app/app_flutter',
        '/data/user/0/com.moodeats.moodeats_app/files',
        '/data/data/com.moodeats.moodeats_app/app_flutter',
        '/data/data/com.moodeats.moodeats_app/files',
      ];
      for (final p in candidates) {
        final d = Directory(p);
        if (d.existsSync()) {
          _baseDirPath = p;
          return p;
        } else {
          try {
            d.createSync(recursive: true);
            _baseDirPath = p;
            return p;
          } catch (_) {}
        }
      }
    }
    _baseDirPath = Directory.systemTemp.path;
    return _baseDirPath!;
  }

  static File _getCacheFile(String key) {
    final sanitized = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('$_storageDir/moodeats_cache_$sanitized.json');
  }

  static void saveJson(String key, dynamic data) {
    _memoryCache[key] = data;
    if (kIsWeb) return;
    try {
      final file = _getCacheFile(key);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('AppCacheService.saveJson failed for $key: $e');
    }
  }

  static dynamic loadJson(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    if (kIsWeb) return null;
    try {
      final file = _getCacheFile(key);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          _memoryCache[key] = decoded;
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('AppCacheService.loadJson failed for $key: $e');
    }
    return null;
  }

  // --- Smart Offline Cache Sanitation (UU PDP No. 27/2022) ---

  /// Completely purges all offline cache files from device disk and wipes in-memory cache.
  /// Called upon logout, account deletion, or explicit cache wipe.
  static int purgeAllCache() {
    _memoryCache.clear();
    int purgedCount = 0;
    try {
      final dir = Directory(_storageDir);
      if (dir.existsSync()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File) {
            final fileName = entry.uri.pathSegments.last;
            if (fileName.startsWith('moodeats_cache_') && fileName.endsWith('.json')) {
              try {
                entry.deleteSync();
                purgedCount++;
              } catch (e) {
                debugPrint('AppCacheService: Failed deleting $fileName: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AppCacheService.purgeAllCache error: $e');
    }
    debugPrint('AppCacheService: Purged $purgedCount cache files from disk & cleared memory cache.');
    return purgedCount;
  }

  /// Purges cached search history for a user from both RAM and disk
  static void purgeHistory([String? userId]) {
    final key = 'history_${userId ?? "guest"}';
    _memoryCache.remove(key);
    try {
      final file = _getCacheFile(key);
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('AppCacheService: Purged local history cache file for ${userId ?? "guest"}');
      }
    } catch (e) {
      debugPrint('AppCacheService.purgeHistory error: $e');
    }
  }

  /// Returns statistics about cached files on disk (file count and total bytes)
  static Map<String, dynamic> getCacheStats() {
    int fileCount = 0;
    int totalBytes = 0;
    try {
      final dir = Directory(_storageDir);
      if (dir.existsSync()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File) {
            final fileName = entry.uri.pathSegments.last;
            if (fileName.startsWith('moodeats_cache_') && fileName.endsWith('.json')) {
              fileCount++;
              totalBytes += entry.lengthSync();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AppCacheService.getCacheStats error: $e');
    }
    return {
      'file_count': fileCount,
      'total_bytes': totalBytes,
      'in_memory_keys': _memoryCache.length,
    };
  }

  // --- Banners Cache ---

  static void cacheBanners(List<dynamic> rawBanners) {
    saveJson('banners', rawBanners);
  }

  static List<BannerModel> getCachedBanners() {
    final raw = loadJson('banners');
    if (raw is List && raw.isNotEmpty) {
      try {
        return raw.map((item) => BannerModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      } catch (e) {
        debugPrint('Error parsing cached banners: $e');
      }
    }
    return _defaultBanners();
  }

  static List<BannerModel> _defaultBanners() {
    return [
      BannerModel(
        id: 'default-1',
        title: 'Voucher Spesial MoodEats • Diskon 30% Merchant Pilihan',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
        targetingType: 'global',
        priority: 1,
      ),
      BannerModel(
        id: 'default-2',
        title: 'Lapar Malam? Temukan Makanan Hangat & Buka 24 Jam',
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
        targetingType: 'global',
        priority: 2,
      ),
      BannerModel(
        id: 'default-3',
        title: 'Kurasi Kuliner Otomatis Berbasis Suasana Hatimu',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
        targetingType: 'global',
        priority: 3,
      ),
    ];
  }

  // --- Default Menus Cache ---

  static void cacheDefaultMenus(List<dynamic> rawMenus) {
    saveJson('default_menus', rawMenus);
  }

  static List<MenuModel> getCachedDefaultMenus() {
    final raw = loadJson('default_menus');
    if (raw is List && raw.isNotEmpty) {
      try {
        return raw.map((item) => MenuModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      } catch (e) {
        debugPrint('Error parsing cached menus: $e');
      }
    }
    return _defaultMenus();
  }

  static List<MenuModel> _defaultMenus() {
    return [
      MenuModel(
        id: 'def-1',
        foodName: 'Soto Kudus Daging Sapi',
        category: 'Kuah Hangat',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        priceEst: 'Rp 25.000',
        description: 'Kuah bening rempah gurih dengan suwiran daging sapi empuk dan taburan bawang goreng',
        displayOrder: 1,
      ),
      MenuModel(
        id: 'def-2',
        foodName: 'Nasi Gila Menteng Spesial',
        category: 'Pedas Gurih',
        imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
        priceEst: 'Rp 28.000',
        description: 'Nasi dengan tumisan sosis, bakso, telur, dan bumbu gurih pedas manis khas Menteng',
        displayOrder: 2,
      ),
      MenuModel(
        id: 'def-3',
        foodName: 'Bakso Urat Malang Komplit',
        category: 'Kuah Gurih',
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
        priceEst: 'Rp 24.000',
        description: 'Bakso urat sapi asli, tahu bakso, siomay kukus, dan pangsit goreng renyah',
        displayOrder: 3,
      ),
      MenuModel(
        id: 'def-4',
        foodName: 'Ayam Geprek Sambal Bawang',
        category: 'Pedas Nampol',
        imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400',
        priceEst: 'Rp 22.000',
        description: 'Ayam krispi renyah digeprek dengan sambal cabai rawit pedas melek',
        displayOrder: 4,
      ),
      MenuModel(
        id: 'def-5',
        foodName: 'Dimsum Mentai & Es Teh Jumbo',
        category: 'Manis Segar',
        imageUrl: 'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400',
        priceEst: 'Rp 20.000',
        description: 'Dimsum lembut saus mentai gurih lezat ditemani es teh manis segar',
        displayOrder: 5,
      ),
    ];
  }

  // --- Roulette Items Cache ---

  static void cacheRouletteItems(List<dynamic> rawItems) {
    saveJson('roulette_items', rawItems);
  }

  static List<RouletteItemModel> getCachedRouletteItems() {
    final raw = loadJson('roulette_items');
    if (raw is List && raw.isNotEmpty) {
      try {
        return raw.map((item) => RouletteItemModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      } catch (e) {
        debugPrint('Error parsing cached roulette: $e');
      }
    }
    return _defaultRouletteItems();
  }

  static List<RouletteItemModel> _defaultRouletteItems() {
    return [
      RouletteItem(
        id: 'roulette-1',
        label: 'Nasi Padang Rendang',
        labelEn: 'Padang Rice with Rendang',
        emoji: '🍛',
        moodBenefit: 'Kaya rempah dan mengenyangkan jiwa saat lelah.',
        moodBenefitEn: 'Rich spices and soul-satisfying nourishment.',
        colorHex: '#EF4444',
        searchKeyword: 'Nasi Padang Rendang',
      ),
      RouletteItem(
        id: 'roulette-2',
        label: 'Mie Ayam Bakso',
        labelEn: 'Chicken Noodles & Meatballs',
        emoji: '🍜',
        moodBenefit: 'Hangat, gurih, dan mengembalikan energi positif.',
        moodBenefitEn: 'Warm, savory comfort bringing instant energy.',
        colorHex: '#F59E0B',
        searchKeyword: 'Mie Ayam Bakso',
      ),
      RouletteItem(
        id: 'roulette-3',
        label: 'Soto Kudus Daging',
        labelEn: 'Kudus Beef Soup',
        emoji: '🍲',
        moodBenefit: 'Kuah bening gurih menenangkan pikiran dan raga.',
        moodBenefitEn: 'Light herbal broth calming body and mind.',
        colorHex: '#10B981',
        searchKeyword: 'Soto Kudus',
      ),
      RouletteItem(
        id: 'roulette-4',
        label: 'Ayam Geprek Sambal',
        labelEn: 'Crispy Smashed Spicy Chicken',
        emoji: '🍗',
        moodBenefit: 'Pedas nampol yang melepaskan penat dan stres.',
        moodBenefitEn: 'Fiery spice blasting away daily stress.',
        colorHex: '#DC2626',
        searchKeyword: 'Ayam Geprek',
      ),
      RouletteItem(
        id: 'roulette-5',
        label: 'Sate Ayam Madura',
        labelEn: 'Madura Chicken Satay',
        emoji: '🍢',
        moodBenefit: 'Bumbu kacang legit manis gurih bikin mood bahagia.',
        moodBenefitEn: 'Sweet savory peanut sauce elevating mood.',
        colorHex: '#8B5CF6',
        searchKeyword: 'Sate Ayam',
      ),
      RouletteItem(
        id: 'roulette-6',
        label: 'Martabak Manis Cokelat Keju',
        labelEn: 'Sweet Chocolate Cheese Pancake',
        emoji: '🥞',
        moodBenefit: 'Manis legit memicu hormon kebahagiaan seketika.',
        moodBenefitEn: 'Sweet and decadent triggering instant joy.',
        colorHex: '#EC4899',
        searchKeyword: 'Martabak Manis',
      ),
    ];
  }

  // --- History Sessions Cache ---

  static void cacheHistory(String? userId, dynamic rawData) {
    final key = 'history_${userId ?? "guest"}';
    saveJson(key, rawData);
  }

  static HistoryFetchResult getCachedHistory(String? userId) {
    final key = 'history_${userId ?? "guest"}';
    final raw = loadJson(key);
    if (raw is Map<String, dynamic>) {
      final list = raw['history'] as List<dynamic>? ?? [];
      final items = list
          .map((item) => HistorySessionModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      final total = raw['total'] as int? ?? items.length;
      final hasMore = raw['has_more'] as bool? ?? false;
      return HistoryFetchResult(items: items, total: total, hasMore: hasMore);
    }
    return HistoryFetchResult(items: [], total: 0, hasMore: false);
  }

  // --- User Vouchers Cache ---

  static void cacheMyVouchers(String userId, List<dynamic> rawVouchers) {
    saveJson('vouchers_$userId', rawVouchers);
  }

  static List<Map<String, dynamic>> getCachedMyVouchers(String userId) {
    final raw = loadJson('vouchers_$userId');
    if (raw is List) {
      try {
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        debugPrint('Error parsing cached vouchers: $e');
      }
    }
    return [];
  }

  // --- Recommendation Cache (Offline fallback) ---

  static void cacheRecommendation(String prompt, Map<String, dynamic> rawResponse) {
    final normKey = _normalizePrompt(prompt);
    saveJson('rec_$normKey', rawResponse);
    saveJson('rec_latest', rawResponse);
  }

  static RecommendationResponse? getCachedRecommendation(String prompt) {
    final normKey = _normalizePrompt(prompt);
    var raw = loadJson('rec_$normKey');
    raw ??= loadJson('rec_latest');

    if (raw is Map<String, dynamic>) {
      try {
        final Map<String, dynamic> dataMap;
        if (raw['data'] is Map<String, dynamic>) {
          dataMap = raw['data'] as Map<String, dynamic>;
        } else {
          dataMap = raw;
        }
        return RecommendationResponse(
          status: 'success_cached',
          sessionId: raw['session_id']?.toString() ?? 'cached-session',
          data: RecommendationData.fromJson(dataMap),
        );
      } catch (e) {
        debugPrint('Error parsing cached recommendation: $e');
      }
    }
    return _generateOfflineFallbackRecommendation(prompt);
  }

  static RecommendationResponse _generateOfflineFallbackRecommendation(String prompt) {
    final defaultMenus = getCachedDefaultMenus();
    final places = defaultMenus.map((m) {
      return PlaceModel(
        id: 'offline-${m.id}',
        name: '${m.foodName} (Rekomendasi Tersimpan)',
        category: m.category,
        address: 'Tersedia di restoran terdekat sekitar Anda',
        distanceKm: 1.5,
        rating: 4.8,
        photoUrl: m.imageUrl,
        moodBadge: m.category,
        priceRange: m.priceEst ?? 'Rp 25.000',
        isSponsored: false,
        isOpen: true,
        openingHours: 'Buka Sekarang • Mode Offline',
        voucher: VoucherModel(hasVoucher: false),
        actionLinks: ActionLinksModel(
          googleMaps: 'https://maps.google.com/?q=${Uri.encodeComponent(m.foodName)}',
          deliveryApp: 'https://gofood.co.id/jakarta/search?q=${Uri.encodeComponent(m.foodName)}',
        ),
      );
    }).toList();

    return RecommendationResponse(
      status: 'offline_mode',
      sessionId: 'offline-local-session',
      data: RecommendationData(
        isRelevant: true,
        detectedMood: 'Mode Offline Cerdas',
        rationale: 'Koneksi ke server sedang terputus, namun MoodEats tetap menampilkan kurasi kuliner favorit yang tersimpan di perangkatmu.',
        places: places,
        homeRecipes: [
          'Mie instan kuah telur dengan cabai rawit & sayur sawi',
          'Nasi goreng spesial bumbu bawang telur orak-arik',
        ],
      ),
    );
  }

  static String _normalizePrompt(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_').substring(
      0,
      text.length > 30 ? 30 : text.length,
    );
  }
}
