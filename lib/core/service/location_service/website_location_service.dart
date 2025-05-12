import 'dart:async';

import 'package:golden_owl/core/service/location_service/location_service.dart';
import 'dart:html' as html;

class WebsiteLocationService extends LocationService {
  Future<List<double>?> getCurrentLocation() async {
    final completer = Completer<List<double>?>();
    
    try {
      final geolocation = html.window.navigator.geolocation;
      
      geolocation.getCurrentPosition().then((html.Geoposition position) {
        try {
          final lat = position.coords?.latitude;
          final lng = position.coords?.longitude;

          if (lat != null && lng != null) {
            completer.complete([lat.toDouble(), lng.toDouble()]);
          } else {
            completer.completeError("Failed to retrieve location coordinates.");
          }
        } catch (e) {
          completer.completeError("Error processing location data: $e");
        }
      }).catchError((error) {
        if (error is html.PositionError) {
          switch (error.code) {
            case 1: // PERMISSION_DENIED
              completer.completeError("Location permission denied. Please allow location access in your browser.");
              break;
            case 2: // POSITION_UNAVAILABLE
              completer.completeError("Location information is unavailable. Please try again later.");
              break;
            case 3: // TIMEOUT
              completer.completeError("Location request timed out. Please try again.");
              break;
            default:
              completer.completeError("Error: ${error.message}");
          }
        } else {
          completer.completeError("Unknown error getting location: $error");
        }
      });
    } catch (e) {
      completer.completeError("Failed to access location services: $e");
    }

    try {
      return await completer.future;
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}


