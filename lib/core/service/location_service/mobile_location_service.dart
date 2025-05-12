import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:golden_owl/core/service/location_service/location_service.dart';

class MobileLocationService extends LocationService {
  Future<List<double>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, try to enable them
      return Future.error('Location services are disabled. Please enable location services in settings.');
    }

    // Check if we have permission to access location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission to access location
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting permissions again
        return Future.error('Location permission denied. Please allow the app to access your location.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      // Try to open app settings to let the user enable location permissions
      final opened = await Geolocator.openAppSettings();
      if (!opened) {
        return Future.error('Location permissions permanently denied. Please enable location permissions in app settings.');
      }
      
      // The user might have changed permissions, check again
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are still denied. Please grant location permissions to use this feature.');
      }
    }

    try {
      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      return [position.latitude, position.longitude];
    } catch (e) {
      return Future.error('Failed to get current location: $e');
    }
  }
}