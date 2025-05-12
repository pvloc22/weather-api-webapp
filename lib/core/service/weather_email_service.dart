import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherEmailService {
  static final WeatherEmailService _instance = WeatherEmailService._internal();

  factory WeatherEmailService() {
    return _instance;
  }

  WeatherEmailService._internal();

  // Deployed server URL on Render
  final String _baseUrl = 'https://weather-email-express-deployment.onrender.com';

  // API endpoint for sending OTP verification email
  Future<bool> sendVerificationEmail({
    required String recipientEmail,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendVerificationEmail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': recipientEmail,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        if (kDebugMode) {
          print('Failed to send verification email. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending verification email: $e');
        return true;
      }
      return false;
    }
  }

  // API endpoint for sending subscription confirmation
  Future<bool> sendSubscriptionConfirmation({
    required String recipientEmail,
    required String location,
    String? cityDisplay,
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      final String displayLocation = cityDisplay ?? location;
      
      final Map<String, dynamic> requestBody = {
        'email': recipientEmail,
        'location': location,
        'displayLocation': displayLocation,
      };

      if (weatherData != null) {
        requestBody.addAll({
          'cityName': weatherData['city_name'] ?? displayLocation,
          'temperature': weatherData['temperature'] ?? 'N/A',
          'windSpeed': weatherData['wind_speed'] ?? 'N/A',
          'humidity': weatherData['humidity'] ?? 'N/A',
          'iconUrl': weatherData['icon_url'] ?? 'https://openweathermap.org/img/wn/10d@2x.png',
          'iconText': weatherData['condition'] ?? 'Unknown',
          'date': weatherData['date'] ?? 'Today',
        });
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/sendSubscriptionConfirmation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        if (kDebugMode) {
          print('Failed to send subscription confirmation. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending subscription confirmation: $e');
        return true;
      }
      return false;
    }
  }

  // API endpoint for sending unsubscribe confirmation
  Future<bool> sendUnsubscribeConfirmation({
    required String recipientEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendUnsubscribeConfirmation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': recipientEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        if (kDebugMode) {
          print('Failed to send unsubscribe confirmation. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending unsubscribe confirmation: $e');
        return true;
      }
      return false;
    }
  }

  // API endpoint for sending daily weather forecast
  Future<bool> sendDailyForecast({
    required String recipientEmail,
    required String location,
    String? cityDisplay,
    required Map<String, dynamic> forecastData,
  }) async {
    try {
      final String displayLocation = cityDisplay ?? location;
      final String cityName = forecastData['city_name'] ?? displayLocation;
      
      final Map<String, dynamic> requestBody = {
        'email': recipientEmail,
        'location': location,
        'displayLocation': displayLocation,
        'cityName': cityName,
        'temperature': forecastData['temperature'] ?? 'N/A',
        'windSpeed': forecastData['wind_speed'] ?? 'N/A',
        'humidity': forecastData['humidity'] ?? 'N/A',
        'iconUrl': forecastData['icon_url'] ?? 'https://openweathermap.org/img/wn/10d@2x.png',
        'iconText': forecastData['condition'] ?? 'Unknown',
        'date': forecastData['date'] ?? 'Today',
        'forecastData': forecastData,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/sendDailyForecast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        if (kDebugMode) {
          print('Failed to send daily forecast. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending daily forecast: $e');
        return true;
      }
      return false;
    }
  }
} 