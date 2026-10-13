import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/user_preferences_model.dart';
import '../../data/services/preferences_service.dart';

class DietaryPreferencesModal extends ConsumerStatefulWidget {
  final AppLanguage lang;

  const DietaryPreferencesModal({
    super.key,
    required this.lang,
  });

  static Future<void> show(BuildContext context, AppLanguage lang) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DietaryPreferencesModal(lang: lang),
    );
  }

  @override
  ConsumerState<DietaryPreferencesModal> createState() =>
      _DietaryPreferencesModalState();
}

class _DietaryPreferencesModalState
    extends ConsumerState<DietaryPreferencesModal> {
  late bool _isHalalOnly;
  late String _dietaryType;
  late Set<String> _selectedAllergies;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userPreferencesProvider);
    _isHalalOnly = current.isHalalOnly;
    _dietaryType = current.dietaryType;
    _selectedAllergies = current.allergies.toSet();
  }

  void _save() {
    HapticFeedback.mediumImpact();
    final updated = UserPreferencesModel(
      isHalalOnly: _isHalalOnly,
      dietaryType: _dietaryType,
      allergies: _selectedAllergies.toList(),
    );

    ref.read(userPreferencesProvider.notifier).updatePreferences(updated);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.lang == AppLanguage.id
              ? '✅ Preferensi makanan berhasil disimpan!'
              : '✅ Dietary preferences saved successfully!',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isId = widget.lang == AppLanguage.id;

    final dietaryOptions = [
      {
        'key': 'none',
        'icon': '🍽️',
        'title': isId ? 'Bebas / Semua' : 'All / Unrestricted',
        'desc': isId
            ? 'Bisa makan semua menu tanpa batasan'
            : 'Enjoy all menus with no dietary restrictions',
      },
      {
        'key': 'vegetarian',
        'icon': '🥗',
        'title': 'Vegetarian',
        'desc': isId
            ? 'Bebas daging & unggas, nabati + telur/susu'
            : 'Plant-based with dairy & eggs, no meat',
      },
      {
        'key': 'vegan',
        'icon': '🌱',
        'title': 'Vegan',
        'desc': isId
            ? '100% murni nabati tanpa produk hewani'
            : '100% plant-based, strictly zero animal products',
      },
      {
        'key': 'low_calorie',
        'icon': '🥑',
        'title': isId ? 'Rendah Kalori / Diet' : 'Low Calorie / Diet',
        'desc': isId
            ? 'Fokus porsi sehat & kalori terkontrol'
            : 'Nutrient-rich, calorie-conscious meals',
      },
      {
        'key': 'low_carb',
        'icon': '🥩',
        'title': isId ? 'Keto / Rendah Karbo' : 'Keto / Low Carb',
        'desc': isId
            ? 'Tinggi protein & lemak sehat, minim tepung'
            : 'High protein & healthy fats, minimal carbs',
      },
      {
        'key': 'pescatarian',
        'icon': '🐟',
        'title': 'Pescatarian',
        'desc': isId
            ? 'Kombinasi ikan & hidangan laut + nabati'
            : 'Fish & seafood combined with vegetarian base',
      },
    ];

    final allergyOptions = [
      {'key': 'gluten_free', 'label': isId ? 'Bebas Gluten 🌾' : 'Gluten-Free 🌾'},
      {'key': 'nut_free', 'label': isId ? 'Bebas Kacang 🥜' : 'Nut-Free 🥜'},
      {'key': 'seafood_free', 'label': isId ? 'Bebas Seafood 🦐' : 'Seafood-Free 🦐'},
      {'key': 'dairy_free', 'label': isId ? 'Bebas Susu / Laktosa 🥛' : 'Dairy-Free 🥛'},
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.redBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isId
                            ? 'Preferensi Makanan & Diet'
                            : 'Dietary & Food Preferences',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isId
                            ? 'AI akan menyaring makanan sesuai gaya hidupmu'
                            : 'AI will tailor meals to your lifestyle',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Halal Toggle Card
                  Text(
                    isId ? 'STANDAR HALAL' : 'HALAL STANDARD',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isHalalOnly ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isHalalOnly ? const Color(0xFF22C55E) : Colors.grey.shade200,
                        width: _isHalalOnly ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isHalalOnly
                                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🟢', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isId ? 'Wajib Halal Saja' : 'Halal Only',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isId
                                    ? 'Hanya pilih resto & hidangan bebas babi, arak, atau non-halal'
                                    : 'Strictly filter out pork, alcohol, or non-halal ingredients',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isHalalOnly,
                          activeTrackColor: const Color(0xFF22C55E),
                          onChanged: (val) {
                            setState(() {
                              _isHalalOnly = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Dietary Types
                  Text(
                    isId ? 'POLA MAKAN & DIET UTAMA' : 'PRIMARY DIETARY STYLE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dietaryOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final item = dietaryOptions[index];
                      final isSelected = _dietaryType == item['key'];

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _dietaryType = item['key']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.redBg.withValues(alpha: 0.4) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(item['icon']!, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['desc']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Allergies / Pantangan Tambahan
                  Text(
                    isId ? 'PANTANGAN & ALERGI BAHAN' : 'ALLERGIES & RESTRICTIONS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isId
                        ? 'AI akan menghindari bahan-bahan berikut dalam saran menu & resep'
                        : 'AI will exclude these ingredients from menus and ideas',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allergyOptions.map((opt) {
                      final key = opt['key']!;
                      final isSelected = _selectedAllergies.contains(key);

                      return FilterChip(
                        label: Text(opt['label']!),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (val) {
                              _selectedAllergies.add(key);
                            } else {
                              _selectedAllergies.remove(key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isId ? 'Simpan Preferensi' : 'Save Preferences',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
