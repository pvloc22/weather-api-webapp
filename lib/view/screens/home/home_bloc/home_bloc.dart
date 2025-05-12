import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/core/local_storage/search_history_service.dart';
import 'package:golden_owl/data/constaints/constaints.dart';
import 'package:golden_owl/data/model/weather_model.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_bloc.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_event.dart';

import '../../../../core/local_storage/service_weather_preference.dart';
import '../../../../core/service/location_service/location_service_factory.dart';
import '../../../../data/model/search_city_result.dart';
import '../../../../data/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final homeRepository = HomeRepository();
  final searchHistoryService = SearchHistoryService();

  HomeBloc() : super(HomeInitialState()) {
    on<SearchCityEvent>(_searchCity);
    on<LoadMoreForecastEvent>(_loadMoreForecast);
    on<RequireCurrentLocationEvent>(_loadCurrentWeather);
    on<SaveCurrentWeatherEvent>(_saveCurrentWeather);
  }

  void _searchCity(SearchCityEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    try {
      //  Get accurate city information from API (e.g., "hano" -> "Hanoi")
      final SearchCityResult result = await homeRepository.getSearchCityName(event.cityName);
      final String standardizedCityName = result.name; // exact name from API, e.g., "Hanoi"

      // Add search query to history with partial info
      await searchHistoryService.addSearchQuery(
        query: event.cityName,
        cityName: standardizedCityName,
      );

      //  Check if there's a cache for this city
      final WeatherResponse? weatherResponseCached = await serviceWeatherPreferences.getCachedWeatherResponse(standardizedCityName);
      final bool isCached = weatherResponseCached != null;

      if (isCached) {
        // Ensure CurrentWeather has the standardized city name
        final CurrentWeather updatedCurrentWeather = CurrentWeather(
          cityName: standardizedCityName,
          temperature: weatherResponseCached.currentWeather.temperature,
          windSpeed: weatherResponseCached.currentWeather.windSpeed,
          humidity: weatherResponseCached.currentWeather.humidity,
          iconUrl: weatherResponseCached.currentWeather.iconUrl,
          iconText: weatherResponseCached.currentWeather.iconText,
          date: weatherResponseCached.currentWeather.date,
        );

        // Update search history with weather info
        await searchHistoryService.updateSearchQueryWeatherInfo(
          query: event.cityName,
          cityName: standardizedCityName,
          weatherIcon: updatedCurrentWeather.iconUrl,
          weatherDescription: updatedCurrentWeather.iconText,
        );

        emit(
          HomeLoadedState(
            currentWeather: updatedCurrentWeather,
            listForecastWeather: weatherResponseCached.forecastWeather,
          ),
        );
      } else {
        //  If no cache, fetch from API and save with standardized city name
        final weatherResponseFetch = await homeRepository.getCurrentAndForecastsWeather(standardizedCityName);

        // Ensure CurrentWeather has the standardized city name
        final CurrentWeather updatedCurrentWeather = CurrentWeather(
          cityName: standardizedCityName,
          temperature: weatherResponseFetch.currentWeather.temperature,
          windSpeed: weatherResponseFetch.currentWeather.windSpeed,
          humidity: weatherResponseFetch.currentWeather.humidity,
          iconUrl: weatherResponseFetch.currentWeather.iconUrl,
          iconText: weatherResponseFetch.currentWeather.iconText,
          date: weatherResponseFetch.currentWeather.date,
        );

        // Update search history with weather info
        await searchHistoryService.updateSearchQueryWeatherInfo(
          query: event.cityName,
          cityName: standardizedCityName,
          weatherIcon: updatedCurrentWeather.iconUrl,
          weatherDescription: updatedCurrentWeather.iconText,
        );

        final updatedWeatherResponse = WeatherResponse(
          currentWeather: updatedCurrentWeather,
          forecastWeather: weatherResponseFetch.forecastWeather,
        );

        emit(
          HomeLoadedState(
            currentWeather: updatedCurrentWeather,
            listForecastWeather: weatherResponseFetch.forecastWeather,
          ),
        );
        await serviceWeatherPreferences.saveSearchedWeather(standardizedCityName, updatedWeatherResponse);
      }
    } catch (e) {
      String errorMessage = e.toString();
      String errorType = GENERAL_ERROR_TYPE;

      // Handle different types of errors with specific messages
      if (errorMessage.contains('Network error')) {
        // Network connectivity issues
        errorType = NETWORK_ERROR_TYPE;
        emit(HomeErrorState(
            errorMessage: 'Network connection error. Please check your internet connection and try again.',
            errorType: errorType
        ));
      } else if (errorMessage.contains('City not found')) {
        // City not found error
        errorType = CITY_NOT_FOUND_ERROR_TYPE;
        emit(HomeErrorState(
            errorMessage: 'City not found. Please try a different location.',
            errorType: errorType
        ));
      } else if (errorMessage.contains('Server error')) {
        // Server error
        emit(HomeErrorState(
            errorMessage: 'Server error occurred. Please try again later.',
            errorType: GENERAL_ERROR_TYPE
        ));
      } else if (errorMessage.contains('Data format error')) {
        // Data parsing error
        emit(HomeErrorState(
            errorMessage: 'Unable to process weather data. Please try again later.',
            errorType: GENERAL_ERROR_TYPE
        ));
      } else {
        // Generic error
        emit(HomeErrorState(
            errorMessage: 'Failed to search weather data: $errorMessage',
            errorType: GENERAL_ERROR_TYPE
        ));
      }
    }
  }


  void _loadMoreForecast(LoadMoreForecastEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingMoreState());
    try {
      // Ensure using the correct standardized city name from CurrentWeather
      final standardizedCityName = event.currentWeather.cityName ?? event.cityName;
      
      final forecasts = await homeRepository.getMoreForecastsWeather(standardizedCityName, event.days);
      
      final weatherResponseLoaded = WeatherResponse(currentWeather: event.currentWeather, forecastWeather: forecasts);
      await serviceWeatherPreferences.saveLoadMoreForecastWeather(standardizedCityName, weatherResponseLoaded);
      
      emit(HomeLoadedMoreState(forecastWeather: forecasts));
    } catch (e) {
      String errorMessage = e.toString();
      String errorType = GENERAL_ERROR_TYPE;

      // Handle different types of errors with specific messages
      if (errorMessage.contains('Network error')) {
        // Network connectivity issues
        errorType = NETWORK_ERROR_TYPE;
        emit(HomeErrorMoreState(
          errorMessage: 'Network connection error. Please check your internet connection and try again.',
          errorType: errorType
        ));
      } else if (errorMessage.contains('City not found')) {
        // City not found error
        errorType = CITY_NOT_FOUND_ERROR_TYPE;
        emit(HomeErrorMoreState(
          errorMessage: 'City not found. Please try a different location.',
          errorType: errorType
        ));
      } else if (errorMessage.contains('Server error')) {
        // Server error
        emit(HomeErrorMoreState(
          errorMessage: 'Server error occurred. Please try again later.',
          errorType: GENERAL_ERROR_TYPE
        ));
      } else if (errorMessage.contains('Data format error')) {
        // Data parsing error
        emit(HomeErrorMoreState(
          errorMessage: 'Unable to process weather data. Please try again later.',
          errorType: GENERAL_ERROR_TYPE
        ));
      } else {
        // Generic error
        emit(HomeErrorMoreState(
          errorMessage: 'Failed to load more forecast data: $errorMessage',
          errorType: GENERAL_ERROR_TYPE
        ));
      }
    }
  }

  void _loadCurrentWeather(RequireCurrentLocationEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    
    try {
      final locationService = LocationServiceFactory.getLocationService();
      final coordinates = await locationService.getCurrentLocation();
      
      if (coordinates != null && coordinates.length == 2) {
        final lat = coordinates[0];
        final lng = coordinates[1];
        
        // You could implement weather fetching by coordinates here
        // For now, we'll just use a city name search for the demo
        try {
          final weatherResponseFetch = await homeRepository.getCurrentAndForecastsUseGPSWeather(lat, lng);

          final CurrentWeather updatedCurrentWeather = CurrentWeather(
            cityName: "Current Location (${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)})",
            temperature: weatherResponseFetch.currentWeather.temperature,
            windSpeed: weatherResponseFetch.currentWeather.windSpeed,
            humidity: weatherResponseFetch.currentWeather.humidity,
            iconUrl: weatherResponseFetch.currentWeather.iconUrl,
            iconText: weatherResponseFetch.currentWeather.iconText,
            date: weatherResponseFetch.currentWeather.date,
          );
          
          final updatedWeatherResponse = WeatherResponse(
            currentWeather: updatedCurrentWeather,
            forecastWeather: weatherResponseFetch.forecastWeather,
          );
          emit(HomeLoadedState(currentWeather: updatedCurrentWeather, listForecastWeather: weatherResponseFetch.forecastWeather));
        } catch (e) {
          emit(HomeErrorState(errorType: GENERAL_ERROR_TYPE,errorMessage: 'Failed to fetch weather for your location: ${e.toString()}'));
        }
      } else {
        emit(HomeRequireCurrentLocationErrorState());
      }
    } catch (e) {
      String errorMessage;
      
      // Provide more user-friendly error messages
      if (e.toString().contains('PERMISSION_DENIED') || 
          e.toString().contains('permission denied') ||
          e.toString().contains('denied')) {
        errorMessage = 'Location permission denied. Please allow the app to access your location in settings.';
      } else if (e.toString().contains('POSITION_UNAVAILABLE') || 
                e.toString().contains('unavailable')) {
        errorMessage = 'Location information is unavailable. Please try again later.';
      } else if (e.toString().contains('TIMEOUT') || 
                e.toString().contains('timed out')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('disabled') || 
                e.toString().contains('turned off') ||
                e.toString().contains('services are not enabled')) {
        errorMessage = 'Location services are disabled. Please enable location services in settings.';
      } else {
        errorMessage = 'Failed to get your current location: ${e.toString()}';
      }
      
      emit(HomeErrorState(errorType: GENERAL_ERROR_TYPE,errorMessage: errorMessage));
    }
  }

  void _saveCurrentWeather(SaveCurrentWeatherEvent event, Emitter<HomeState> emit) async {
    try {
      final cityName = event.currentWeather.cityName;
      if (cityName != null && cityName.isNotEmpty) {
        final weatherResponse = WeatherResponse(
          currentWeather: event.currentWeather,
          forecastWeather: event.forecastWeather,
        );
        
        await serviceWeatherPreferences.saveSearchedWeather(cityName, weatherResponse);
        
        // Could emit a success state here if needed
      }
    } catch (e) {
      // Handle error if needed
    }
  }
}
