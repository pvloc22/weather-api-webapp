

import 'package:flutter/material.dart';
import 'package:golden_owl/data/model/search_city_result.dart';
import 'package:golden_owl/data/model/weather_model.dart';
import 'package:golden_owl/data/remote/weather_api_client.dart';

class HomeRepository{
  final weatherApiClient = WeatherApiClient();

  Future<WeatherResponse> getCurrentAndForecastsWeather(String cityName) async {
    try {
      final weatherResponse = await weatherApiClient.fetchWeatherWithCityName(cityName);
      return weatherResponse;
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }
  Future<WeatherResponse> getCurrentAndForecastsUseGPSWeather(double latitude, double longitude) async {
    try {
      final weatherResponse = await weatherApiClient.fetchWeatherWithLatitudeAndLongitude(latitude, longitude);
      return weatherResponse;
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }
  Future<List<ForecastWeather>> getMoreForecastsWeather(String cityName, int days) async {
    try {
      final forecasts = await weatherApiClient.fetchMoreForecasts(cityName, days);
      return forecasts;
    } catch (e) {
      throw Exception('Error fetching more forecast data: $e');
    }
  }
  Future<SearchCityResult> getSearchCityName(String cityName) async {
    try {
      final searchCityResult = await weatherApiClient.searchCityName(cityName);
      return searchCityResult;
    } catch (e) {
      throw Exception('Error fetching search city data: $e');
    }
  }
}