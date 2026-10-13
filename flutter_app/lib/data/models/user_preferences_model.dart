import 'package:moodeats_app/core/localization/app_strings.dart';

class UserPreferencesModel {
  final bool isHalalOnly;
  final String dietaryType;
  final List<String> allergies;
  final bool isOpenNowOnly;

  const UserPreferencesModel({
    this.isHalalOnly = false,
    this.dietaryType = 'none',
    this.allergies = const [],
    this.isOpenNowOnly = false,
  });

  UserPreferencesModel copyWith({
    bool? isHalalOnly,
    String? dietaryType,
    List<String>? allergies,
    bool? isOpenNowOnly,
  }) {
    return UserPreferencesModel(
      isHalalOnly: isHalalOnly ?? this.isHalalOnly,
      dietaryType: dietaryType ?? this.dietaryType,
      allergies: allergies ?? this.allergies,
      isOpenNowOnly: isOpenNowOnly ?? this.isOpenNowOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_halal_only': isHalalOnly,
        'dietary_type': dietaryType,
        'allergies': allergies,
        'is_open_now_only': isOpenNowOnly,
      };

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      isHalalOnly: json['is_halal_only'] as bool? ?? false,
      dietaryType: json['dietary_type'] as String? ?? 'none',
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isOpenNowOnly: json['is_open_now_only'] as bool? ?? false,
    );
  }

  String getDietaryLabel(AppLanguage lang) {
    final isId = lang == AppLanguage.id;
    switch (dietaryType) {
      case 'vegetarian':
        return isId ? 'Vegetarian 🥗' : 'Vegetarian 🥗';
      case 'vegan':
        return isId ? 'Vegan 🌱' : 'Vegan 🌱';
      case 'low_calorie':
        return isId ? 'Rendah Kalori 🥑' : 'Low Calorie 🥑';
      case 'low_carb':
        return isId ? 'Keto / Rendah Karbo 🥩' : 'Keto / Low Carb 🥩';
      case 'pescatarian':
        return isId ? 'Pescatarian 🐟' : 'Pescatarian 🐟';
      default:
        return isId ? 'Bebas / Semua Makanan' : 'All / Unrestricted';
    }
  }

  static String getAllergyLabel(String key, AppLanguage lang) {
    final isId = lang == AppLanguage.id;
    switch (key) {
      case 'gluten_free':
        return isId ? 'Bebas Gluten 🌾' : 'Gluten-Free 🌾';
      case 'nut_free':
        return isId ? 'Bebas Kacang 🥜' : 'Nut-Free 🥜';
      case 'seafood_free':
        return isId ? 'Bebas Seafood 🦐' : 'Seafood-Free 🦐';
      case 'dairy_free':
        return isId ? 'Bebas Susu / Laktosa 🥛' : 'Dairy-Free 🥛';
      default:
        return key;
    }
  }

  String getSummaryText(AppLanguage lang) {
    final isId = lang == AppLanguage.id;
    final parts = <String>[];
    if (isHalalOnly) {
      parts.add(isId ? 'Wajib Halal 🟢' : 'Halal Only 🟢');
    }
    if (isOpenNowOnly) {
      parts.add(isId ? 'Buka Sekarang 🕒' : 'Open Now 🕒');
    }
    if (dietaryType != 'none') {
      parts.add(getDietaryLabel(lang));
    }
    if (allergies.isNotEmpty) {
      parts.add(isId ? '${allergies.length} Pantangan' : '${allergies.length} Restrictions');
    }
    if (parts.isEmpty) {
      return isId ? 'Bebas / Semua Makanan (Belum diatur)' : 'All Foods (Default)';
    }
    return parts.join(' • ');
  }
}
