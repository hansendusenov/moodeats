import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceTelemetry {
  final String model;
  final String os;
  final String appVersion;

  const DeviceTelemetry({
    required this.model,
    required this.os,
    required this.appVersion,
  });
}

class DeviceInfoService {
  static const MethodChannel _channel =
      MethodChannel('com.moodeats.moodeats_app/device_info');

  static const String appVersion = 'v1.0.2';

  static DeviceTelemetry? _cachedTelemetry;

  static Future<DeviceTelemetry> getTelemetry() async {
    if (_cachedTelemetry != null) {
      return _cachedTelemetry!;
    }
    if (kIsWeb) {
      _cachedTelemetry = const DeviceTelemetry(model: 'Web Browser', os: 'Web Application', appVersion: appVersion);
      return _cachedTelemetry!;
    }

    String model = 'Unknown Device';
    String os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

    if (Platform.isAndroid) {
      try {
        final Map? info = await _channel.invokeMethod<Map>('getDeviceInfo');
        if (info != null) {
          final manufacturer = (info['manufacturer'] ?? '').toString();
          final brand = (info['brand'] ?? '').toString();
          final deviceModel = (info['model'] ?? '').toString();
          final release = (info['release'] ?? '').toString();
          final sdkInt = info['sdkInt']?.toString() ?? '';

          final brandDisplay = brand.isNotEmpty
              ? brand[0].toUpperCase() + brand.substring(1)
              : (manufacturer.isNotEmpty ? manufacturer : 'Android');

          model = '$brandDisplay $deviceModel'.trim();
          os = 'Android $release (SDK $sdkInt)'.trim();
        }
      } catch (e) {
        debugPrint('Could not retrieve native Android device info: $e');
        model = 'Android Mobile Device';
        os = 'Android (${Platform.operatingSystemVersion})';
      }
    } else if (Platform.isIOS) {
      model = 'Apple iPhone';
      os = 'iOS ${Platform.operatingSystemVersion}';
    }

    _cachedTelemetry = DeviceTelemetry(
      model: model,
      os: os,
      appVersion: appVersion,
    );

    return _cachedTelemetry!;
  }
}
