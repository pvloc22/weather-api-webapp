import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/core/local_storage/base_preferences.dart';
import 'package:golden_owl/core/style/colors.dart';
import 'package:golden_owl/data/model/weather_model.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_bloc.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_event.dart';
import 'package:golden_owl/view/screens/weather_saved/weather_saved_bloc/weather_saved_bloc.dart';
import 'package:golden_owl/view/screens/weather_saved/weather_saved_bloc/weather_saved_event.dart';
import 'package:golden_owl/view/screens/weather_saved/weather_saved_bloc/weather_saved_state.dart';
import 'package:intl/intl.dart';

import '../detail_search_screen/detail_weather_history_search_screen.dart';

class WeatherSavedScreen extends StatefulWidget {
  const WeatherSavedScreen({Key? key}) : super(key: key);

  @override
  State<WeatherSavedScreen> createState() => _WeatherSavedScreenState();
}

class _WeatherSavedScreenState extends State<WeatherSavedScreen> {
  late final WeatherSavedBloc _weatherSavedBloc;

  @override
  void initState() {
    super.initState();
    _weatherSavedBloc = WeatherSavedBloc();
    _weatherSavedBloc.add(LoadSavedWeathersEvent());
  }

  @override
  void dispose() {
    _weatherSavedBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _weatherSavedBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Weather', style: TextStyle(color: whiteColor)),
          backgroundColor: blueColor,
          elevation: 0,
          iconTheme: IconThemeData(color: whiteColor),
        ),
        body: BlocBuilder<WeatherSavedBloc, WeatherSavedState>(
          builder: (context, state) {
            if (state is WeatherSavedLoadingState) {
              return Center(child: CircularProgressIndicator(color: blueColor));
            } else if (state is WeatherSavedLoadedState) {
              return _buildSavedWeatherList(state.savedWeathers);
            } else if (state is WeatherSavedErrorState) {
              return Center(child: Text(state.message, style: TextStyle(color: Colors.red)));
            }
            
            return Center(
              child: Text(
                'No saved weather data yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavedWeatherList(List<WeatherResponse> savedWeathers) {
    if (savedWeathers.isEmpty) {
      return Center(
        child: Text(
          'No saved weather data yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Locations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => _weatherSavedBloc.add(ClearAllSavedWeathersEvent()),
                child: Text('Clear All', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: savedWeathers.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = savedWeathers[index];
              final currentWeather = item.currentWeather;
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item.timestamp!));
              
              return Dismissible(
                key: Key(item.currentWeather.cityName ?? ''),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _weatherSavedBloc.add(DeleteSavedWeatherEvent(cityName: item.currentWeather.cityName ?? ''));
                },
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  leading: CircleAvatar(
                    backgroundColor: blueColor.withOpacity(0.2),
                    radius: 28,
                    child: Image.network(
                      currentWeather.iconUrl ?? '',
                      width: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.cloud, color: blueColor);
                      },
                    ),
                  ),
                  title: Text(
                    currentWeather.cityName ?? 'Unknown Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        '${currentWeather.temperature}°C, ${currentWeather.iconText}',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Saved on: $formattedDate',
                        style: TextStyle(fontSize: 12, color: Colors.black38),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    onPressed: () {},
                  ),
                  onTap: () {
                    // Go back to home screen with this weather data
                    final cityName = currentWeather.cityName;
                    if (cityName != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DetailWeatherHistorySearchScreen(cityName: cityName,weatherResponse: savedWeathers[index],)),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 