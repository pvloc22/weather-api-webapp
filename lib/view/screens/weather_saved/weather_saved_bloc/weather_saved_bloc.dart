import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/core/local_storage/service_weather_preference.dart';
import 'package:golden_owl/core/local_storage/base_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_saved_event.dart';
import 'weather_saved_state.dart';

class WeatherSavedBloc extends Bloc<WeatherSavedEvent, WeatherSavedState> {
  WeatherSavedBloc() : super(WeatherSavedInitialState()) {
    on<LoadSavedWeathersEvent>(_onLoadSavedWeathers);
    on<DeleteSavedWeatherEvent>(_onDeleteSavedWeather);
    on<ClearAllSavedWeathersEvent>(_onClearAllSavedWeathers);
  }

  Future<void> _onLoadSavedWeathers(
    LoadSavedWeathersEvent event,
    Emitter<WeatherSavedState> emit,
  ) async {
    emit(WeatherSavedLoadingState());
    
    try {
      final savedWeathers = await serviceWeatherPreferences.getAllSavedWeathers();
      emit(WeatherSavedLoadedState(savedWeathers: savedWeathers));
    } catch (e) {
      emit(WeatherSavedErrorState(message: 'Failed to load saved weather data'));
    }
  }

  Future<void> _onDeleteSavedWeather(
    DeleteSavedWeatherEvent event,
    Emitter<WeatherSavedState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_storageKey}${event.cityName}';
      await prefs.remove(key);
      
      // Reload the list
      add(LoadSavedWeathersEvent());
    } catch (e) {
      emit(WeatherSavedErrorState(message: 'Failed to delete saved weather'));
    }
  }

  Future<void> _onClearAllSavedWeathers(
    ClearAllSavedWeathersEvent event,
    Emitter<WeatherSavedState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final weatherKeys = allKeys.where((k) => k.startsWith(_storageKey)).toList();
      
      for (final key in weatherKeys) {
        await prefs.remove(key);
      }
      
      emit(WeatherSavedLoadedState(savedWeathers: []));
    } catch (e) {
      emit(WeatherSavedErrorState(message: 'Failed to clear saved weather data'));
    }
  }
}

const String _storageKey = 'WthService_'; 