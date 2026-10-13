import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocation {
  final double latitude;
  final double longitude;
  final String cityName;
  final String subDistrict;
  final bool isGpsAcquired;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.subDistrict = '',
    required this.isGpsAcquired,
  });

  String get displayLabel {
    if (subDistrict.isNotEmpty) {
      return '$subDistrict, $cityName';
    }
    return cityName;
  }
}

class LocationNotifier extends StateNotifier<UserLocation> {
  LocationNotifier()
      : super(const UserLocation(
          latitude: -6.2297,
          longitude: 106.8295,
          cityName: 'Mendeteksi Lokasi...',
          isGpsAcquired: false,
        ));

  /// Requests runtime permission from Android and fetches live GPS coordinates
  Future<void> detectCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied by user.');
          state = const UserLocation(
            latitude: -6.1754,
            longitude: 106.8272,
            cityName: 'Jakarta Pusat',
            isGpsAcquired: false,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever.');
        state = const UserLocation(
          latitude: -6.1754,
          longitude: 106.8272,
          cityName: 'Jakarta Pusat',
          isGpsAcquired: false,
        );
        return;
      }

      // Permissions granted, fetch high accuracy position with fallback to last known
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        final reverseResult = await _reverseGeocode(position.latitude, position.longitude);
        state = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: reverseResult['city'] ?? 'Jakarta',
          subDistrict: reverseResult['subDistrict'] ?? '',
          isGpsAcquired: true,
        );
        debugPrint('GPS Acquired: ${position.latitude}, ${position.longitude} -> ${state.cityName}');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void setManualLocation({
    required double latitude,
    required double longitude,
    required String cityName,
    String subDistrict = '',
  }) {
    state = UserLocation(
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
      subDistrict: subDistrict,
      isGpsAcquired: true,
    );
  }

  /// Fast reverse geocoding via OpenStreetMap Nominatim
  Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MoodEatsApp/1.0 (moodeats@moodeats.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          // Detect specific administrative city (e.g., Jakarta Utara, Jakarta Selatan, etc.)
          final cityDistrict = address['city_district']?.toString();
          final municipality = address['municipality']?.toString();
          final rawCity = address['city']?.toString();
          final county = address['county']?.toString();
          final stateName = address['state']?.toString();

          String city = '';
          if (cityDistrict != null && cityDistrict.toLowerCase().contains('jakarta')) {
            city = cityDistrict;
          } else if (municipality != null && municipality.toLowerCase().contains('jakarta')) {
            city = municipality;
          } else if (county != null && county.toLowerCase().contains('jakarta')) {
            city = county;
          } else if (cityDistrict != null && cityDistrict.isNotEmpty) {
            city = cityDistrict;
          } else if (rawCity != null && !rawCity.toLowerCase().contains('daerah khusus')) {
            city = rawCity;
          } else {
            city = rawCity ?? county ?? stateName ?? 'Jakarta Pusat';
          }

          final subDistrict = address['suburb'] ??
              address['neighbourhood'] ??
              address['village'] ??
              address['quarter'] ??
              '';

          return {
            'city': city
                .replaceAll('Kota Administrasi ', '')
                .replaceAll('Daerah Khusus Ibukota ', '')
                .replaceAll('Kota ', '')
                .trim(),
            'subDistrict': subDistrict.toString().trim(),
          };
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    // Heuristic fallback based on coordinates in Jakarta
    if (lat > -6.16) {
      return {'city': 'Jakarta Utara', 'subDistrict': 'Tanjung Priok'};
    } else if (lat > -6.20) {
      return {'city': 'Jakarta Pusat', 'subDistrict': 'Menteng'};
    } else {
      return {'city': 'Jakarta Selatan', 'subDistrict': 'Kebayoran'};
    }
  }
}

final userLocationProvider =
    StateNotifierProvider<LocationNotifier, UserLocation>((ref) {
  final notifier = LocationNotifier();
  // Trigger initial GPS acquisition
  notifier.detectCurrentLocation();
  return notifier;
});
