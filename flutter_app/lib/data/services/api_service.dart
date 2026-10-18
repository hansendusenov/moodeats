import 'dart:convert';
import 'dart:math' as math;
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
  static const String defaultBackendUrl =
      'https://moodeats-proxy-r53v6ivp3a-et.a.run.app';

  late final String baseUrl;

  ApiService() {
    final envUrl = dotenv.env['ADK_AGENT_BASE_URL'] ?? dotenv.env['AGENT_API_URL'];
    String configuredUrl = (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : defaultBackendUrl;

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
          .timeout(const Duration(minutes: 5));

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
        .timeout(const Duration(seconds: 60));

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
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

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
      final response = await http.get(url).timeout(const Duration(seconds: 60));

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
      final response = await http.get(url).timeout(const Duration(seconds: 60));

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
        .timeout(const Duration(minutes: 5));

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
      final response = await http.delete(url).timeout(const Duration(seconds: 60));
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
    ).timeout(const Duration(seconds: 60));

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
    ).timeout(const Duration(seconds: 60));

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
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (userId != null && userId.isNotEmpty) {
        headers['X-User-Id'] = userId;
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['sessions'] as List<dynamic>?) ??
            (data['history'] as List<dynamic>?) ??
            [];
        final items = list.map((item) => HistorySessionModel.fromJson(item as Map<String, dynamic>)).toList();
        final total = (data['total_count'] as int?) ??
            (data['total'] as int?) ??
            items.length;
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
      ).timeout(const Duration(seconds: 60));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error ApiService.syncUserProfile: $e');
      return false;
    }
  }

  /// GET /api/v1/users/profile
  Future<Map<String, dynamic>?> getUserProfile({String? email, String? userId}) async {
    try {
      final queryParams = <String, String>{};
      if (email != null && email.isNotEmpty) queryParams['email'] = email.trim();
      if (userId != null && userId.isNotEmpty) queryParams['user_id'] = userId.trim();
      if (queryParams.isEmpty) return null;

      final uri = Uri.parse('$baseUrl/api/v1/users/profile').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['profile'] != null) {
          return Map<String, dynamic>.from(data['profile']);
        }
      }
    } catch (e) {
      debugPrint('Error ApiService.getUserProfile: $e');
    }
    return null;
  }

  /// GET /api/v1/vouchers/my
  Future<List<Map<String, dynamic>>> getMyVouchers(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/vouchers/my?user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 60));
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

  /// Fetches ~10 curated comfort food restaurants based on nearest user location
  Future<List<PlaceModel>> getNearbyComfortRestaurants({
    double? lat,
    double? lng,
    String? city,
  }) async {
    final double userLat = lat ?? -6.2297;
    final double userLng = lng ?? 106.8295;
    final String userCity = (city != null && city.isNotEmpty) ? city : 'Jakarta Selatan';

    // 1. Primary: Google Places API (New v1) searchText for 10 real nearby restaurants
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? 'AIzaSyBMZGVGlEtKO8NyV9lO1gSPWHDw2Iby66o';
      if (apiKey.isNotEmpty) {
        final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
        final body = jsonEncode({
          'textQuery': 'comfort food restoran di $userCity',
          'locationBias': {
            'circle': {
              'center': {'latitude': userLat, 'longitude': userLng},
              'radius': 7000.0,
            }
          },
          'maxResultCount': 10,
        });

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.photos,places.currentOpeningHours,places.priceLevel,places.primaryTypeDisplayName',
          },
          body: body,
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final rawPlaces = data['places'] as List<dynamic>? ?? [];
          if (rawPlaces.isNotEmpty) {
            final List<PlaceModel> results = [];
            final fallbackPhotos = [
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500',
              'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500',
              'https://images.unsplash.com/photo-1552611052-33e04de081de?w=500',
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500',
              'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500',
              'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500',
              'https://images.unsplash.com/photo-1525755662778-989d0524087e?w=500',
            ];

            for (int i = 0; i < rawPlaces.length; i++) {
              final p = rawPlaces[i] as Map<String, dynamic>;
              final name = (p['displayName']?['text'] ?? '').toString();
              if (name.isEmpty) continue;

              final addr = (p['formattedAddress'] ?? '').toString();
              final pLoc = p['location'] as Map<String, dynamic>?;
              double dist = 1.0;
              if (pLoc != null && pLoc['latitude'] is num && pLoc['longitude'] is num) {
                dist = _haversineDistanceKm(
                  userLat,
                  userLng,
                  (pLoc['latitude'] as num).toDouble(),
                  (pLoc['longitude'] as num).toDouble(),
                );
              }

              final rating = (p['rating'] is num) ? (p['rating'] as num).toDouble() : 4.6;
              final isOpen = p['currentOpeningHours']?['openNow'] == true;
              final photoList = p['photos'] as List<dynamic>?;
              String photoUrl = fallbackPhotos[i % fallbackPhotos.length];
              if (photoList != null && photoList.isNotEmpty) {
                final photoRef = photoList.first['name'];
                if (photoRef != null) {
                  photoUrl = 'https://places.googleapis.com/v1/$photoRef/media?maxHeightPx=400&maxWidthPx=400&key=$apiKey';
                }
              }

              final encodedName = Uri.encodeComponent(name);
              final encodedAddr = Uri.encodeComponent(addr);

              results.add(PlaceModel(
                id: p['id']?.toString() ?? 'place_$i',
                name: name,
                category: p['primaryTypeDisplayName']?['text']?.toString() ?? 'Comfort Food',
                address: addr,
                distanceKm: dist,
                rating: rating,
                photoUrl: photoUrl,
                moodBadge: 'Comfort Food Terdekat',
                priceRange: 'Rp 25.000 - Rp 50.000',
                isSponsored: false,
                isOpen: isOpen,
                openingHours: isOpen ? 'Buka Sekarang' : 'Tutup Sementara',
                voucher: VoucherModel(hasVoucher: false),
                actionLinks: ActionLinksModel(
                  googleMaps: 'https://maps.google.com/?q=$encodedName%20$encodedAddr',
                  deliveryApp: 'https://gofood.co.id/jakarta/search?q=$encodedName',
                ),
              ));
            }

            if (results.isNotEmpty) {
              results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
              return results.take(10).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Google Places API comfort food error: $e');
    }

    // 2. Secondary Fallback: Supabase Cached Places
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://tpkchcrwqjrfprdibawz.supabase.co';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_NnxB2xMykdtqEgHxzNhc2w_grwjwubb';
      if (supabaseUrl.isNotEmpty && anonKey.isNotEmpty) {
        final uri = Uri.parse('$supabaseUrl/rest/v1/places_cache?select=places_payload&limit=8');
        final res = await http.get(
          uri,
          headers: {'apikey': anonKey, 'Authorization': 'Bearer $anonKey'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>?;
          if (list != null && list.isNotEmpty) {
            final List<PlaceModel> cachedPlaces = [];
            final seenNames = <String>{};
            for (final row in list) {
              final payload = row['places_payload'];
              final placesList = payload is List ? payload : (payload is String ? jsonDecode(payload) : []);
              if (placesList is List) {
                for (final item in placesList) {
                  if (item is Map<String, dynamic>) {
                    final p = PlaceModel.fromJson(item);
                    if (seenNames.add(p.name)) {
                      cachedPlaces.add(p);
                    }
                  }
                }
              }
            }
            if (cachedPlaces.isNotEmpty) {
              cachedPlaces.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
              return cachedPlaces.take(10).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase places cache fallback error: $e');
    }

    // 3. Guaranteed Local Curated Fallback: Top 10 Comfort Food Spots in Jakarta
    return _getCuratedFallbackRestaurants(userLat, userLng);
  }

  double _haversineDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    const double r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return double.parse((r * c).toStringAsFixed(1));
  }

  List<PlaceModel> _getCuratedFallbackRestaurants(double userLat, double userLng) {
    final rawSpots = [
      {'name': 'Wajan Noni', 'cat': 'Indonesian Comfort Food', 'addr': 'Jl. H. R. Rasuna Said No.15, Setiabudi, Jakarta Selatan', 'rating': 4.8, 'lat': -6.222, 'lng': 106.831, 'img': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'},
      {'name': 'Hang Tuah - Kuningan City', 'cat': 'Kopitiam & Comfort Food', 'addr': 'Kuningan City Mall LG Floor, Jl. Prof. DR. Satrio, Jakarta Selatan', 'rating': 4.8, 'lat': -6.224, 'lng': 106.830, 'img': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500'},
      {'name': 'Soto Kudus Menara Senayan', 'cat': 'Soto & Kuah Hangat', 'addr': 'Jl. Tentara Pelajar No.1, Kebayoran Lama, Jakarta Selatan', 'rating': 4.7, 'lat': -6.221, 'lng': 106.795, 'img': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500'},
      {'name': 'Sop Buntut Cut Meutia Menteng', 'cat': 'Sup Tradisional Hangat', 'addr': 'Jl. Cut Meutia No. 9, Menteng, Jakarta Pusat', 'rating': 4.9, 'lat': -6.187, 'lng': 106.834, 'img': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'},
      {'name': 'Bakso Jeki 2 Kemayoran', 'cat': 'Bakso Daging Kuah Gurih', 'addr': 'Jl. Serdang Baru No.10, Kemayoran, Jakarta Pusat', 'rating': 4.7, 'lat': -6.160, 'lng': 106.858, 'img': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500'},
      {'name': 'Kopi Tuku & Roti Sabang', 'cat': 'Kopi & Camilan Penenang', 'addr': 'Jl. H. Agus Salim No. 60, Menteng, Jakarta Pusat', 'rating': 4.8, 'lat': -6.182, 'lng': 106.824, 'img': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=500'},
      {'name': 'Nasi Goreng Kambing Kebon Sirih', 'cat': 'Nasi Goreng Rempah', 'addr': 'Jl. Kebon Sirih Barat Dalam, Gambir, Jakarta Pusat', 'rating': 4.6, 'lat': -6.184, 'lng': 106.829, 'img': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500'},
      {'name': 'Bakso Kampungqu Sunter', 'cat': 'Bakso Urat & Kuah Segar', 'addr': 'Jl. Sunter Jaya V No.69, Tanjung Priok, Jakarta Utara', 'rating': 4.9, 'lat': -6.145, 'lng': 106.870, 'img': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500'},
      {'name': 'Soto Betawi Bang Madun', 'cat': 'Soto Santan Gurih', 'addr': 'Jl. Tebet Barat Dalam Raya No. 45, Jakarta Selatan', 'rating': 4.7, 'lat': -6.235, 'lng': 106.850, 'img': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'},
      {'name': 'Wedang Ronde Udo Sunter', 'cat': 'Dessert Tradisional Hangat', 'addr': 'Ruko Taman Sunter Indah HJ2, Jakarta Utara', 'rating': 4.8, 'lat': -6.140, 'lng': 106.865, 'img': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500'},
    ];

    return rawSpots.map((s) {
      final name = s['name'] as String;
      final addr = s['addr'] as String;
      final sLat = s['lat'] as double;
      final sLng = s['lng'] as double;
      final dist = _haversineDistanceKm(userLat, userLng, sLat, sLng);
      return PlaceModel(
        id: 'curated_${name.toLowerCase().replaceAll(' ', '_')}',
        name: name,
        category: s['cat'] as String,
        address: addr,
        distanceKm: dist,
        rating: s['rating'] as double,
        photoUrl: s['img'] as String,
        moodBadge: 'Comfort Food Pilihan',
        priceRange: 'Rp 20.000 - Rp 45.000',
        isSponsored: false,
        isOpen: true,
        openingHours: 'Buka Sekarang',
        voucher: VoucherModel(hasVoucher: false),
        actionLinks: ActionLinksModel(
          googleMaps: 'https://maps.google.com/?q=${Uri.encodeComponent('$name $addr')}',
          deliveryApp: 'https://gofood.co.id/jakarta/search?q=${Uri.encodeComponent(name)}',
        ),
      );
    }).toList();
  }
}

