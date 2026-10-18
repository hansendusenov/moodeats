import 'google_auth_stub.dart'
    if (dart.library.js_util) 'google_auth_web.dart' as platform_impl;

class GoogleAuthPlatformHelper {
  static Future<Map<String, dynamic>> signInWithPopup() {
    return platform_impl.signInWithPopup();
  }

  static String getWebSavedSession() {
    return platform_impl.getWebSavedSession();
  }

  static void saveWebSession(String jsonStr) {
    platform_impl.saveWebSession(jsonStr);
  }

  static void clearWebSession() {
    platform_impl.clearWebSession();
  }

  static String getWebSavedProfilesDb() {
    return platform_impl.getWebSavedProfilesDb();
  }

  static void saveWebProfilesDb(String jsonStr) {
    platform_impl.saveWebProfilesDb(jsonStr);
  }

  static bool hasProfileUpdated() {
    return platform_impl.hasProfileUpdated();
  }

  static void setProfileUpdated(bool val) {
    platform_impl.setProfileUpdated(val);
  }
}
