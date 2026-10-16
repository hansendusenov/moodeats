import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences_model.dart';
import '../providers/app_providers.dart';
import 'firebase_auth_service.dart';

class PreferencesService {
  static String? _baseDirPath;
  static UserPreferencesModel _webPrefs = const UserPreferencesModel();

  static String get _getStorageDir {
    if (_baseDirPath != null) return _baseDirPath!;
    if (Platform.isAndroid) {
      final candidates = [
        '/data/user/0/com.moodeats.moodeats_app/app_flutter',
        '/data/user/0/com.moodeats.moodeats_app/files',
        '/data/data/com.moodeats.moodeats_app/app_flutter',
        '/data/data/com.moodeats.moodeats_app/files',
      ];
      for (final p in candidates) {
        final d = Directory(p);
        if (d.existsSync()) {
          _baseDirPath = p;
          return p;
        }
      }
    }
    _baseDirPath = Directory.systemTemp.path;
    return _baseDirPath!;
  }

  static String get _filePath => '$_getStorageDir/moodeats_preferences.json';

  static UserPreferencesModel load() {
    if (kIsWeb) return _webPrefs;
    try {
      final file = File(_filePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final map = jsonDecode(content) as Map<String, dynamic>;
        return UserPreferencesModel.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
    return const UserPreferencesModel();
  }

  static void save(UserPreferencesModel prefs) {
    if (kIsWeb) {
      _webPrefs = prefs;
      return;
    }
    try {
      final file = File(_filePath);
      file.writeAsStringSync(jsonEncode(prefs.toJson()), flush: true);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }
}

class PreferencesNotifier extends StateNotifier<UserPreferencesModel> {
  final Ref _ref;

  PreferencesNotifier(this._ref) : super(PreferencesService.load());

  Future<void> updatePreferences(UserPreferencesModel newPrefs) async {
    state = newPrefs;
    PreferencesService.save(newPrefs);

    // Sync with backend if user is logged in
    try {
      final user = _ref.read(authUserProvider);
      if (user != null && user.id.isNotEmpty) {
        final api = _ref.read(apiServiceProvider);
        await api.syncUserProfile(
          userId: user.id,
          email: user.email,
          displayName: user.displayName.isNotEmpty ? user.displayName : user.email.split('@').first,
          birthDate: user.birthDate,
          gender: user.gender,
          isHalalOnly: newPrefs.isHalalOnly,
          dietaryType: newPrefs.dietaryType,
          allergies: newPrefs.allergies,
        );
      }
    } catch (e) {
      debugPrint('Error syncing preferences to backend: $e');
    }
  }

  void toggleHalalOnly() {
    final next = !state.isHalalOnly;
    updatePreferences(state.copyWith(isHalalOnly: next));
  }

  void toggleOpenNowOnly() {
    final next = !state.isOpenNowOnly;
    updatePreferences(state.copyWith(isOpenNowOnly: next));
  }
}

final userPreferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferencesModel>((ref) {
  return PreferencesNotifier(ref);
});
