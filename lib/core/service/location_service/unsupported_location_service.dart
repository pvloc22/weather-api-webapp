import 'package:golden_owl/core/service/location_service/location_service.dart';

// This class is a stub implementation for platforms that don't support WebsiteLocationService
class WebsiteLocationService extends LocationService {
  @override
  Future<List<double>?> getCurrentLocation() async {
    throw UnsupportedError('Web location service is not available on this platform. Please use the mobile location service instead.');
  }
} 