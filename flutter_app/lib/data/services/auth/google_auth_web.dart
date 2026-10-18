import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:convert';

Future<Map<String, dynamic>> signInWithPopup() async {
  try {
    final promise = globalContext.callMethod('triggerGoogleAuthPopup'.toJS) as JSPromise<JSString>;
    final jsStr = await promise.toDart;
    return jsonDecode(jsStr.toDart) as Map<String, dynamic>;
  } catch (e) {
    return {'success': false, 'errorMessage': e.toString()};
  }
}

String getWebSavedSession() {
  try {
    final res = globalContext.callMethod('getWebSession'.toJS) as JSString?;
    return res?.toDart ?? '';
  } catch (_) {
    return '';
  }
}

void saveWebSession(String jsonStr) {
  try {
    globalContext.callMethod('saveWebSession'.toJS, jsonStr.toJS);
  } catch (_) {}
}

void clearWebSession() {
  try {
    globalContext.callMethod('clearWebSession'.toJS);
  } catch (_) {}
}

String getWebSavedProfilesDb() {
  try {
    final res = globalContext.callMethod('getWebProfilesDb'.toJS) as JSString?;
    return res?.toDart ?? '{}';
  } catch (_) {
    return '{}';
  }
}

void saveWebProfilesDb(String jsonStr) {
  try {
    globalContext.callMethod('saveWebProfilesDb'.toJS, jsonStr.toJS);
  } catch (_) {}
}

bool hasProfileUpdated() {
  try {
    final res = globalContext.callMethod('hasProfileUpdated'.toJS) as JSBoolean?;
    return res?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

void setProfileUpdated(bool val) {
  try {
    globalContext.callMethod('setProfileUpdated'.toJS, val.toJS);
  } catch (_) {}
}
