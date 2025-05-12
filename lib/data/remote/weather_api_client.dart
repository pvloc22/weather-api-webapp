import 'dart:convert';

import 'package:golden_owl/data/model/weather_model.dart';
import 'package:golden_owl/data/url_api/weather_api.dart';
import 'package:http/http.dart' as http;

import '../model/search_city_result.dart';

class WeatherApiClient {
  String _apiKey = '40658e5907ef4e198b845530251005';

  Future<WeatherResponse> fetchWeatherWithCityName(String cityName) async {
    final url = Uri.parse('${API_WEATHER_URL.GET_FORECASTS_WEATHER}?q=$cityName&days=4&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final current = CurrentWeather.fromMap(data);
        final List<ForecastWeather> forecasts =
            (data['forecast']['forecastday'] as List).map((item) => ForecastWeather.fromMap(item)).toList();
        return WeatherResponse(currentWeather: current, forecastWeather: forecasts);
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Handle city not found error specifically
        throw Exception('City not found: $cityName');
      } else {
        // Handle other server errors with more specific message
        throw Exception('Server error: HTTP ${response.statusCode} - Failed to fetch weather data');
      }
    } on http.ClientException {
      // Handle network connectivity issues
      throw Exception('Network error: Unable to connect to weather service. Please check your internet connection.');
    } on FormatException {
      // Handle json parsing errors
      throw Exception('Data format error: Unable to process weather data');
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('Error: $e');
    }
  }

  Future<CurrentWeather> fetchCurrentWeatherWithCityName(String cityName) async {
    final url = Uri.parse('${API_WEATHER_URL.GET_CURRENT_WEATHER}?q=$cityName&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final current = CurrentWeather.fromMap(data);
        return current;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Handle city not found error specifically
        throw Exception('City not found: $cityName');
      } else {
        // Handle other server errors with more specific message
        throw Exception('Server error: HTTP ${response.statusCode} - Failed to fetch weather data');
      }
    } on http.ClientException {
      // Handle network connectivity issues
      throw Exception('Network error: Unable to connect to weather service. Please check your internet connection.');
    } on FormatException {
      // Handle json parsing errors
      throw Exception('Data format error: Unable to process weather data');
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('Error: $e');
    }
  }

  Future<CurrentWeather> fetchCurrentWeatherWithLatitudeAndLongitude(double lat, double long) async {
    final url = Uri.parse('${API_WEATHER_URL.GET_CURRENT_WEATHER}?q=$lat,$long&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final current = CurrentWeather.fromMap(data);
        return current;
      } else if (response.statusCode == 400) {
        // Handle location not found error specifically
        throw Exception('Location not found for coordinates: $lat, $long');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Handle network connectivity issues
      throw Exception('Network error: Unable to connect to weather service. Please check your internet connection.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<WeatherResponse> fetchWeatherWithLatitudeAndLongitude(double lat, double long) async {
    final url = Uri.parse('${API_WEATHER_URL.GET_FORECASTS_WEATHER}?q=$lat,$long&days=4&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final current = CurrentWeather.fromMap(data);
        final List<ForecastWeather> forecasts =
        (data['forecast']['forecastday'] as List).map((item) => ForecastWeather.fromMap(item)).toList();
        return WeatherResponse(currentWeather: current, forecastWeather: forecasts);
      } else if (response.statusCode == 400) {
        // Handle location not found error specifically
        throw Exception('Location not found for coordinates: $lat, $long');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Handle network connectivity issues
      throw Exception('Network error: Unable to connect to weather service. Please check your internet connection.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<ForecastWeather>> fetchMoreForecasts(String cityName, int days) async {
    final url = Uri.parse('${API_WEATHER_URL.GET_FORECASTS_WEATHER}?q=$cityName&days=$days&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<ForecastWeather> forecasts = (data['forecast']['forecastday'] as List).map((item) => ForecastWeather.fromMap(item)).toList();
        return forecasts;
      } else if (response.statusCode == 400) {
        // Handle city not found error specifically
        throw Exception('City not found: $cityName');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Handle network connectivity issues
      throw Exception('Network error: Unable to connect to weather service. Please check your internet connection.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<SearchCityResult> searchCityName(String cityName) async {
    final url = Uri.parse('${API_WEATHER_URL.GET_SEARCH_WEATHER}?q=$cityName&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          throw Exception('No city found matching "$cityName".');
        }
        return SearchCityResult.fromMap(data.first);
      } else if (response.statusCode == 400) {
        throw Exception('Invalid city search query: $cityName');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Handle network connectivity issues
      throw Exception('Network error: Unable to connect to weather service. Please check your internet connection.');
    } catch (e) {
      throw Exception('An error occurred while searching for the city: $e');
    }
  }
}
