import 'dart:math';

import 'package:flutter/material.dart';
import 'package:golden_owl/core/style/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:golden_owl/data/model/weather_model.dart';

class DetailWeatherHistorySearchScreen extends StatelessWidget {
  final WeatherResponse weatherResponse;
  final String cityName;

  const DetailWeatherHistorySearchScreen({
    Key? key,
    required this.weatherResponse,
    required this.cityName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Details', style: TextStyle(fontWeight: FontWeight.w600, color: whiteColor)),
        backgroundColor: blueColor,
        iconTheme: IconThemeData(color: whiteColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _rightPanel(),
          ],
        ),
      ),
    );
  }


  Widget _rightPanel() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_weatherSummary(), _weatherForecast()]),
    );
  }

  Widget _weatherSummary() {
    return _buildWeatherSummary(weatherResponse.currentWeather);
  }

  Widget _buildWeatherSummary(CurrentWeather currentWeather) {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 40),
      width: double.infinity,
      decoration: BoxDecoration(color: blueColor, borderRadius: BorderRadius.circular(5)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 400) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentWeather.cityName} (${currentWeather.date})',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: whiteColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Temperature: ${currentWeather.temperature}°C',
                        style: TextStyle(fontSize: 16, color: whiteColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Wind: ${currentWeather.windSpeed} M/s',
                        style: TextStyle(fontSize: 16, color: whiteColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Humidity: ${currentWeather.humidity}%',
                        style: TextStyle(fontSize: 16, color: whiteColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Image.network(
                      '${currentWeather.iconUrl ?? ''}',
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator();
                      },
                    ),
                    Text(
                      currentWeather.iconText ?? 'No description',
                      style: TextStyle(fontWeight: FontWeight.w600, color: whiteColor),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentWeather.cityName} (${currentWeather.date})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: whiteColor),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Image.network(
                    '${currentWeather.iconUrl ?? ''}',
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator();
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    currentWeather.iconText ?? 'No description',
                    style: TextStyle(fontWeight: FontWeight.w600, color: whiteColor),
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temperature: ${currentWeather.temperature}°C',
                      style: TextStyle(fontSize: 16, color: whiteColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Wind: ${currentWeather.windSpeed} m/s',
                      style: TextStyle(fontSize: 16, color: whiteColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Humidity: ${currentWeather.humidity}%',
                      style: TextStyle(fontSize: 16, color: whiteColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _weatherForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderWeatherForecast(weatherResponse.forecastWeather.length), 
        _buildWeatherForecast()
      ],
    );
  }

  Widget _buildWeatherForecast() {
    if (kIsWeb) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: _listWeatherForecastWebsite(weatherResponse.forecastWeather),
      );
    } else {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: _listWeatherForecastMobile(weatherResponse.forecastWeather),
      );
    }
  }

  Widget _buildHeaderWeatherForecast(int days) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Text('$days-Day Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
    );
  }

  Widget _listWeatherForecastMobile(List<ForecastWeather> listForecastsWeather) {
    return SizedBox(
      height: 220, // Reduced height to prevent overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: listForecastsWeather.length,
        itemBuilder: (context, index) {
          return Container(
            width: 140, // Fixed width for mobile items
            child: _itemWeatherForecast(listForecastsWeather[index]),
          );
        },
      ),
    );
  }

  Widget _listWeatherForecastWebsite(List<ForecastWeather> listForecastsWeather) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;

        if (constraints.maxWidth > 1000) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 400) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95, // Reduced to allow more vertical space
          ),
          itemCount: listForecastsWeather.length,
          itemBuilder: (context, index) {
            return _itemWeatherForecast(listForecastsWeather[index]);
          },
        );
      },
    );
  }

  Widget _itemWeatherForecast(ForecastWeather forecastWth) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8), // Reduced padding
      decoration: BoxDecoration(color: grayColor, borderRadius: BorderRadius.circular(5)),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '(${forecastWth.date})',
            style: TextStyle(color: whiteColor, fontWeight: FontWeight.w600, fontSize: 14), // Smaller font
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 5), // Reduced spacing
          SizedBox(
            height: 40, // Smaller image
            child: Image.network(
              '${forecastWth.iconUrl ?? ''}',
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return CircularProgressIndicator();
              },
            ),
          ),
          SizedBox(height: 5), // Reduced spacing
          Text(
            'Temp: ${forecastWth.temperature}°C',
            style: TextStyle(color: whiteColor, fontWeight: FontWeight.w500, fontSize: 12), // Smaller font
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3), // Reduced spacing
          Text(
            'Wind: ${forecastWth.windSpeed} M/s',
            style: TextStyle(color: whiteColor, fontWeight: FontWeight.w500, fontSize: 12), // Smaller font
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3), // Reduced spacing
          Text(
            'Humidity: ${forecastWth.humidity}%',
            style: TextStyle(color: whiteColor, fontWeight: FontWeight.w500, fontSize: 12), // Smaller font
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 