abstract class SearchEvent {}

// Event when user performs a search
class SearchQuerySubmitted extends SearchEvent {
  final String query;
  
  SearchQuerySubmitted(this.query);
}

// Event when loading search history
class LoadSearchHistory extends SearchEvent {}

// Event when removing an item from history
class RemoveSearchHistoryItem extends SearchEvent {
  final String query;
  
  RemoveSearchHistoryItem(this.query);
}

// Event when clearing all history
class ClearSearchHistory extends SearchEvent {}

// Event when selecting an item from history
class SearchHistoryItemSelected extends SearchEvent {
  final String query;
  
  SearchHistoryItemSelected(this.query);
}

// Event for updating weather information for a history item
class UpdateSearchHistoryWeather extends SearchEvent {
  final String query;
  final String? cityName;
  final String? weatherIcon;
  final String? weatherDescription;
  
  UpdateSearchHistoryWeather({
    required this.query,
    this.cityName,
    this.weatherIcon,
    this.weatherDescription,
  });
}

// Event for filtering search history as user types
class FilterSearchHistory extends SearchEvent {
  final String query;
  
  FilterSearchHistory(this.query);
} 