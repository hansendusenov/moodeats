class DefaultMenu {
  final String id;
  final String foodName;
  final String category;
  final String imageUrl;
  final String? priceEst;
  final String? description;
  final int displayOrder;

  DefaultMenu({
    required this.id,
    required this.foodName,
    required this.category,
    required this.imageUrl,
    this.priceEst,
    this.description,
    this.displayOrder = 0,
  });

  factory DefaultMenu.fromJson(Map<String, dynamic> json) {
    return DefaultMenu(
      id: json['id'] ?? '',
      foodName: json['food_name'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      priceEst: json['price_est'] ?? 'Rp 25.000',
      description: json['description'] ?? '',
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

typedef MenuModel = DefaultMenu;
