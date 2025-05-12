import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/data/model/search_history_item.dart';
import 'package:golden_owl/core/style/colors.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_bloc.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_event.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_state.dart';
import 'package:intl/intl.dart';
import 'package:golden_owl/core/local_storage/service_weather_preference.dart';

import '../detail_search_screen/detail_weather_history_search_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final SearchBloc _searchBloc;

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc();
    _searchBloc.add(LoadSearchHistory());
  }

  @override
  void dispose() {
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search History', style: TextStyle(fontWeight: FontWeight.w600, color: whiteColor)),
        backgroundColor: primaryBlue,
        iconTheme: IconThemeData(color: whiteColor),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, color: whiteColor),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          )
        ],
      ),
      body: BlocProvider(
        create: (context) => _searchBloc,
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return Center(child: CircularProgressIndicator(color: primaryBlue));
            } else if (state is SearchHistoryLoaded) {
              final items = state.historyItems;
              if (items.isEmpty) {
                return _buildEmptyState();
              }
              return _buildHistoryList(items);
            } else if (state is SearchError) {
              return Center(child: Text(state.message, style: TextStyle(color: errorColor)));
            }
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No search history yet',
            style: TextStyle(fontSize: 18, color: textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your search history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<SearchHistoryItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp);
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: 2,
          color: surfaceColor,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildLeadingIcon(item),
            title: Text(
              item.query,
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.cityName != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Found: ${item.cityName}',
                      style: TextStyle(fontWeight: FontWeight.w500, color: primaryDarkBlue),
                    ),
                  ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: textSecondary),
                    SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
                if (item.weatherDescription != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.weatherDescription!,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.cityName != null)
                  IconButton(
                    icon: Icon(Icons.visibility, color: accentColor),
                    tooltip: 'View details',
                    onPressed: () {
                      _navigateToDetailScreen(item.cityName!);
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: errorColor),
                  tooltip: 'Delete',
                  onPressed: () => _searchBloc.add(RemoveSearchHistoryItem(item.query)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToDetailScreen(String cityName) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );
    
    try {
      // Get cached weather data for this city
      final weatherResponse = await serviceWeatherPreferences.getCachedWeatherResponse(cityName);
      
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      if (weatherResponse != null) {
        // Navigate to detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailWeatherHistorySearchScreen(
              weatherResponse: weatherResponse,
              cityName: cityName,
            ),
          ),
        );
      } else {
        // Show error if no cached data found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No cached weather data found for $cityName'),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading weather data: ${e.toString()}'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Widget _buildLeadingIcon(SearchHistoryItem item) {
    // If we have a weather icon, display it
    if (item.weatherIcon != null && item.weatherIcon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          item.weatherIcon!,
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return _defaultLeadingIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _defaultLeadingIcon();
          },
        ),
      );
    }
    
    // Default icon if no weather icon is available
    return _defaultLeadingIcon();
  }
  
  Widget _defaultLeadingIcon() {
    return CircleAvatar(
      backgroundColor: primaryBlue,
      child: Icon(Icons.search, color: whiteColor),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Search History', style: TextStyle(color: primaryDarkBlue)),
        content: Text('Are you sure you want to clear all search history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _searchBloc.add(ClearSearchHistory());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}