import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:golden_owl/core/service/weather_email_service.dart';

class SmtpService {
  static final SmtpService _instance = SmtpService._internal();

  factory SmtpService() {
    return _instance;
  }

  SmtpService._internal();

  // Weather Email Service for web
  final _weatherEmailService = WeatherEmailService();

  // Gmail SMTP configuration
  final String _username = 'phamloc842002@gmail.com';
  final String _password = 'inzd veri zcxm pvbc'; // App password
  final String _appName = 'weather_send_mail';

  // Lazy loading of SMTP server to avoid unnecessary initialization
  SmtpServer? _cachedSmtpServer;

  // Get SMTP server instance with specific Gmail configuration
  SmtpServer get _smtpServer {
    if (_cachedSmtpServer == null) {
      _cachedSmtpServer = gmail(_username, _password);
    }
    return _cachedSmtpServer!;
  }

  // Send verification email with OTP
  Future<bool> sendVerificationEmail({required String recipientEmail, required String otp}) async {
    // Use Weather Email Service for web
    if (kIsWeb) {
      return await _weatherEmailService.sendVerificationEmail(recipientEmail: recipientEmail, otp: otp);
    }

    // Use SMTP directly for mobile
    try {
      final message =
          Message()
            ..from = Address(_username, 'Weather Forecast Service')
            ..recipients.add(recipientEmail)
            ..subject = 'Email Verification Code'
            ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
            <h2 style="color: #5372F0; text-align: center;">Weather Forecast Service</h2>
            <p style="font-size: 16px;">Hello,</p>
            <p style="font-size: 16px;">Thank you for subscribing to our Weather Forecast Service. Please use the following verification code to complete your subscription:</p>
            <div style="text-align: center; margin: 30px 0;">
              <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; font-size: 24px; letter-spacing: 5px; font-weight: bold;">$otp</div>
            </div>
            <p style="font-size: 16px;">This code will expire in 10 minutes.</p>
            <p style="font-size: 16px;">If you didn't request this code, please ignore this email.</p>
            <p style="font-size: 14px; color: #666; margin-top: 30px; text-align: center;">Weather Forecast Service - Stay updated with the latest weather information.</p>
          </div>
        ''';

      final sendReport = await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Send subscription confirmation email
  Future<bool> sendSubscriptionConfirmation({
    required String recipientEmail,
    required String location,
    String? cityDisplay,
    Map<String, dynamic>? weatherData,
  }) async {
    // Use Weather Email Service for web
    if (kIsWeb) {
      return await _weatherEmailService.sendSubscriptionConfirmation(
        recipientEmail: recipientEmail,
        location: location,
        cityDisplay: cityDisplay,
        weatherData: weatherData,
      );
    }
    
    // Use SMTP directly for mobile
    try {
      // Extract weather data if available
      final String displayLocation = cityDisplay ?? location;
      final cityName = weatherData?['city_name'] ?? displayLocation;
      final temperature = weatherData?['temperature'] ?? 'N/A';
      final condition = weatherData?['condition'] ?? 'Unknown';
      final windSpeed = weatherData?['wind_speed'] ?? 'N/A';
      final humidity = weatherData?['humidity'] ?? 'N/A';
      final iconUrl = weatherData?['icon_url'] ?? 'https://openweathermap.org/img/wn/10d@2x.png';
      final date = weatherData?['date'] ?? 'Today';
      
      final message = Message()
        ..from = Address(_username, 'Weather Forecast Service')
        ..recipients.add(recipientEmail)
        ..subject = 'Weather Forecast Subscription Confirmed'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
            <h2 style="color: #5372F0; text-align: center;">Weather Forecast Service</h2>
            <p style="font-size: 16px;">Hello,</p>
            <p style="font-size: 16px;">Thank you for subscribing to our Weather Forecast Service!</p>
            <p style="font-size: 16px;">You will now receive daily weather forecasts for <strong>$cityName</strong>.</p>
            
            ${weatherData != null ? '''
            <div style="background-color: #5372F0; color: white; border-radius: 10px; padding: 15px; margin: 20px 0;">
              <h3 style="text-align: center; margin: 0 0 10px 0;">Current Weather Information</h3>
              <table style="width: 100%; border-collapse: collapse; color: white;">
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>City Name:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$cityName</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Date:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$date</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Temperature:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">${temperature}°C</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Condition:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$condition</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Wind Speed:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$windSpeed km/h</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Humidity:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$humidity%</td>
                </tr>
                <tr>
                  <td style="padding: 8px;"><strong>Weather Icon:</strong></td>
                  <td style="padding: 8px;"><img src="$iconUrl" alt="$condition" style="width: 50px; height: 50px; background-color: white; border-radius: 50%; padding: 5px;"></td>
                </tr>
              </table>
            </div>
            ''' : '''
            <div style="text-align: center; margin: 30px 0;">
              <img src="https://openweathermap.org/img/wn/10d@2x.png" alt="Weather Icon" style="width: 100px; height: 100px;">
            </div>
            '''}
            
            <p style="font-size: 16px;">To unsubscribe at any time, please visit our app and use the unsubscribe option.</p>
            <p style="font-size: 14px; color: #666; margin-top: 30px; text-align: center;">Weather Forecast Service - Stay updated with the latest weather information.</p>
          </div>
        ''';

      final sendReport = await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Send daily weather forecast email with enhanced weather information
  Future<bool> sendDailyForecast({
    required String recipientEmail,
    required String location,
    String? cityDisplay,
    required Map<String, dynamic> forecastData,
  }) async {
    // Use Weather Email Service for web
    if (kIsWeb) {
      return await _weatherEmailService.sendDailyForecast(
        recipientEmail: recipientEmail,
        location: location,
        cityDisplay: cityDisplay,
        forecastData: forecastData,
      );
    }

    try {
      final String displayLocation = cityDisplay ?? location;
      final currentTemperature = forecastData['temperature'] ?? 'N/A';
      final currentCondition = forecastData['condition'] ?? 'Unknown';
      final currentHumidity = forecastData['humidity'] ?? 'N/A';
      final currentWindSpeed = forecastData['wind_speed'] ?? 'N/A';
      final currentIconUrl = forecastData['icon_url'] ?? 'https://openweathermap.org/img/wn/10d@2x.png';
      final cityName = forecastData['city_name'] ?? displayLocation;
      final date = forecastData['date'] ?? 'Today';

      // Additional forecast data
      final List<Map<String, dynamic>> weekForecast =
          forecastData['forecast_days'] as List<Map<String, dynamic>>? ?? [];

      // Enhanced weather information
      final feelsLike = forecastData['feels_like'] ?? 'N/A';
      final pressure = forecastData['pressure'] ?? 'N/A';
      final uvIndex = forecastData['uv_index'] ?? 'N/A';
      final visibility = forecastData['visibility'] ?? 'N/A';
      final sunrise = forecastData['sunrise'] ?? 'N/A';
      final sunset = forecastData['sunset'] ?? 'N/A';
      final description = forecastData['description'] ?? '';
      final lastUpdated = forecastData['last_updated'] ?? '';
      final locationDetails = forecastData['location_details'] ?? '';

      // Build forecast days HTML if available
      String forecastDaysHtml = '';
      if (weekForecast.isNotEmpty) {
        forecastDaysHtml = '''
          <div style="margin-top: 30px;">
            <h3 style="color: #5372F0; text-align: center;">5-Day Forecast</h3>
            <div style="display: flex; overflow-x: auto; padding: 10px 0;">
        ''';

        for (var forecast in weekForecast) {
          final dayTemp = forecast['temperature'] ?? 'N/A';
          final dayCondition = forecast['icon_text'] ?? 'Unknown';
          final dayIcon = forecast['icon_url'] ?? 'https://openweathermap.org/img/wn/10d@2x.png';
          final dayDate = forecast['date'] ?? '';
          final dayDesc = forecast['description'] ?? '';

          forecastDaysHtml += '''
            <div style="flex: 0 0 auto; width: 120px; text-align: center; margin: 0 10px; background-color: #f8f9fa; border-radius: 8px; padding: 15px;">
              <p style="font-weight: bold; margin: 5px 0;">$dayDate</p>
              <img src="$dayIcon" alt="$dayCondition" style="width: 50px; height: 50px;">
              <p style="font-size: 18px; margin: 5px 0;">$dayTemp°C</p>
              <p style="font-size: 12px; color: #666;">$dayDesc</p>
            </div>
          ''';
        }

        forecastDaysHtml += '''
            </div>
          </div>
        ''';
      }

      final message =
          Message()
            ..from = Address(_username, 'Weather Forecast Service')
            ..recipients.add(recipientEmail)
            ..subject = 'Weather Forecast for $cityName - $date'
            ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px; background-color: #ffffff;">
            <h2 style="color: #5372F0; text-align: center; border-bottom: 2px solid #f0f0f0; padding-bottom: 15px;">Weather Forecast Service</h2>
            
            <!-- Required Weather Information Section -->
            <div style="background-color: #5372F0; color: white; border-radius: 10px; padding: 15px; margin-bottom: 20px;">
              <h3 style="text-align: center; margin: 0 0 10px 0;">Essential Weather Information</h3>
              <table style="width: 100%; border-collapse: collapse; color: white;">
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>City Name:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$cityName</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Date:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$date</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Temperature:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$currentTemperature°C</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Condition:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$currentCondition</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Wind Speed:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$currentWindSpeed km/h</td>
                </tr>
                <tr>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);"><strong>Humidity:</strong></td>
                  <td style="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.2);">$currentHumidity%</td>
                </tr>
                <tr>
                  <td style="padding: 8px;"><strong>Weather Icon:</strong></td>
                  <td style="padding: 8px;"><img src="$currentIconUrl" alt="$currentCondition" style="width: 50px; height: 50px; background-color: white; border-radius: 50%; padding: 5px;"></td>
                </tr>
              </table>
            </div>
            
            <div style="text-align: center; margin: 20px 0 10px 0;">
              <h3 style="font-size: 22px; margin: 0;">$cityName</h3>
              <p style="color: #666; margin: 5px 0;">$date</p>
              <p style="color: #888; font-size: 12px; margin: 2px 0;">$locationDetails</p>
            </div>
            
            <div style="background-color: #f0f7ff; border-radius: 10px; padding: 20px; text-align: center; box-shadow: 0 2px 10px rgba(0,0,0,0.05);">
              <div style="display: flex; justify-content: center; align-items: center;">
                <img src="$currentIconUrl" alt="$currentCondition" style="width: 80px; height: 80px;">
                <div style="text-align: left; margin-left: 15px;">
                  <h2 style="margin: 0; font-size: 36px;">$currentTemperature°C</h2>
                  <p style="margin: 5px 0; font-size: 18px;">$currentCondition</p>
                  <p style="margin: 5px 0; font-size: 14px; color: #666;">Feels like: $feelsLike°C</p>
                </div>
              </div>
              <p style="margin: 15px 0 5px 0; font-size: 15px; color: #444; text-align: center;">$description</p>
            </div>
            
            <div style="display: flex; justify-content: space-between; margin: 20px 0; flex-wrap: wrap;">
              <div style="flex: 1; min-width: 120px; background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin: 5px; text-align: center;">
                <p style="font-size: 14px; color: #666; margin: 0;">Humidity</p>
                <p style="font-size: 18px; font-weight: bold; margin: 5px 0;">$currentHumidity%</p>
              </div>
              <div style="flex: 1; min-width: 120px; background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin: 5px; text-align: center;">
                <p style="font-size: 14px; color: #666; margin: 0;">Wind Speed</p>
                <p style="font-size: 18px; font-weight: bold; margin: 5px 0;">$currentWindSpeed km/h</p>
              </div>
              <div style="flex: 1; min-width: 120px; background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin: 5px; text-align: center;">
                <p style="font-size: 14px; color: #666; margin: 0;">Pressure</p>
                <p style="font-size: 18px; font-weight: bold; margin: 5px 0;">$pressure</p>
              </div>
              <div style="flex: 1; min-width: 120px; background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin: 5px; text-align: center;">
                <p style="font-size: 14px; color: #666; margin: 0;">UV Index</p>
                <p style="font-size: 18px; font-weight: bold; margin: 5px 0;">$uvIndex</p>
              </div>
            </div>
            
            <div style="display: flex; justify-content: space-between; margin: 20px 0;">
              <div style="flex: 1; text-align: center; background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin-right: 10px;">
                <div style="display: flex; align-items: center; justify-content: center;">
                  <img src="https://openweathermap.org/img/wn/01d@2x.png" alt="Sunrise" style="width: 40px; height: 40px;">
                  <div>
                    <p style="font-size: 14px; color: #666; margin: 0;">Sunrise</p>
                    <p style="font-size: 16px; font-weight: bold; margin: 5px 0;">$sunrise</p>
                  </div>
                </div>
              </div>
              <div style="flex: 1; text-align: center; background-color: #f8f9fa; border-radius: 8px; padding: 15px; margin-left: 10px;">
                <div style="display: flex; align-items: center; justify-content: center;">
                  <img src="https://openweathermap.org/img/wn/01n@2x.png" alt="Sunset" style="width: 40px; height: 40px;">
                  <div>
                    <p style="font-size: 14px; color: #666; margin: 0;">Sunset</p>
                    <p style="font-size: 16px; font-weight: bold; margin: 5px 0;">$sunset</p>
                  </div>
                </div>
              </div>
            </div>
            
            <div style="margin: 25px 0; background-color: #f8f9fa; border-radius: 8px; padding: 15px;">
              <div style="display: flex; align-items: center;">
                <span style="background-color: #5372F0; color: white; font-size: 12px; padding: 5px 10px; border-radius: 4px; margin-right: 10px;">TODAY'S HIGHLIGHT</span>
                <span style="color: #666; font-size: 14px;">Visibility: $visibility</span>
              </div>
              <p style="margin: 10px 0 0 0; color: #444; font-size: 14px;">
                ${currentCondition.toLowerCase().contains('rain') ? 'Bring an umbrella! Precipitation is expected throughout the day.' : (currentCondition.toLowerCase().contains('sun') ? 'Great day for outdoor activities! Don\'t forget sun protection.' : 'Check for weather updates as conditions may change.')}
              </p>
            </div>
            
            $forecastDaysHtml
            
            <div style="margin-top: 30px; background-color: #f0f7ff; border-radius: 10px; padding: 15px; text-align: center;">
              <p style="font-size: 16px;">Stay prepared for the day ahead with this weather update!</p>
              <p style="font-size: 14px; color: #666;">$lastUpdated</p>
            </div>
            
            <p style="font-size: 14px; color: #666; margin-top: 30px; text-align: center; border-top: 1px solid #e0e0e0; padding-top: 20px;">
              Weather Forecast Service - Stay updated with the latest weather information.
            </p>
            <p style="font-size: 12px; color: #999; text-align: center;">
              To unsubscribe, please visit our app and use the unsubscribe option.
            </p>
          </div>
        ''';

      final sendReport = await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Send unsubscribe confirmation email
  Future<bool> sendUnsubscribeConfirmation({required String recipientEmail}) async {
    // Use Weather Email Service for web
    if (kIsWeb) {
      return await _weatherEmailService.sendUnsubscribeConfirmation(recipientEmail: recipientEmail);
    }

    // Use SMTP directly for mobile
    try {
      final message =
          Message()
            ..from = Address(_username, 'Weather Forecast Service')
            ..recipients.add(recipientEmail)
            ..subject = 'Unsubscribed from Weather Forecast Service'
            ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
            <h2 style="color: #5372F0; text-align: center;">Weather Forecast Service</h2>
            <p style="font-size: 16px;">Hello,</p>
            <p style="font-size: 16px;">You have successfully unsubscribed from our Weather Forecast Service.</p>
            <p style="font-size: 16px;">We're sorry to see you go. If you have any feedback that could help us improve our service, please let us know.</p>
            <p style="font-size: 16px;">If you wish to resubscribe in the future, you can do so through our app at any time.</p>
            <p style="font-size: 14px; color: #666; margin-top: 30px; text-align: center;">Thank you for using our Weather Forecast Service.</p>
          </div>
        ''';

      final sendReport = await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Bulk send method to improve performance when sending to multiple recipients
  Future<Map<String, bool>> bulkSendForecast({
    required List<Map<String, dynamic>> recipients, // List of {email, location, cityDisplay}
    required Map<String, dynamic> globalForecastData,
  }) async {
    final results = <String, bool>{};

    // Group recipients by location to minimize forecast API calls
    final locationGroups = <String, List<Map<String, String>>>{};

    for (var recipient in recipients) {
      final email = recipient['email'] as String;
      final location = recipient['location'] as String;
      final cityDisplay = recipient['cityDisplay'] as String?;

      if (!locationGroups.containsKey(location)) {
        locationGroups[location] = [];
      }
      locationGroups[location]!.add({
        'email': email,
        'cityDisplay': cityDisplay ?? location,
      });
    }

    // Send emails by location group
    for (var entry in locationGroups.entries) {
      final location = entry.key;
      final recipientsList = entry.value;

      // Get forecast data for this location (or use global if already available)
      final Map<String, dynamic> locationForecastData = globalForecastData;

      // Update location in forecast data
      locationForecastData['city_name'] = location;

      // Send to each recipient
      for (var recipient in recipientsList) {
        final email = recipient['email']!;
        final cityDisplay = recipient['cityDisplay'];
        
        try {
          final success = await sendDailyForecast(
            recipientEmail: email,
            location: location,
            cityDisplay: cityDisplay,
            forecastData: locationForecastData,
          );
          results[email] = success;

          // Small delay to avoid SMTP rate limits
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          results[email] = false;
        }
      }
    }

    return results;
  }
}
