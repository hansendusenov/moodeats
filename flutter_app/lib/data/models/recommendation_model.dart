class RecommendationResponse {
  final String status;
  final String sessionId;
  final RecommendationData data;

  RecommendationResponse({
    required this.status,
    required this.sessionId,
    required this.data,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    // Determine data map: check 'data' key or fallback to top-level json map
    final Map<String, dynamic> dataMap = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json);

    return RecommendationResponse(
      status: json['status']?.toString() ?? 'success',
      sessionId: json['session_id']?.toString() ?? dataMap['session_id']?.toString() ?? '',
      data: RecommendationData.fromJson(dataMap),
    );
  }
}

class RecommendationData {
  final bool isRelevant;
  final String detectedMood;
  final String rationale;
  final List<PlaceModel> places;
  final List<String> homeRecipes;

  RecommendationData({
    required this.isRelevant,
    required this.detectedMood,
    required this.rationale,
    required this.places,
    required this.homeRecipes,
  });

  factory RecommendationData.fromJson(Map<String, dynamic> json) {
    String detectedMood = (json['detected_mood'] ?? '').toString();
    String rationale = (json['rationale'] ?? '').toString();

    // Check nested sentiment block if top-level fields are empty
    if (json['sentiment'] is Map) {
      final s = json['sentiment'] as Map;
      if (detectedMood.isEmpty) {
        detectedMood = s['detected_mood']?.toString() ?? '';
      }
      if (rationale.isEmpty) {
        rationale = s['mood_rationale']?.toString() ??
            s['rationale']?.toString() ??
            '';
      }
    }

    if (detectedMood.isEmpty) detectedMood = 'Comfort Seeking';
    if (rationale.isEmpty) {
      rationale = 'Pilihan hidangan terbaik yang cocok untuk menemani dan memulihkan suasana hatimu saat ini.';
    }

    final rawPlaces = json['places'] as List<dynamic>? ?? [];
    final List<PlaceModel> places = [];
    for (final item in rawPlaces) {
      if (item is Map<String, dynamic>) {
        places.add(PlaceModel.fromJson(item));
      } else if (item is Map) {
        places.add(PlaceModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final rawRecipes = json['home_recipes'] as List<dynamic>? ?? [];
    final List<String> homeRecipes = rawRecipes.map((e) => e.toString()).toList();

    return RecommendationData(
      isRelevant: json['is_relevant'] is bool ? json['is_relevant'] as bool : true,
      detectedMood: detectedMood,
      rationale: rationale,
      places: places,
      homeRecipes: homeRecipes,
    );
  }
}

class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final double distanceKm;
  final double rating;
  final String photoUrl;
  final String moodBadge;
  final String priceRange;
  final bool isSponsored;
  final bool isOpen;
  final String? openingHours;
  final VoucherModel voucher;
  final ActionLinksModel actionLinks;

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.photoUrl,
    required this.moodBadge,
    required this.priceRange,
    required this.isSponsored,
    this.isOpen = true,
    this.openingHours,
    required this.voucher,
    required this.actionLinks,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    double parsedDistance = 1.0;
    if (json['distance_km'] is num) {
      parsedDistance = (json['distance_km'] as num).toDouble();
    } else if (json['distance_km'] is String) {
      parsedDistance = double.tryParse(json['distance_km']) ?? 1.0;
    }

    double parsedRating = 4.5;
    if (json['rating'] is num) {
      parsedRating = (json['rating'] as num).toDouble();
    } else if (json['rating'] is String) {
      parsedRating = double.tryParse(json['rating']) ?? 4.5;
    }

    final voucherMap = json['voucher'] is Map
        ? Map<String, dynamic>.from(json['voucher'] as Map)
        : <String, dynamic>{};

    final actionLinksMap = json['action_links'] is Map
        ? Map<String, dynamic>.from(json['action_links'] as Map)
        : <String, dynamic>{};

    final name = json['name']?.toString() ?? 'Tempat Makan';
    final category = json['category']?.toString() ?? 'Kuliner';
    final photoUrl = resolvePhotoUrl(json['photo_url']?.toString(), name, category);

    return PlaceModel(
      id: json['id']?.toString() ?? '',
      name: name,
      category: category,
      address: json['address']?.toString() ?? '',
      distanceKm: parsedDistance,
      rating: parsedRating,
      photoUrl: photoUrl,
      moodBadge: json['mood_badge']?.toString() ?? 'Rekomendasi',
      priceRange: json['price_range']?.toString() ?? 'Rp 20.000 - Rp 45.000',
      isSponsored: json['is_sponsored'] == true || json['is_sponsored'] == 1,
      isOpen: json['is_open'] == null ? true : (json['is_open'] == true || json['is_open'] == 1),
      openingHours: json['opening_hours']?.toString(),
      voucher: VoucherModel.fromJson(voucherMap),
      actionLinks: ActionLinksModel.fromJson(actionLinksMap),
    );
  }

  static String resolvePhotoUrl(String? rawUrl, String name, String category) {
    if (rawUrl != null &&
        rawUrl.isNotEmpty &&
        !rawUrl.contains('photo-1546069901-ba9599a7e63c') &&
        !rawUrl.contains('photo-1555396273-367ea4eb4db5')) {
      return rawUrl;
    }
    final lower = '$name $category'.toLowerCase();
    if (lower.contains('bakso') || lower.contains('meatball')) {
      return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600';
    }
    if (lower.contains('soto') || lower.contains('soup') || lower.contains('kuah') || lower.contains('sop')) {
      return 'https://images.unsplash.com/photo-1547592180-85f173990554?w=600';
    }
    if (lower.contains('sate') || lower.contains('satay') || lower.contains('panggang') || lower.contains('bakar')) {
      return 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600';
    }
    if (lower.contains('kopi') || lower.contains('coffee') || lower.contains('cafe') || lower.contains('kafe') || lower.contains('kopitiam')) {
      return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600';
    }
    if (lower.contains('ayam') || lower.contains('chicken') || lower.contains('geprek') || lower.contains('bebek')) {
      return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600';
    }
    if (lower.contains('nasi') || lower.contains('rice') || lower.contains('padang') || lower.contains('warteg')) {
      return 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600';
    }
    if (lower.contains('burger') || lower.contains('western') || lower.contains('pizza') || lower.contains('pasta')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600';
    }
    if (lower.contains('mie') || lower.contains('noodle') || lower.contains('ramen') || lower.contains('kwetiau')) {
      return 'https://images.unsplash.com/photo-1552611052-33e04de081de?w=600';
    }
    if (lower.contains('manis') || lower.contains('dessert') || lower.contains('cake') || lower.contains('boba') || lower.contains('es ')) {
      return 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600';
    }
    if (lower.contains('seafood') || lower.contains('ikan') || lower.contains('udang')) {
      return 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=600';
    }
    return rawUrl?.isNotEmpty == true
        ? rawUrl!
        : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600';
  }
}

class VoucherModel {
  final bool hasVoucher;
  final String? merchantId;
  final String? voucherCode;
  final String? type;
  final String? discountText;
  final int durationMinutes;

  VoucherModel({
    required this.hasVoucher,
    this.merchantId,
    this.voucherCode,
    this.type,
    this.discountText,
    this.durationMinutes = 15,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    int parsedDuration = 15;
    if (json['duration_minutes'] is num) {
      parsedDuration = (json['duration_minutes'] as num).toInt();
    } else if (json['duration_minutes'] is String) {
      parsedDuration = int.tryParse(json['duration_minutes']) ?? 15;
    }

    return VoucherModel(
      hasVoucher: json['has_voucher'] == true || json['has_voucher'] == 1,
      merchantId: json['merchant_id']?.toString(),
      voucherCode: json['voucher_code']?.toString(),
      type: json['type']?.toString() ?? 'timer',
      discountText: json['discount_text']?.toString(),
      durationMinutes: parsedDuration,
    );
  }
}

class ActionLinksModel {
  final String? googleMaps;
  final String? deliveryApp;
  final String? whatsappBooking;

  ActionLinksModel({
    this.googleMaps,
    this.deliveryApp,
    this.whatsappBooking,
  });

  factory ActionLinksModel.fromJson(Map<String, dynamic> json) {
    return ActionLinksModel(
      googleMaps: json['google_maps']?.toString(),
      deliveryApp: json['delivery_app']?.toString(),
      whatsappBooking: json['whatsapp_booking']?.toString(),
    );
  }
}
