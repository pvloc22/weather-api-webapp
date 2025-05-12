import 'package:golden_owl/data/model/weather_model.dart';

abstract class HomeEvent {
  const HomeEvent();
}

class SearchCityEvent extends HomeEvent {
  final String cityName;

  const SearchCityEvent({required this.cityName});
}
class LoadMoreForecastEvent extends HomeEvent {
  final String cityName;
  final int days;
  final CurrentWeather currentWeather;

  LoadMoreForecastEvent({required this.cityName, required this.days, required this.currentWeather});
}

class RequireCurrentLocationEvent extends HomeEvent {
  final bool isWebsite;

  RequireCurrentLocationEvent({required this.isWebsite});
}

class SaveCurrentWeatherEvent extends HomeEvent {
  final CurrentWeather currentWeather;
  final List<ForecastWeather> forecastWeather;
  
  SaveCurrentWeatherEvent({
    required this.currentWeather,
    required this.forecastWeather,
  });
}
