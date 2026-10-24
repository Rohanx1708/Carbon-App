import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:attendance/core/feedback/user_facing_error.dart';
import 'package:attendance/features/settings/data/office_settings_service.dart';

/// Location checks for check-in / check-out, driven by the office settings API
/// (`geofence_enabled`, `latitude`, `longitude`, `geofence_radius`).
abstract final class OfficeGeofence {
  static final OfficeSettingsService _settingsService = OfficeSettingsService();

  /// Current device position, after making sure location is on and permitted.
  static Future<Position> currentPosition({String action = 'check in'}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw UserMessageError('Turn on location services to $action.');
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw UserMessageError('Location access is blocked. Allow it in Settings to $action.');
    }
    if (permission == LocationPermission.denied) {
      throw UserMessageError('Location access is needed to $action.');
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
      );
    } catch (_) {
      throw UserMessageError('Could not get your location. Move to an open area and try again.');
    }

    if (position.isMocked) {
      throw UserMessageError('Mock locations are not allowed. Turn off any location spoofing apps to $action.');
    }
    return position;
  }

  /// Returns the current position, throwing a [UserMessageError] when the
  /// office geofence is enabled and the device is outside its radius.
  static Future<Position> verify({String action = 'check in'}) async {
    final position = await currentPosition(action: action);

    OfficeSettings? settings;
    try {
      settings = await _settingsService.fetch();
    } catch (e) {
      // The server validates the location on check-in/out as well.
      debugPrint('[OfficeGeofence] could not load office settings: $e');
    }

    if (settings != null && settings.hasActiveGeofence) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        settings.latitude!,
        settings.longitude!,
      );
      if (distance > settings.geofenceRadius) {
        throw UserMessageError(
          'You are ${_formatDistance(distance)} away from the office. '
          'You can only $action within ${settings.geofenceRadius.round()} m of the office.',
        );
      }
    }
    return position;
  }

  static String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }
}
