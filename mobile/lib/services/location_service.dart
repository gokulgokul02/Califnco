// ============================================================
// Location Service — Califnco Water Purifiers
// Uses: Geolocator (GPS) + OpenStreetMap Nominatim (Free reverse geocode)
//       + OpenStreetMap tiles (100% Free, no Google Maps API key needed)
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class UserLocationResult {
  final LatLng position;
  final String formattedAddress;
  final String city;
  final String state;
  final String postalCode;

  UserLocationResult({
    required this.position,
    required this.formattedAddress,
    required this.city,
    required this.state,
    required this.postalCode,
  });
}

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  // Geoapify API Key (Free tier - no credit card required)
  static const String geoapifyApiKey = 'be0865153ff4415589e053201f89f6d8';

  // Default fallback: Califnco HQ / Central Service Hub (Chennai)
  static const LatLng defaultLocation = LatLng(13.0827, 80.2707);

  /// Determine the current position of the device.
  Future<UserLocationResult?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions permanently denied');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      final addressData = await getAddressFromCoordinates(latLng);

      return addressData ??
          UserLocationResult(
            position: latLng,
            formattedAddress: 'Location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
            city: 'Chennai',
            state: 'Tamil Nadu',
            postalCode: '600001',
          );
    } catch (e) {
      debugPrint('[LocationService] Error fetching location: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to a readable address using Geoapify with OpenStreetMap fallback
  Future<UserLocationResult?> getAddressFromCoordinates(LatLng latLng) async {
    // 1. Try Geoapify API (Fast, precise, formatted address)
    if (geoapifyApiKey.isNotEmpty) {
      try {
        final geoUrl = Uri.parse(
          'https://api.geoapify.com/v1/geocode/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&apiKey=$geoapifyApiKey',
        );
        final geoRes = await http.get(geoUrl).timeout(const Duration(seconds: 4));
        if (geoRes.statusCode == 200) {
          final data = jsonDecode(geoRes.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>?;
          if (features != null && features.isNotEmpty) {
            final props = (features.first['properties'] as Map<String, dynamic>?) ?? {};
            final formatted = props['formatted'] as String? ?? '';
            final city = props['city'] as String? ?? props['county'] as String? ?? 'Chennai';
            final state = props['state'] as String? ?? 'Tamil Nadu';
            final postcode = props['postcode'] as String? ?? '600001';

            if (formatted.isNotEmpty) {
              return UserLocationResult(
                position: latLng,
                formattedAddress: formatted,
                city: city.toString(),
                state: state.toString(),
                postalCode: postcode.toString(),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[LocationService] Geoapify reverse geocode fallback note: $e');
      }
    }

    // 2. Fallback to OpenStreetMap Nominatim
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'CalifncoWaterApp/1.0 (support@califnco.com)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = (data['address'] as Map<String, dynamic>?) ?? {};

        final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? '';
        final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['state_district'] ?? 'Chennai';
        final state = addr['state'] ?? 'Tamil Nadu';
        final postcode = addr['postcode'] ?? '600001';
        final displayName = (data['display_name'] as String?) ?? '$road, $city, $state - $postcode';

        return UserLocationResult(
          position: latLng,
          formattedAddress: displayName,
          city: city.toString(),
          state: state.toString(),
          postalCode: postcode.toString(),
        );
      }
    } catch (e) {
      debugPrint('[LocationService] OSM Reverse geocode note: $e');
    }

    return UserLocationResult(
      position: latLng,
      formattedAddress: 'Location (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})',
      city: 'Chennai',
      state: 'Tamil Nadu',
      postalCode: '600001',
    );
  }
}
