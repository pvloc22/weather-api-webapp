import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:golden_owl/data/model/search_history_item.dart';

class SearchHistoryService {
  static final SearchHistoryService _instance = SearchHistoryService._internal();

  factory SearchHistoryService() {
    return _instance;
  }

  SearchHistoryService._internal();

  static const String _storageKey = 'search_history';
  static const int _maxHistoryItems = 10;

  // Get search history list
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_storageKey) ?? [];

    final historyList = historyJson
        .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
        .toList();

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
    final historyList = historyJson
        .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
        .toList();

    // Remove duplicate items
    historyList.removeWhere((item) => item.query.toLowerCase() == query.trim().toLowerCase());

    // Add new item to the top
    historyList.insert(0, newItem);

    // Limit the number of items
    if (historyList.length > _maxHistoryItems) {
      historyList.removeLast();
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

    final historyList = historyJson
        .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
        .toList();

    // Find and update item
    for (int i = 0; i < historyList.length; i++) {
      if (historyList[i].query.toLowerCase() == query.trim().toLowerCase()) {
        historyList[i] = SearchHistoryItem(
          query: historyList[i].query,
          timestamp: historyList[i].timestamp,
          cityName: cityName ?? historyList[i].cityName,
          weatherIcon: weatherIcon ?? historyList[i].weatherIcon,
          weatherDescription: weatherDescription ?? historyList[i].weatherDescription,
        );
        break;
      }
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

    final historyList = historyJson
        .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
        .toList();

    historyList.removeWhere((item) => item.query.toLowerCase() == query.toLowerCase());

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