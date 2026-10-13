import 'package:flutter/material.dart';

class RouletteItem {
  final String id;
  final String label;
  final String labelEn;
  final String emoji;
  final String moodBenefit;
  final String moodBenefitEn;
  final String colorHex;
  final String searchKeyword;

  RouletteItem({
    required this.id,
    required this.label,
    this.labelEn = '',
    required this.emoji,
    required this.moodBenefit,
    this.moodBenefitEn = '',
    required this.colorHex,
    required this.searchKeyword,
  });

  String displayLabel(bool isId) {
    if (isId) return label;
    return labelEn.isNotEmpty ? labelEn : label;
  }

  String displayMoodBenefit(bool isId) {
    if (isId) return moodBenefit;
    return moodBenefitEn.isNotEmpty ? moodBenefitEn : moodBenefit;
  }

  Color get color {
    final hexCode = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  factory RouletteItem.fromJson(Map<String, dynamic> json) {
    return RouletteItem(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      labelEn: json['label_en'] ?? '',
      emoji: json['emoji'] ?? '🍽️',
      moodBenefit: json['mood_benefit'] ?? '',
      moodBenefitEn: json['mood_benefit_en'] ?? '',
      colorHex: json['color_hex'] ?? '#DC2626',
      searchKeyword: json['search_keyword'] ?? '',
    );
  }
}

typedef RouletteItemModel = RouletteItem;
