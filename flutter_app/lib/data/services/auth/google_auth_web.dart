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
