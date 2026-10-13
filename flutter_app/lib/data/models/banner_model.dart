class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? targetUrl;
  final String targetingType;
  final String? targetCity;
  final double radiusKm;
  final int priority;

  BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.targetUrl,
    required this.targetingType,
    this.targetCity,
    this.radiusKm = 5.0,
    this.priority = 1,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      targetUrl: json['target_url'],
      targetingType: json['targeting_type'] ?? 'global',
      targetCity: json['target_city'],
      radiusKm: (json['radius_km'] is num) ? (json['radius_km'] as num).toDouble() : 5.0,
      priority: json['priority'] ?? 1,
    );
  }
}

typedef BannerModel = BannerItem;
