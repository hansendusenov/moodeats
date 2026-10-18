import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.en);

  void setLanguage(AppLanguage lang) {
    state = lang;
  }

  void toggleLanguage() {
    state = state == AppLanguage.id ? AppLanguage.en : AppLanguage.id;
  }
}

final appLanguageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});
