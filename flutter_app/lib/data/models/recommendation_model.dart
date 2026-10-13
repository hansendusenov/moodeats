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
    return RecommendationResponse(
      status: json['status'] ?? 'success',
      sessionId: json['session_id'] ?? '',
      data: RecommendationData.fromJson(json['data'] ?? {}),
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
    return RecommendationData(
      isRelevant: json['is_relevant'] ?? true,
      detectedMood: json['detected_mood'] ?? 'Comfort',
      rationale: json['rationale'] ?? '',
      places: (json['places'] as List<dynamic>? ?? [])
          .map((item) => PlaceModel.fromJson(item))
          .toList(),
      homeRecipes: (json['home_recipes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
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
    return PlaceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Tempat Makan',
      category: json['category'] ?? 'Kuliner',
      address: json['address'] ?? '',
      distanceKm: (json['distance_km'] is num) ? (json['distance_km'] as num).toDouble() : 1.0,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.5,
      photoUrl: json['photo_url'] ?? '',
      moodBadge: json['mood_badge'] ?? 'Rekomendasi',
      priceRange: json['price_range'] ?? 'Rp 20.000 - Rp 40.000',
      isSponsored: json['is_sponsored'] ?? false,
      isOpen: json['is_open'] as bool? ?? true,
      openingHours: json['opening_hours'] as String?,
      voucher: VoucherModel.fromJson(json['voucher'] ?? {}),
      actionLinks: ActionLinksModel.fromJson(json['action_links'] ?? {}),
    );
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
    return VoucherModel(
      hasVoucher: json['has_voucher'] ?? false,
      merchantId: json['merchant_id'],
      voucherCode: json['voucher_code'],
      type: json['type'] ?? 'timer',
      discountText: json['discount_text'],
      durationMinutes: json['duration_minutes'] ?? 15,
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
      googleMaps: json['google_maps'],
      deliveryApp: json['delivery_app'],
      whatsappBooking: json['whatsapp_booking'],
    );
  }
}
