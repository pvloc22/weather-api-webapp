import 'package:golden_owl/data/model/weather_model.dart';

import 'base_preferences.dart';

const String _storageKey = 'WthService_';

ServiceWeatherPreferences serviceWeatherPreferences = ServiceWeatherPreferences();
class ServiceWeatherPreferences extends BasePreferences {
  String _normalizeCacheKey(String cityName) {
    final normalized = cityName.trim().toLowerCase();
    return normalized;
  }

  Future<bool> saveSearchedWeather(String cityName, WeatherResponse weatherResponse) async {
    final normalizedCityName = _normalizeCacheKey(cityName);
    return await setWeatherResponseApplicationSavedInformation(
      storageKey: _storageKey,
      name: normalizedCityName,
      weatherResponse: weatherResponse,
    );
  }

  Future<WeatherResponse?> getCachedWeatherResponse(String cityName) async {
    final normalizedCityName = _normalizeCacheKey(cityName);
    return await getWeatherResponseApplicationSavedInformation(
      storageKey: _storageKey,
      searchName: normalizedCityName,
    );
  }

  Future<bool> saveLoadMoreForecastWeather(String cityName, WeatherResponse weatherResponse) async {
    final normalizedCityName = _normalizeCacheKey(cityName);

    final success = await appendForecastToCache(
      storageKey: _storageKey,
      cityName: normalizedCityName,
      newForecasts: weatherResponse.forecastWeather,
    );

    return success;
  }

  Future<List<WeatherResponse>> getAllSavedWeathers() async {
    return await getAllSavedWeatherFromCache(
      storageKey: _storageKey,
    );
  }

}
