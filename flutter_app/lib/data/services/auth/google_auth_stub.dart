// Stub for non-web platforms
Future<Map<String, dynamic>> signInWithPopup() async {
  throw UnsupportedError('Popup is only supported on Web');
}

String getWebSavedSession() => '';
void saveWebSession(String json) {}
void clearWebSession() {}
String getWebSavedProfilesDb() => '{}';
void saveWebProfilesDb(String jsonStr) {}
bool hasProfileUpdated() => false;
void setProfileUpdated(bool val) {}
