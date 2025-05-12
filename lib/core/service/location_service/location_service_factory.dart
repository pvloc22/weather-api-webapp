import 'package:flutter/foundation.dart';
import 'package:golden_owl/core/service/location_service/location_service.dart';
import 'package:golden_owl/core/service/location_service/mobile_location_service.dart';

// Conditional import
import 'website_location_service.dart' if (dart.library.io) 'unsupported_location_service.dart';

class LocationServiceFactory {
  static LocationService getLocationService() {
    if (kIsWeb) {
      return WebsiteLocationService();
    } else {
      return MobileLocationService();
    }
  }
} 