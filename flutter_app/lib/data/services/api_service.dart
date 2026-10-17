import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recommendation_model.dart';
import '../models/banner_model.dart';
import '../models/menu_model.dart';
import '../models/roulette_model.dart';
import '../models/history_session_model.dart';
import 'app_cache_service.dart';

class ApiService {
  late final String baseUrl;

  ApiService() {
    final envUrl = dotenv.env['ADK_AGENT_BASE_URL'] ?? dotenv.env['AGENT_API_URL'];
    String configuredUrl = (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');

    baseUrl = configuredUrl.endsWith('/')
        ? configuredUrl.substring(0, configuredUrl.length - 1)
        : configuredUrl;
  }

  /// POST /api/v1/agent/recommend
  Future<RecommendationResponse> getRecommendation({
    required String prompt,
    String? sessionId,
    double? lat,
    double? lng,
    String? city = 'Jakarta Selatan',
    String? userId,
    bool isHalalOnly = false,
    String? dietaryType,
    List<String>? allergies,
    bool onlyOpenNow = false,
    String? deviceOs,
    String? appVersion,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/agent/recommend');
    final body = jsonEncode({
      'prompt': prompt,
      'session_id': sessionId,
      'lat': lat ?? -6.2297,
      'lng': lng ?? 106.8580,
      'city': city ?? 'Jakarta Selatan',
      'user_id': userId,
      'is_halal_only': isHalalOnly,
      'dietary_type': dietaryType,
      'allergies': allergies,
      'only_open_now': onlyOpenNow,
      'is_manual_location': false,
      'device_os': deviceOs,
      'app_version': appVersion,
    });

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppCacheService.cacheRecommendation(prompt, data);
        return RecommendationResponse.fromJson(data);
      } else {
        throw Exception(
            'Gagal memuat rekomendasi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error ApiService.getRecommendation: $e. Using offline cache.');
      final cached = AppCacheService.getCachedRecommendation(prompt);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// POST /api/v1/vouchers/claim
  Future<Map<String, dynamic>> claimVoucher({
    required String merchantId,
    String? userId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/vouchers/claim');
    final body = jsonEncode({
      'merchant_id': merchantId,
      'user_id': userId,
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Gagal mengklaim voucher');
    }
  }

  /// GET /api/v1/banners
  Future<List<BannerModel>> getBanners({String? city}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/banners').replace(
        queryParameters: city != null ? {'city': city} : null,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['banners'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          AppCacheService.cacheBanners(list);
          return list.map((item) => BannerModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error ApiService.getBanners: $e. Falling back to cache.');
    }
    return AppCacheService.getCachedBanners();
  }

  /// GET /api/v1/menus/default
  Future<List<MenuModel>> getDefaultMenus() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/menus/default');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['menus'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          AppCacheService.cacheDefaultMenus(list);
          return list.map((item) => MenuModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error ApiService.getDefaultMenus: $e. Falling back to cache.');
    }
    return AppCacheService.getCachedDefaultMenus();
  }

  /// GET /api/v1/roulette
  Future<List<RouletteItemModel>> getRouletteItems() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/roulette');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['items'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          AppCacheService.cacheRouletteItems(list);
          return list.map((item) => RouletteItemModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error ApiService.getRouletteItems: $e. Falling back to cache.');
    }
    return AppCacheService.getCachedRouletteItems();
  }

  /// POST /api/v1/agent/analyze-image
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String lang = 'id',
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/agent/analyze-image');
    final base64Image = base64Encode(imageBytes);
    final body = jsonEncode({
      'image_base64': base64Image,
      'mime_type': mimeType,
      'lang': lang,
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['detected_text'] ?? '';
    } else {
      throw Exception('Gagal menganalisis foto: ${response.statusCode}');
    }
  }

  /// DELETE /api/v1/sessions/history (Subject Rights: Unlink Sessions & Purge Local Cache)
  Future<bool> clearHistory(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/sessions/history?user_id=$userId');
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        AppCacheService.purgeHistory(userId);
        return true;
      }
    } catch (e) {
      debugPrint('Error ApiService.clearHistory: $e');
    }
    // Purge local cache regardless of offline status
    AppCacheService.purgeHistory(userId);
    return false;
  }

  /// POST /api/v1/users/delete-request (Subject Rights: Right to Erasure / 30-Day Grace Period)
  Future<Map<String, dynamic>> requestAccountDeletion(String userId) async {
    final url = Uri.parse('$baseUrl/api/v1/users/delete-request');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      AppCacheService.purgeAllCache();
      return data;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Gagal mengajukan penghapusan akun');
    }
  }

  /// POST /api/v1/users/cancel-delete (Subject Rights: Restore Account During Grace Period)
  Future<Map<String, dynamic>> cancelAccountDeletion(String userId) async {
    final url = Uri.parse('$baseUrl/api/v1/users/cancel-delete');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Gagal membatalkan penghapusan akun');
    }
  }

  /// GET /api/v1/sessions/history with date range and lazy pagination
  Future<HistoryFetchResult> getHistorySessionsPage({
    String? userId,
    String? startDate,
    String? endDate,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
      if (userId != null && userId.isNotEmpty) queryParams['user_id'] = userId;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/api/v1/sessions/history').replace(
        queryParameters: queryParams,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['history'] as List<dynamic>? ?? [];
        final items = list.map((item) => HistorySessionModel.fromJson(item)).toList();
        final total = data['total'] as int? ?? items.length;
        final hasMore = data['has_more'] as bool? ?? false;
        if (offset == 0 && items.isNotEmpty) {
          AppCacheService.cacheHistory(userId, data);
        }
        return HistoryFetchResult(items: items, total: total, hasMore: hasMore);
      }
    } catch (e) {
      debugPrint('Error ApiService.getHistorySessionsPage: $e. Falling back to cache.');
    }
    if (offset == 0) {
      return AppCacheService.getCachedHistory(userId);
    }
    return HistoryFetchResult(items: [], total: 0, hasMore: false);
  }

  Future<List<HistorySessionModel>> getHistorySessions({
    String? userId,
    String? startDate,
    String? endDate,
    int offset = 0,
    int limit = 10,
  }) async {
    final res = await getHistorySessionsPage(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      offset: offset,
      limit: limit,
    );
    return res.items;
  }

  /// POST /api/v1/users/sync
  Future<bool> syncUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? birthDate,
    String? gender,
    String? phone,
    String? deviceModel,
    String? deviceOs,
    String? appVersion,
    bool? isHalalOnly,
    String? dietaryType,
    List<String>? allergies,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/users/sync');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'email': email,
          'display_name': displayName,
          'birth_date': birthDate,
          'gender': gender,
          'phone': phone,
          'device_model': deviceModel,
          'device_os': deviceOs,
          'app_version': appVersion,
          'is_halal_only': isHalalOnly,
          'dietary_type': dietaryType,
          'allergies': allergies,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error ApiService.syncUserProfile: $e');
      return false;
    }
  }

  /// GET /api/v1/vouchers/my
  Future<List<Map<String, dynamic>>> getMyVouchers(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/vouchers/my?user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['vouchers'] as List<dynamic>? ?? [];
        final mapped = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mapped.isNotEmpty) {
          AppCacheService.cacheMyVouchers(userId, mapped);
        }
        return mapped;
      }
    } catch (e) {
      debugPrint('Error ApiService.getMyVouchers: $e. Falling back to cache.');
    }
    return AppCacheService.getCachedMyVouchers(userId);
  }
}

