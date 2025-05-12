import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:golden_owl/core/service/smtp_service/smtp_service.dart';
import 'package:golden_owl/data/remote/weather_api_client.dart';

class EmailSubscriptionRepository {
  static final EmailSubscriptionRepository _instance = EmailSubscriptionRepository._internal();
  
  factory EmailSubscriptionRepository() {
    return _instance;
  }
  
  EmailSubscriptionRepository._internal();
  
  final SmtpService _smtpService = SmtpService();
  
  // Generate a 6-digit OTP code
  String generateOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }
  
  // Save email and OTP temporarily for verification
  Future<void> saveEmailAndOtp(String email, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_verification_email', email);
      await prefs.setString('verification_otp', otp);
      await prefs.setInt('otp_creation_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // debugPrint('Error saving email and OTP: $e');
    }
  }
  
  // Verify OTP code
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('pending_verification_email');
      final storedOtp = prefs.getString('verification_otp');
      final otpCreationTime = prefs.getInt('otp_creation_time') ?? 0;
      
      // Check if OTP has expired (10 minutes)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final otpAge = currentTime - otpCreationTime;
      final tenMinutesInMillis = 10 * 60 * 1000;
      
      if (otpAge > tenMinutesInMillis) {
        // debugPrint('OTP expired');
        return false;
      }
      
      // Always require correct OTP and email match, even on web
      return email == storedEmail && otp == storedOtp;
    } catch (e) {
      // debugPrint('Error verifying OTP: $e');
      return false; // Don't accept OTP in case of errors
    }
  }
  
  // Save subscription details
  Future<void> saveSubscription(String email, String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscribed_email', email);
      await prefs.setString('subscribed_location', location);
      await prefs.setBool('is_subscribed', true);
      await prefs.setInt('subscription_date', DateTime.now().millisecondsSinceEpoch);
      
      // Clear verification data
      await prefs.remove('pending_verification_email');
      await prefs.remove('verification_otp');
      await prefs.remove('otp_creation_time');
    } catch (e) {
      // debugPrint('Error saving subscription: $e');
    }
  }
  
  // Check if a user is subscribed
  Future<bool> isSubscribed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_subscribed') ?? false;
    } catch (e) {
      // debugPrint('Error checking subscription status: $e');
      return false;
    }
  }
  
  // Get subscription details
  Future<Map<String, String>> getSubscriptionDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('subscribed_email') ?? '';
      final location = prefs.getString('subscribed_location') ?? '';
      return {
        'email': email,
        'location': location,
      };
    } catch (e) {
      // debugPrint('Error getting subscription details: $e');
      return {
        'email': '',
        'location': '',
      };
    }
  }
  
  // Get all subscriptions from SharedPreferences
  // In a real app, this would likely come from a database
  Future<List<Map<String, String>>> getAllSubscriptions() async {
    try {
      // For demo purposes, we'll just return the current user's subscription
      final details = await getSubscriptionDetails();
      if (details['email']!.isEmpty) {
        return [];
      }
      return [details];
    } catch (e) {
      // debugPrint('Error getting all subscriptions: $e');
      return [];
    }
  }
  
  // Unsubscribe
  Future<void> unsubscribe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('subscribed_email');
      
      if (email != null && email.isNotEmpty) {
        await _smtpService.sendUnsubscribeConfirmation(recipientEmail: email);
      }
      
      await prefs.remove('subscribed_email');
      await prefs.remove('subscribed_location');
      await prefs.setBool('is_subscribed', false);
    } catch (e) {
      // debugPrint('Error unsubscribing: $e');
      // Still consider unsubscribed even if there's an error
    }
  }
  
  // Send verification email
  Future<bool> sendVerificationEmail(String email) async {
    final otp = generateOtp();
    // debugPrint('Generated OTP: $otp'); // For testing purposes
    
    final result = await _smtpService.sendVerificationEmail(
      recipientEmail: email,
      otp: otp,
    );
    
    if (result) {
      await saveEmailAndOtp(email, otp);
    }
    
    return result;
  }
  
  // Send subscription confirmation
  Future<bool> sendSubscriptionConfirmation(String email, String location) async {
    try {
      // Fetch current weather data for the location
      final weatherApiClient = WeatherApiClient();
      final currentWeather = await weatherApiClient.fetchCurrentWeatherWithCityName(location);
      
      // Create a map with all the weather information
      final weatherData = {
        'city_name': currentWeather.cityName ?? location,
        'temperature': currentWeather.temperature ?? 'N/A',
        'condition': currentWeather.iconText ?? 'Unknown',
        'wind_speed': currentWeather.windSpeed ?? 'N/A',
        'humidity': currentWeather.humidity ?? 'N/A',
        'icon_url': currentWeather.iconUrl ?? 'https://openweathermap.org/img/wn/10d@2x.png',
        'date': currentWeather.date ?? DateTime.now().toString().substring(0, 10)
      };
      
      // Send email with weather data
      return await _smtpService.sendSubscriptionConfirmation(
        recipientEmail: email,
        location: location,
        weatherData: weatherData,
      );
    } catch (e) {
      // If weather data fetch fails, still send the basic confirmation email
      return await _smtpService.sendSubscriptionConfirmation(
        recipientEmail: email,
        location: location,
      );
    }
  }
  
  // Send a daily forecast email to current user
  Future<bool> sendDailyForecast(Map<String, dynamic> forecastData) async {
    final subscriptionDetails = await getSubscriptionDetails();
    final email = subscriptionDetails['email'] ?? '';
    final location = subscriptionDetails['location'] ?? '';
    
    if (email.isEmpty || location.isEmpty) {
      return false;
    }
    
    // Add location to forecast data
    final Map<String, dynamic> enhancedForecastData = Map.from(forecastData);
    enhancedForecastData['city_name'] = location;
    
    // Add more weather details if available (example values for mock data)
    if (!enhancedForecastData.containsKey('feels_like')) {
      enhancedForecastData['feels_like'] = (forecastData['temperature'] as num?)?.toDouble()?.round() ?? 'N/A';
    }
    
    if (!enhancedForecastData.containsKey('pressure')) {
      enhancedForecastData['pressure'] = '1013'; // Example default
    }
    
    if (!enhancedForecastData.containsKey('uv_index')) {
      enhancedForecastData['uv_index'] = '3'; // Example default
    }
    
    if (!enhancedForecastData.containsKey('visibility')) {
      enhancedForecastData['visibility'] = '10 km'; // Example default
    }
    
    if (!enhancedForecastData.containsKey('sunrise')) {
      enhancedForecastData['sunrise'] = '06:30 AM'; // Example default
    }
    
    if (!enhancedForecastData.containsKey('sunset')) {
      enhancedForecastData['sunset'] = '06:30 PM'; // Example default
    }
    
    return await _smtpService.sendDailyForecast(
      recipientEmail: email,
      location: location,
      forecastData: enhancedForecastData,
    );
  }
  
  // Send a daily forecast email to all subscribers
  Future<Map<String, bool>> sendDailyForecastToAllSubscribers(
    Map<String, dynamic> globalForecastData
  ) async {
    try {
      // Get all subscriptions
      final subscriptions = await getAllSubscriptions();
      
      if (subscriptions.isEmpty) {
        // debugPrint('No subscribers found');
        return {};
      }
      
      // Use bulk send for better performance
      return await _smtpService.bulkSendForecast(
        recipients: subscriptions,
        globalForecastData: globalForecastData,
      );
    } catch (e) {
      // debugPrint('Error sending forecasts to all subscribers: $e');
      return {};
    }
  }
  
  // Configure the forecast data from WeatherResponse model
  Map<String, dynamic> prepareForecastDataFromWeatherResponse(dynamic weatherResponse) {
    if (weatherResponse == null) {
      return {
        'temperature': 'N/A',
        'condition': 'Unknown',
        'humidity': 'N/A',
        'wind_speed': 'N/A',
        'icon_url': 'https://openweathermap.org/img/wn/10d@2x.png',
        'date': DateTime.now().toString().split(' ')[0],
        'city_name': 'Unknown Location',
      };
    }
    
    try {
      final currentWeather = weatherResponse.currentWeather;
      final forecastDays = weatherResponse.forecastWeather;
      
      // Format temperature and numbers for better display
      final formattedTemp = currentWeather.temperature != null 
          ? currentWeather.temperature.toStringAsFixed(1) 
          : 'N/A';
      
      final formattedHumidity = currentWeather.humidity != null 
          ? currentWeather.humidity.toString() 
          : 'N/A';
      
      final formattedWindSpeed = currentWeather.windSpeed != null 
          ? currentWeather.windSpeed.toStringAsFixed(1) 
          : 'N/A';
      
      // Calculate feels like temperature (simplified version)
      final feelsLike = currentWeather.temperature != null
          ? (currentWeather.temperature + (currentWeather.humidity != null && currentWeather.humidity > 70 ? 2 : -1)).toStringAsFixed(1)
          : 'N/A';
      
      // Format date in a more readable way if possible
      String formattedDate = currentWeather.date ?? DateTime.now().toString().split(' ')[0];
      try {
        final date = DateTime.parse(formattedDate);
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        // Keep original format if parsing fails
      }
      
      // Determine the time of day based on current time to calculate sunrise/sunset
      final now = DateTime.now();
      final sunriseTime = '${(now.hour + 24 - 12) % 24}:${now.minute.toString().padLeft(2, '0')} AM';
      final sunsetTime = '${(now.hour + 12) % 12}:${now.minute.toString().padLeft(2, '0')} PM';
      
      final forecastData = {
        // Basic weather data
        'temperature': formattedTemp,
        'condition': currentWeather.iconText ?? 'Unknown',
        'humidity': formattedHumidity,
        'wind_speed': formattedWindSpeed,
        'icon_url': currentWeather.iconUrl ?? 'https://openweathermap.org/img/wn/10d@2x.png',
        'date': formattedDate,
        'city_name': currentWeather.cityName ?? 'Unknown Location',
        
        // Enhanced weather data
        'feels_like': feelsLike,
        'pressure': '1013 hPa', // Example default if not available in model
        'uv_index': currentWeather.humidity != null 
            ? (currentWeather.humidity > 80 ? '2' : (currentWeather.humidity > 50 ? '5' : '8')) 
            : '4',
        'visibility': currentWeather.humidity != null 
            ? (currentWeather.humidity > 80 ? '5 km' : (currentWeather.humidity > 50 ? '10 km' : '20+ km')) 
            : '10 km',
        'sunrise': sunriseTime,
        'sunset': sunsetTime,
        
        // Additional useful information
        'description': currentWeather.iconText != null 
            ? _getExpandedWeatherDescription(currentWeather.iconText) 
            : 'Variable weather conditions expected for today.',
        'last_updated': 'Updated ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'location_details': currentWeather.cityName != null 
            ? _getLocationDetails(currentWeather.cityName) 
            : '',
      };
      
      // Add forecast days if available
      if (forecastDays != null && forecastDays.isNotEmpty) {
        final List<Map<String, dynamic>> forecastList = [];
        
        for (var forecast in forecastDays) {
          // Format date for forecast days
          String forecastFormattedDate = forecast.date ?? '';
          try {
            final date = DateTime.parse(forecastFormattedDate);
            forecastFormattedDate = '${date.day}/${date.month}';
          } catch (e) {
            // Keep original format if parsing fails
          }
          
          final formattedForecastTemp = forecast.temperature != null 
              ? forecast.temperature.toStringAsFixed(1) 
              : 'N/A';
          
          forecastList.add({
            'temperature': formattedForecastTemp,
            'icon_text': forecast.iconText ?? 'Unknown',
            'icon_url': forecast.iconUrl ?? 'https://openweathermap.org/img/wn/10d@2x.png',
            'date': forecastFormattedDate,
            'humidity': forecast.humidity?.toString() ?? 'N/A',
            'wind_speed': forecast.windSpeed != null ? forecast.windSpeed.toStringAsFixed(1) : 'N/A',
            'description': forecast.iconText != null 
                ? _getShortWeatherDescription(forecast.iconText) 
                : 'Variable conditions',
          });
        }
        
        forecastData['forecast_days'] = forecastList;
      }
      
      return forecastData;
    } catch (e) {
      // debugPrint('Error preparing forecast data: $e');
      return {
        'temperature': 'N/A',
        'condition': 'Unknown',
        'humidity': 'N/A',
        'wind_speed': 'N/A',
        'icon_url': 'https://openweathermap.org/img/wn/10d@2x.png',
        'date': DateTime.now().toString().split(' ')[0],
        'city_name': 'Unknown Location',
      };
    }
  }
  
  // Helper method to generate more detailed weather descriptions
  String _getExpandedWeatherDescription(String? condition) {
    if (condition == null) return 'Variable weather conditions expected.';
    
    condition = condition.toLowerCase();
    
    if (condition.contains('rain') || condition.contains('shower')) {
      return 'Precipitation expected. Don\'t forget your umbrella and waterproof clothing.';
    } else if (condition.contains('cloud')) {
      return 'Cloudy skies expected. Temperature might feel cooler than indicated.';
    } else if (condition.contains('sun') || condition.contains('clear')) {
      return 'Clear skies with abundant sunshine. UV index may be high - consider sun protection.';
    } else if (condition.contains('snow') || condition.contains('sleet')) {
      return 'Snow or winter precipitation expected. Dress warmly and be cautious when traveling.';
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return 'Reduced visibility due to fog or mist. Take care when driving or commuting.';
    } else if (condition.contains('wind') || condition.contains('storm')) {
      return 'Windy or stormy conditions expected. Secure loose items outdoors.';
    } else {
      return 'Mixed weather conditions expected. Check for updates throughout the day.';
    }
  }
  
  // Helper method to generate shorter weather descriptions for forecast days
  String _getShortWeatherDescription(String? condition) {
    if (condition == null) return 'Variable';
    
    condition = condition.toLowerCase();
    
    if (condition.contains('rain') || condition.contains('shower')) {
      return 'Rainy';
    } else if (condition.contains('cloud')) {
      return 'Cloudy';
    } else if (condition.contains('sun') || condition.contains('clear')) {
      return 'Sunny';
    } else if (condition.contains('snow') || condition.contains('sleet')) {
      return 'Snowy';
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return 'Foggy';
    } else if (condition.contains('wind') || condition.contains('storm')) {
      return 'Windy';
    } else {
      return 'Mixed';
    }
  }
  
  // Helper to generate location details based on city name
  String _getLocationDetails(String? cityName) {
    if (cityName == null || cityName.isEmpty) return '';
    
    // For cities that include country information like "Paris, France"
    if (cityName.contains(',')) {
      return 'Local forecast for $cityName';
    }
    
    // For cities without country information
    return 'Local forecast for $cityName';
  }
} 