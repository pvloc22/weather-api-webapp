import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:golden_owl/data/model/search_history_item.dart';
import 'base_preferences.dart';

const String _storageKey = 'search_history';
const int _maxHistoryItems = 10;

SearchHistoryService searchHistoryService = SearchHistoryService();

class SearchHistoryService extends BasePreferences {
  
  // Get search history list
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_storageKey) ?? [];
    
    final historyList = <SearchHistoryItem>[];
    final now = DateTime.now();
    
    for (final item in historyJson) {
      try {
        final decodedItem = SearchHistoryItem.fromJson(jsonDecode(item));
        
        // Only include items from today
        if (isSameDate(decodedItem.timestamp, now)) {
          historyList.add(decodedItem);
        }
      } catch (e) {
        // Skip invalid items
        print('Error parsing history item: $e');
      }
    }
    
    // Sort by time, newest first
    historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return historyList;
  }
  
  // Add a keyword to search history
  Future<void> addSearchQuery({
    required String query,
    String? cityName,
    String? weatherIcon,
    String? weatherDescription,
  }) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_storageKey) ?? [];
    
    // Create new item
    final newItem = SearchHistoryItem(
      query: query.trim(),
      timestamp: DateTime.now(),
      cityName: cityName,
      weatherIcon: weatherIcon,
      weatherDescription: weatherDescription,
    );
    
    // Convert the entire list to objects
    final historyList = <SearchHistoryItem>[];
    final now = DateTime.now();
    
    for (final item in historyJson) {
      try {
        final decodedItem = SearchHistoryItem.fromJson(jsonDecode(item));
        
        // Only include items from today and not matching the new query
        if (isSameDate(decodedItem.timestamp, now) && 
            decodedItem.query.toLowerCase() != query.trim().toLowerCase()) {
          historyList.add(decodedItem);
        }
      } catch (e) {
        // Skip invalid items
        print('Error parsing history item: $e');
      }
    }
    
    // Add new item to the top
    historyList.insert(0, newItem);
    
    // Limit the number of items
    if (historyList.length > _maxHistoryItems) {
      historyList.removeRange(_maxHistoryItems, historyList.length);
    }
    
    // Save the list
    final updatedHistoryJson = historyList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, updatedHistoryJson);
  }
  
  // Update weather information for an existing keyword
  Future<void> updateSearchQueryWeatherInfo({
    required String query,
    String? cityName,
    String? weatherIcon,
    String? weatherDescription,
  }) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_storageKey) ?? [];
    
    final historyList = <SearchHistoryItem>[];
    bool updated = false;
    final now = DateTime.now();
    
    // Process existing items
    for (final item in historyJson) {
      try {
        final decodedItem = SearchHistoryItem.fromJson(jsonDecode(item));
        
        // Only include items from today
        if (isSameDate(decodedItem.timestamp, now)) {
          if (decodedItem.query.toLowerCase() == query.trim().toLowerCase()) {
            // Update existing item
            historyList.add(SearchHistoryItem(
              query: decodedItem.query,
              timestamp: decodedItem.timestamp,
              cityName: cityName ?? decodedItem.cityName,
              weatherIcon: weatherIcon ?? decodedItem.weatherIcon,
              weatherDescription: weatherDescription ?? decodedItem.weatherDescription,
            ));
            updated = true;
          } else {
            historyList.add(decodedItem);
          }
        }
      } catch (e) {
        // Skip invalid items
        print('Error parsing history item: $e');
      }
    }
    
    // If the query wasn't found, add it as a new item
    if (!updated) {
      await addSearchQuery(
        query: query,
        cityName: cityName,
        weatherIcon: weatherIcon,
        weatherDescription: weatherDescription,
      );
      return;
    }
    
    // Save the list
    final updatedHistoryJson = historyList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, updatedHistoryJson);
  }
  
  // Remove a keyword from history
  Future<void> removeSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_storageKey) ?? [];
    
    final historyList = <SearchHistoryItem>[];
    final now = DateTime.now();
    
    for (final item in historyJson) {
      try {
        final decodedItem = SearchHistoryItem.fromJson(jsonDecode(item));
        
        // Only include items from today and not matching the query to remove
        if (isSameDate(decodedItem.timestamp, now) && 
            decodedItem.query.toLowerCase() != query.toLowerCase()) {
          historyList.add(decodedItem);
        }
      } catch (e) {
        // Skip invalid items
        print('Error parsing history item: $e');
      }
    }
    
    final updatedHistoryJson = historyList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, updatedHistoryJson);
  }
  
  // Clear all search history
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}