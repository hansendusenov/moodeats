import 'recommendation_model.dart';

class HistorySessionModel {
  final String id;
  final String sessionId;
  final String title;
  final String detectedMood;
  final String restaurant;
  final List<String> foodCategories;
  final String? city;
  final bool hasVoucher;
  final DateTime? createdAt;
  final Map<String, dynamic>? cachedResponse;

  HistorySessionModel({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.detectedMood,
    required this.restaurant,
    this.foodCategories = const [],
    this.city,
    this.hasVoucher = false,
    this.createdAt,
    this.cachedResponse,
  });

  bool get hasCachedResponse =>
      cachedResponse != null && cachedResponse!.isNotEmpty;

  RecommendationResponse? toRecommendationResponse() {
    if (!hasCachedResponse) return null;
    final Map<String, dynamic> dataMap;
    if (cachedResponse!['data'] is Map<String, dynamic>) {
      dataMap = cachedResponse!['data'] as Map<String, dynamic>;
    } else {
      dataMap = cachedResponse!;
    }
    return RecommendationResponse(
      status: cachedResponse!['status']?.toString() ?? 'success',
      sessionId: sessionId,
      data: RecommendationData.fromJson(dataMap),
    );
  }

  factory HistorySessionModel.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString() ??
        json['prompt']?.toString() ??
        'Rekomendasi Kuliner';
    final restaurant = json['restaurant']?.toString() ??
        json['first_restaurant_name']?.toString() ??
        'Tempat Makan Terdekat';
    final mood = json['detected_mood']?.toString() ?? 'Mood Discovery';

    return HistorySessionModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      title: title.isNotEmpty ? title : 'Rekomendasi Kuliner',
      detectedMood: mood.isNotEmpty ? mood : 'Mood Discovery',
      restaurant: restaurant.isNotEmpty ? restaurant : 'Tempat Makan Terdekat',
      foodCategories: (json['food_categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      city: json['city']?.toString(),
      hasVoucher: json['has_voucher'] == true || json['has_voucher'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      cachedResponse: json['cached_response'] != null &&
              json['cached_response'] is Map<String, dynamic>
          ? json['cached_response'] as Map<String, dynamic>
          : null,
    );
  }
}

class HistoryFetchResult {
  final List<HistorySessionModel> items;
  final int total;
  final bool hasMore;

  HistoryFetchResult({
    required this.items,
    required this.total,
    required this.hasMore,
  });
}


