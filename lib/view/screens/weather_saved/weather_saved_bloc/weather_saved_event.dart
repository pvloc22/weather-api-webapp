abstract class WeatherSavedEvent {}

class LoadSavedWeathersEvent extends WeatherSavedEvent {}

class DeleteSavedWeatherEvent extends WeatherSavedEvent {
  final String cityName;
  
  DeleteSavedWeatherEvent({required this.cityName});
}

class ClearAllSavedWeathersEvent extends WeatherSavedEvent {} 