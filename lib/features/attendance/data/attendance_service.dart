import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceRecord {
  final DateTime timestamp;
  final String action; 
  final double latitude;
  final double longitude;
  final String? address;

  AttendanceRecord({
    required this.timestamp,
    required this.action,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        timestamp: DateTime.parse(json['timestamp'] as String),
        action: json['action'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
      );
}

class AttendanceService {
  static const String _storageKey = 'attendance_records_v1';
  static const String _geofenceCacheKey = 'geofence_target_cache_v1';

  // Geofence configuration
  static const String geofenceAddress = '834X+54 Dehradun, Uttarakhand 248001';
  static const double geofenceRadiusMeters = 200.0;

  Future<(double lat, double lng)> _getGeofenceTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_geofenceCacheKey);
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        final lat = (map['lat'] as num).toDouble();
        final lng = (map['lng'] as num).toDouble();
        return (lat, lng);
      } catch (_) {}
    }

    // Resolve address to coordinates and cache
    final locations = await locationFromAddress(geofenceAddress);
    if (locations.isEmpty) {
      throw Exception('Unable to resolve geofence address. Please check network and try again.');
    }
    final loc = locations.first;
    await prefs.setString(_geofenceCacheKey, jsonEncode({'lat': loc.latitude, 'lng': loc.longitude}));
    return (loc.latitude, loc.longitude);
  }

  Future<bool> ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
    
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  // Try to obtain a more accurate fix by listening briefly to the stream
  Future<Position> getAccuratePosition({Duration timeout = const Duration(seconds: 8)}) async {
    Position? best;
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).takeWhile((_) => true);

    try {
      final sub = stream.listen((pos) {
        if (best == null || (pos.accuracy < (best!.accuracy))) {
          best = pos;
        }
      });
      await Future<void>.delayed(timeout);
      await sub.cancel();
    } catch (_) {
      // ignore and fallback
    }

    if (best != null) return best!;
    return getCurrentPosition();
  }

  Future<String?> reverseGeocode({required double latitude, required double longitude}) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.postalCode,
        p.country,
      ].where((e) => (e ?? '').toString().trim().isNotEmpty).toList();
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<List<AttendanceRecord>> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    return raw
        .map((e) => AttendanceRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _saveRecords(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = records.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<AttendanceRecord> punch({required String action}) async {
    final hasPerm = await ensureLocationPermission();
    if (!hasPerm) {
      throw Exception('Location permission not granted or services disabled');
    }

    final pos = await getAccuratePosition();

    // Enforce geofence radius
    final (targetLat, targetLng) = await _getGeofenceTarget();
    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      targetLat,
      targetLng,
    );
    if (distance > geofenceRadiusMeters) {
      throw Exception('You are outside the allowed attendance area (>${geofenceRadiusMeters.toStringAsFixed(0)} m).');
    }
    final address = await reverseGeocode(latitude: pos.latitude, longitude: pos.longitude);
    final record = AttendanceRecord(
      timestamp: DateTime.now(),
      action: action,
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: address,
    );
    final list = await _loadRecords();
    list.insert(0, record);
    await _saveRecords(list);
    return record;
  }

  Future<List<AttendanceRecord>> records() => _loadRecords();

  Future<void> clearAll() async {
    await _saveRecords(<AttendanceRecord>[]);
  }
}


