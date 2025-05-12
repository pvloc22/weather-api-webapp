abstract class Weather {
  final double? temperature;
  final double? windSpeed;
  final int? humidity;
  final String? iconUrl;
  final String? iconText;
  final String? date;

  Weather({required this.temperature, required this.windSpeed, required this.humidity, required this.iconUrl, required this.iconText, required this.date});
}

class CurrentWeather extends Weather{
  final String? cityName;
  CurrentWeather({required this.cityName,required super.temperature, required super.windSpeed, required super.humidity, required super.iconUrl, required super.iconText, required super.date});
  // write a method to convert the object to json with name toMap

  factory CurrentWeather.fromMap(Map<String, dynamic> map) {
    return CurrentWeather(
      cityName: map['location']?['name'] ?? 'Unknown',
      temperature: (map['current']?['temp_c'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (map['current']?['wind_kph'] as num?)?.toDouble() ?? 0.0,
      humidity: map['current']?['humidity'] ?? 0,
      iconUrl: map['current']?['condition']?['icon'] != null
          ? 'https:${map['current']['condition']['icon']}'
          : '',
      iconText: map['current']?['condition']?['text'] ?? 'No description',
      date:  (map['location']?['localtime'] ?? '').split(' ').first,

    );
  }

  @override
  String toString() {
    return 'CurrentWeather(cityName: $cityName, temperature: $temperature, windSpeed: $windSpeed, humidity: $humidity, iconUrl: $iconUrl, iconText: $iconText, date: $date)';
  }
}

class ForecastWeather extends Weather{
  ForecastWeather({required super.temperature, required super.windSpeed, required super.humidity, required super.iconUrl, required super.iconText, required super.date});

  factory ForecastWeather.fromMap(Map<String, dynamic> map) {

    return ForecastWeather(
      temperature: (map['day']?['avgtemp_c'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (map['day']?['maxwind_kph'] as num?)?.toDouble() ?? 0.0,
      humidity: map['day']?['avghumidity'] ?? 0,
      iconUrl: map['day']?['condition']?['icon'] != null
          ? 'https:${map['day']['condition']['icon']}'
          : '',
      iconText: map['day']?['condition']?['text'] ?? 'No description',
      date: map['date'] ?? '',
    );
  }
  @override
  String toString() {
    return 'ForecastWeather(temperature: $temperature, windSpeed: $windSpeed, humidity: $humidity, iconUrl: $iconUrl, iconText: $iconText, date: $date)';
  }
}

class WeatherResponse {
  String ?timestamp;
  final CurrentWeather currentWeather;
  final List<ForecastWeather> forecastWeather;

  WeatherResponse({required this.currentWeather, required this.forecastWeather, this.timestamp});

  WeatherResponse copyWith({
    CurrentWeather? currentWeather,
    List<ForecastWeather>? forecastWeather,
  }) {
    return WeatherResponse(
      currentWeather: currentWeather ?? this.currentWeather,
      forecastWeather: forecastWeather ?? this.forecastWeather,
    );
  }
}
