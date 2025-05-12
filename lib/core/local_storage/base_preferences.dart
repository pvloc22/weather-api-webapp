import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/model/weather_model.dart';
Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

class BasePreferences {
  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  Future<bool> setWeatherResponseApplicationSavedInformation({
    required String storageKey,
    required String name,
    required WeatherResponse weatherResponse,
  }) async {
    final prefs = await _prefs;
    final key = '$storageKey$name';

    final now = DateTime.now();
    final value = jsonEncode({
      'timestamp': now.toIso8601String(),
      'currentWeather': {
        'cityName': weatherResponse.currentWeather.cityName,
        'temperature': weatherResponse.currentWeather.temperature,
        'windSpeed': weatherResponse.currentWeather.windSpeed,
        'humidity': weatherResponse.currentWeather.humidity,
        'iconUrl': weatherResponse.currentWeather.iconUrl,
        'iconText': weatherResponse.currentWeather.iconText,
        'date': weatherResponse.currentWeather.date,
      },
      'forecastWeather': weatherResponse.forecastWeather.map((f) => {
        'temperature': f.temperature,
        'windSpeed': f.windSpeed,
        'humidity': f.humidity,
        'iconUrl': f.iconUrl,
        'iconText': f.iconText,
        'date': f.date,
      }).toList(),
    });
    return prefs.setString(key, value);
  }

  Future<WeatherResponse?> getWeatherResponseApplicationSavedInformation({
    required String storageKey,
    required String searchName,
  }) async {
    final prefs = await _prefs;
    final fullKey = '$storageKey$searchName';

    if (!prefs.containsKey(fullKey)) {
      return null;
    }

    final jsonString = prefs.getString(fullKey);
    if (jsonString == null) {
      return null;
    }

    final Map<String, dynamic> map = jsonDecode(jsonString);

    final timestamp = DateTime.tryParse(map['timestamp'] ?? '');
    if (timestamp == null || !isSameDate(timestamp, DateTime.now())) {
      await prefs.remove(fullKey);
      return null;
    }

    final currentWeather = CurrentWeather(
      cityName: map['currentWeather']['cityName'],
      temperature: map['currentWeather']['temperature'],
      windSpeed: map['currentWeather']['windSpeed'],
      humidity: map['currentWeather']['humidity'],
      iconUrl: map['currentWeather']['iconUrl'],
      iconText: map['currentWeather']['iconText'],
      date: map['currentWeather']['date'],
    );

    final forecastWeather = (map['forecastWeather'] as List).map((f) {
      return ForecastWeather(
        temperature: f['temperature'],
        windSpeed: f['windSpeed'],
        humidity: f['humidity'],
        iconUrl: f['iconUrl'],
        iconText: f['iconText'],
        date: f['date'],
      );
    }).toList();

    return WeatherResponse(currentWeather: currentWeather, forecastWeather: forecastWeather);
  }

  Future<bool> appendForecastToCache({
    required String storageKey,
    required String cityName,
    required List<ForecastWeather> newForecasts,
  }) async {
    final prefs = await _prefs;
    final fullKey = '$storageKey$cityName';

    if (!prefs.containsKey(fullKey)) {
      return false;
    }

    final jsonString = prefs.getString(fullKey);
    if (jsonString == null) {
      return false;
    }

    final Map<String, dynamic> map = jsonDecode(jsonString);

    final List<dynamic> cachedForecasts = map['forecastWeather'] as List;
    final existingForecasts = cachedForecasts.map((f) {
      return ForecastWeather(
        temperature: f['temperature'],
        windSpeed: f['windSpeed'],
        humidity: f['humidity'],
        iconUrl: f['iconUrl'],
        iconText: f['iconText'],
        date: f['date'],
      );
    }).toList();

    final List<Map<String, dynamic>> updatedForecastsJson = newForecasts.map((f) => {
      'temperature': f.temperature,
      'windSpeed': f.windSpeed,
      'humidity': f.humidity,
      'iconUrl': f.iconUrl,
      'iconText': f.iconText,
      'date': f.date,
    }).toList();

    final updatedJson = jsonEncode({
      'timestamp': map['timestamp'],
      'currentWeather': map['currentWeather'],
      'forecastWeather': updatedForecastsJson,
    });

    return prefs.setString(fullKey, updatedJson);
  }

  Future<List<WeatherResponse>> getAllSavedWeatherFromCache({
    required String storageKey,
  }) async {
    final prefs = await _prefs;
    final List<WeatherResponse> results = [];
    
    final allKeys = prefs.getKeys();
    final weatherKeys = allKeys.where((k) => k.startsWith(storageKey)).toList();
    
    for (final key in weatherKeys) {
      final jsonString = prefs.getString(key);
      if (jsonString == null) continue;
      
      try {
        final Map<String, dynamic> map = jsonDecode(jsonString);
        final timestamp = DateTime.tryParse(map['timestamp'] ?? '');
        
        if (timestamp == null || !isSameDate(timestamp, DateTime.now())) {
          await prefs.remove(key);
          continue;
        }
        
        final currentWeather = CurrentWeather(
          cityName: map['currentWeather']['cityName'],
          temperature: map['currentWeather']['temperature'],
          windSpeed: map['currentWeather']['windSpeed'],
          humidity: map['currentWeather']['humidity'],
          iconUrl: map['currentWeather']['iconUrl'],
          iconText: map['currentWeather']['iconText'],
          date: map['currentWeather']['date'],
        );
        
        final forecastWeather = (map['forecastWeather'] as List).map((f) {
          return ForecastWeather(
            temperature: f['temperature'],
            windSpeed: f['windSpeed'],
            humidity: f['humidity'],
            iconUrl: f['iconUrl'],
            iconText: f['iconText'],
            date: f['date'],
          );
        }).toList();
        
        
        results.add(WeatherResponse(
          currentWeather: currentWeather,
          forecastWeather: forecastWeather,
          timestamp: timestamp.toIso8601String(),
        ));
      } catch (e) {
        // Skip entries that can't be parsed
        continue;
      }
    }
    
    // Sort by timestamp, newest first
    results.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
    
    return results;
  }

}
