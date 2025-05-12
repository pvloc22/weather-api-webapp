import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/core/local_storage/search_history_service.dart';
import 'package:golden_owl/data/model/search_history_item.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_event.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchHistoryService _searchHistoryService = searchHistoryService;

  SearchBloc() : super(SearchInitial()) {
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<SearchQuerySubmitted>(_onSearchQuerySubmitted);
    on<RemoveSearchHistoryItem>(_onRemoveSearchHistoryItem);
    on<ClearSearchHistory>(_onClearSearchHistory);
    on<SearchHistoryItemSelected>(_onSearchHistoryItemSelected);
    on<UpdateSearchHistoryWeather>(_onUpdateSearchHistoryWeather);
    on<FilterSearchHistory>(_onFilterSearchHistory);
  }

  // Handle loading search history
  Future<void> _onLoadSearchHistory(LoadSearchHistory event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      final historyItems = await _searchHistoryService.getSearchHistory();
      emit(SearchHistoryLoaded(historyItems));
    } catch (e) {
      emit(SearchError('Could not load search history: $e'));
    }
  }

  // Handle real-time filtering as user types
  Future<void> _onFilterSearchHistory(FilterSearchHistory event, Emitter<SearchState> emit) async {
    try {
      final query = event.query.toLowerCase().trim();
      
      // If query is empty, just show regular history
      if (query.isEmpty) {
        final historyItems = await _searchHistoryService.getSearchHistory();
        emit(SearchHistoryLoaded(historyItems));
        return;
      }
      
      // Filter the history items by the query
      final allHistoryItems = await _searchHistoryService.getSearchHistory();
      
      // Helper function to compute relevance score
      int getRelevanceScore(SearchHistoryItem item) {
        int score = 0;
        
        // Exact matches get highest score
        if (item.query.toLowerCase() == query) {
          score += 100;
        }
        // Query starts with the search term
        else if (item.query.toLowerCase().startsWith(query)) {
          score += 75;
        }
        // Query contains the search term
        else if (item.query.toLowerCase().contains(query)) {
          score += 50;
        }
        
        // City name exact match
        if (item.cityName != null) {
          if (item.cityName!.toLowerCase() == query) {
            score += 90;
          }
          // City name starts with the search term
          else if (item.cityName!.toLowerCase().startsWith(query)) {
            score += 70;
          }
          // City name contains the search term
          else if (item.cityName!.toLowerCase().contains(query)) {
            score += 40;
          }
        }
        
        // Weather description contains search term
        if (item.weatherDescription != null && 
            item.weatherDescription!.toLowerCase().contains(query)) {
          score += 20;
        }
        
        // Boost more recent searches slightly
        score += (DateTime.now().difference(item.timestamp).inHours < 24) ? 5 : 0;
        
        return score;
      }
      
      // Filter and sort by relevance score
      final scoredItems = allHistoryItems
          .where((item) {
            // At least one field must contain the query
            return item.query.toLowerCase().contains(query) || 
                  (item.cityName != null && item.cityName!.toLowerCase().contains(query)) ||
                  (item.weatherDescription != null && item.weatherDescription!.toLowerCase().contains(query));
          })
          .map((item) => MapEntry(item, getRelevanceScore(item)))
          .where((entry) => entry.value > 0)  // Only include items with some relevance
          .toList();
      
      // Sort by score (descending)
      scoredItems.sort((a, b) => b.value.compareTo(a.value));
      
      // Extract just the items
      final filteredItems = scoredItems.map((entry) => entry.key).toList();
      
      emit(SearchHistoryFiltered(filteredItems, query));
    } catch (e) {
      // If there's an error, still show full history
      final historyItems = await _searchHistoryService.getSearchHistory();
      emit(SearchHistoryLoaded(historyItems));
    }
  }

  // Handle new search query submission
  Future<void> _onSearchQuerySubmitted(SearchQuerySubmitted event, Emitter<SearchState> emit) async {
    if (event.query.trim().isEmpty) {
      add(LoadSearchHistory());
      return;
    }

    emit(SearchLoading());
    try {
      // Save query to history
      await _searchHistoryService.addSearchQuery(query: event.query);

      // Perform search and return results
      emit(SearchSuccess(event.query));

      // Reload search history
      add(LoadSearchHistory());
    } catch (e) {
      emit(SearchError('Error while searching: $e'));
    }
  }

  // Handle updating weather information for a history item
  Future<void> _onUpdateSearchHistoryWeather(UpdateSearchHistoryWeather event, Emitter<SearchState> emit) async {
    try {
      await _searchHistoryService.updateSearchQueryWeatherInfo(
        query: event.query,
        cityName: event.cityName,
        weatherIcon: event.weatherIcon,
        weatherDescription: event.weatherDescription,
      );

      // No need to emit new state as this is a background update
    } catch (e) {
      // Log error but don't disrupt the UI
      print('Error updating search history weather: $e');
    }
  }

  // Handle removing an item from history
  Future<void> _onRemoveSearchHistoryItem(RemoveSearchHistoryItem event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      await _searchHistoryService.removeSearchQuery(event.query);
      add(LoadSearchHistory());
    } catch (e) {
      emit(SearchError('Could not remove search item: $e'));
    }
  }

  // Handle clearing all search history
  Future<void> _onClearSearchHistory(ClearSearchHistory event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      await _searchHistoryService.clearSearchHistory();
      emit(SearchHistoryLoaded([]));
    } catch (e) {
      emit(SearchError('Could not clear search history: $e'));
    }
  }

  // Handle selecting an item from history
  void _onSearchHistoryItemSelected(SearchHistoryItemSelected event, Emitter<SearchState> emit) {
    // add(SearchQuerySubmitted(event.query));
  }
}
