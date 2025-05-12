import 'dart:math';

import 'package:flutter/material.dart';
import 'package:golden_owl/core/style/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/data/model/weather_model.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_bloc.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_state.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_event.dart';

import '../../../../data/constaints/constaints.dart';
import '../../search/search_screen.dart';
import '../../search/history_screen.dart';
import '../../subscription/subscription_screen.dart';
import '../../weather_saved/weather_saved_screen.dart';

class HomeForm extends StatefulWidget {
  const HomeForm({super.key});

  @override
  State<HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<HomeForm> {
  final TextEditingController _cityNameController = TextEditingController();
  final ScrollController _scrollControllers = ScrollController();

  bool _isLoadingMore = false;
  WeatherResponse? _weatherResponse;

  /// Loading more
  int _daysForecast = 0;
  String _currentCityName = '';

  @override
  void initState() {
    if (!kIsWeb) {
      _scrollControllers.addListener(() {
        final maxScroll = _scrollControllers.position.maxScrollExtent;
        final currentScroll = _scrollControllers.position.pixels;
        // Check if we're at least 80% through the scroll
        if (currentScroll >= (maxScroll * 0.8)) {
          if (_daysForecast > 0 && _currentCityName.isNotEmpty && !_isLoadingMore && _daysForecast < 14) {
            /// Lazy loading
            _isLoadingMore = true;
            context.read<HomeBloc>().add(
              LoadMoreForecastEvent(
                cityName: _currentCityName,
                days: _daysForecast + 4,
                currentWeather: _weatherResponse!.currentWeather,
              ),
            );
          }
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _scrollControllers.dispose();
    _cityNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Dashboard', style: TextStyle(fontWeight: FontWeight.w600, color: whiteColor)),
        backgroundColor: blueColor,

        actions: [
          IconButton(
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeatherSavedScreen()),
              );
            },
            icon: Icon(Icons.save_alt, color: whiteColor),
          ),

          Padding(
            padding: EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
              icon: Icon(Icons.history_toggle_off, color: whiteColor),
            ),
          ),
        ],
      ),
      body: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          FocusScope.of(context).unfocus();
          if (state is HomeLoadingState) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(child: CircularProgressIndicator());
              },
            );
          } else if (state is HomeLoadedState) {
            Navigator.of(context).pop();
            _weatherResponse = WeatherResponse(
              currentWeather: state.currentWeather,
              forecastWeather: state.listForecastWeather,
            );
            _currentCityName = state.currentWeather.cityName!;
            _daysForecast = state.listForecastWeather.length;
            _isLoadingMore = false;
          } else if (state is HomeLoadedMoreState) {
            _weatherResponse = _weatherResponse!.copyWith(forecastWeather: state.forecastWeather);
            _daysForecast = state.forecastWeather.length;
            _isLoadingMore = false;
          } else if (state is HomeErrorState) {
            Navigator.of(context, rootNavigator: true).pop();
            FocusScope.of(context).unfocus();
            _isLoadingMore = false;

            // Different dialog/message based on error type
            if (state.errorType == CITY_NOT_FOUND_ERROR_TYPE) {
              // City not found error
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("City Not Found"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Location ', style: TextStyle(fontWeight: FontWeight.normal)),
                                TextSpan(
                                  text: _cityNameController.text,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                TextSpan(text: ' not found.', style: TextStyle(fontWeight: FontWeight.normal)),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Please check the spelling or try a different location.'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } else if (state.errorType == NETWORK_ERROR_TYPE) {
              // Network error
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Network Error"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('Unable to connect to the weather service.'),
                          SizedBox(height: 8),
                          Text('Please check your internet connection and try again.'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              // General or other errors
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Error"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(state.errorMessage),
                          SizedBox(height: 8),
                          Text('Please try again later.'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          } else if (state is HomeErrorMoreState) {
            /// Lazy loading
            _isLoadingMore = false;

            // Show a snackbar with the error message for load more errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                duration: Duration(seconds: 3),
                backgroundColor: state.errorType == NETWORK_ERROR_TYPE 
                    ? Colors.red 
                    : (state.errorType == CITY_NOT_FOUND_ERROR_TYPE ? Colors.orange : Colors.grey[700]),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          } else if (state is HomeLoadingMoreState) {
            /// Lazy loading
            _isLoadingMore = true;
          }
        },
        child: LayoutBuilder(
          builder: (context, constrains) {
            if (constrains.maxWidth < 600) {
              return SingleChildScrollView(
                child: Column(children: [_leftPanel(), _weatherResponse == null ? Container() : _rightPanel()]),
              );
            } else {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _leftPanel()),
                      _weatherResponse == null
                          ? Expanded(flex: 2, child: _RightPanelPlaceholder())
                          : Expanded(flex: 2, child: _rightPanel()),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _RightPanelPlaceholder() {
    return Column(children: [_buildSummaryPlaceholder(), SizedBox(height: 30), _buildForecastPlaceholderGrid()]);
  }

  Widget _buildForecastPlaceholderGrid() {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columns
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95, // Adjusted ratio to accommodate content height
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _itemWeatherForecastPlaceholder(),
    );
  }

  Widget _itemWeatherForecastPlaceholder() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: grayColor.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _placeholderLine(width: 80),
          SizedBox(height: 10),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
          ),
          SizedBox(height: 10),
          _placeholderLine(width: 100),
          SizedBox(height: 5),
          _placeholderLine(width: 90),
          SizedBox(height: 5),
          _placeholderLine(width: 70),
        ],
      ),
    );
  }

  Widget _placeholderLine({double width = 100, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildSummaryPlaceholder() {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 40),
      margin: EdgeInsets.only(top: 30),
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
                      _placeholderLine(width: 150),
                      SizedBox(height: 10),
                      _placeholderLine(width: 120),
                      SizedBox(height: 10),
                      _placeholderLine(width: 100),
                      SizedBox(height: 10),
                      _placeholderLine(width: 80),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(width: 60, height: 60, color: Colors.white24),
                    SizedBox(height: 8),
                    _placeholderLine(width: 100),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _placeholderLine(width: 150),
                SizedBox(height: 10),
                Align(alignment: Alignment.center, child: Container(width: 60, height: 60, color: Colors.white24)),
                SizedBox(height: 8),
                Align(alignment: Alignment.center, child: _placeholderLine(width: 100)),
                SizedBox(height: 10),
                _placeholderLine(width: 120),
                SizedBox(height: 10),
                _placeholderLine(width: 100),
                SizedBox(height: 10),
                _placeholderLine(width: 80),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _leftPanel() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter a city Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: TextField(
              controller: _cityNameController,
              onChanged: (value) {},
              decoration: InputDecoration(
                filled: true,
                fillColor: whiteColor,
                border: OutlineInputBorder(),
                hintText: 'E.g., New York, Tokyo',
                hintStyle: TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: blueColor, width: 1.0)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 1.0)),
                prefixIcon: Icon(Icons.search, color: blueColor, size: 30,),
              ),
              readOnly: true,
              onTap: () async {
                FocusScope.of(context).unfocus();

                // Navigate to SearchScreen with current query
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(
                      initialQuery: _cityNameController.text,
                    ),
                  ),
                );

                // Handle the returned query
                if (result != null && result is String && result.isNotEmpty) {
                  _cityNameController.text = result;
                  context.read<HomeBloc>().add(SearchCityEvent(cityName: result));
                }
              },
            ),
          ),
          InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              String cityName = _cityNameController.text;

              if (cityName.isNotEmpty) {
                context.read<HomeBloc>().add(SearchCityEvent(cityName: cityName));
              }
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: blueColor, borderRadius: BorderRadius.circular(5)),
              alignment: Alignment.center,
              child: Text('Search', style: TextStyle(color: whiteColor, fontSize: 16)),
            ),
          ),


          Container(
            margin: EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('or', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          InkWell(
            onTap: () {
              context.read<HomeBloc>().add(RequireCurrentLocationEvent(isWebsite: kIsWeb));
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 20),
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: grayColor, borderRadius: BorderRadius.circular(5)),
              child: Text('Use Current Location', style: TextStyle(fontSize: 16, color: whiteColor)),
            ),
          ),

          Container(
            margin: EdgeInsets.only(top: 30),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Subscription', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 20),
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: blueColor, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, color: blueColor),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Email Subscribe',
                      style: TextStyle(fontSize: 16, color: blueColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return _buildWeatherSummary(_weatherResponse!.currentWeather);
      },
    );
  }

  Widget _buildWeatherSummary(CurrentWeather currentWeather) {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 40),
      width: double.infinity,
      decoration: BoxDecoration(color: blueColor, borderRadius: BorderRadius.circular(5)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 400) {
            return Column(
              children: [
                Row(
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
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) {
        return current is HomeLoadedState || current is HomeLoadedMoreState || current is HomeLoadingState;
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildHeaderWeatherForecast(_weatherResponse!.forecastWeather.length), _buildWeatherForecast()],
        );
      },
    );
  }

  Widget _buildWeatherForecast() {
    if (kIsWeb) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _listWeatherForecastWebsite(_weatherResponse!.forecastWeather),
            BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (previous, current) {
                return current is HomeLoadedMoreState ||
                    current is HomeLoadingMoreState ||
                    current is HomeErrorMoreState;
              },
              builder: (context, state) {
                if (state is HomeLoadingMoreState) {
                  return Center(child: Container(margin: EdgeInsets.only(top: 30), child: CircularProgressIndicator()));
                } else {
                  return _daysForecast < 14 ? _buildSeeMoreButton() : Container();
                }
              },
            ),
          ],
        ),
      );
    } else {
      return BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
            child: _listWeatherForecastMobile(_weatherResponse!.forecastWeather, state),
          );
        },
      );
    }
  }

  Widget _buildSeeMoreButton() {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () {
          context.read<HomeBloc>().add(
            LoadMoreForecastEvent(
              cityName: _currentCityName,
              days: _daysForecast + 4,
              currentWeather: _weatherResponse!.currentWeather,
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(top: 30),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: blueColor, borderRadius: BorderRadius.circular(5)),
          child: Text('See more', style: TextStyle(color: whiteColor, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildHeaderWeatherForecast(int days) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Text('$days-Day Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
    );
  }

  Widget _listWeatherForecastMobile(List<ForecastWeather> listForecastsWeather, HomeState state) {
    // Don't show loading indicator if we're already at the maximum forecasts
    bool isLoading = _isLoadingMore && _daysForecast < 14;

    return SizedBox(
      height: 220, // Reduced height to prevent overflow
      child: ListView.builder(
        controller: _scrollControllers,
        scrollDirection: Axis.horizontal,
        itemCount: listForecastsWeather.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < listForecastsWeather.length) {
            return Container(
              width: 140, // Fixed width for mobile items
              child: _itemWeatherForecast(listForecastsWeather[index]),
            );
          } else {
            return Container(width: 80, child: Center(child: CircularProgressIndicator()));
          }
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
            childAspectRatio: 0.95,
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
            style: TextStyle(color: whiteColor, fontWeight: FontWeight.w600, fontSize: 14),
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
