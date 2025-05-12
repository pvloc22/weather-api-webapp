import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/data/model/search_history_item.dart';
import 'package:golden_owl/core/style/colors.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_bloc.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_event.dart';
import 'package:golden_owl/view/screens/search/search_bloc/search_state.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  
  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final SearchBloc _searchBloc;

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc();
    _searchBloc.add(LoadSearchHistory());
    
    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      // Apply initial filtering if there's an initial query
      _searchBloc.add(FilterSearchHistory(widget.initialQuery!));
    }

    // Set up listener for text changes to filter in real-time
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    _searchBloc.add(FilterSearchHistory(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search', style: TextStyle(color: whiteColor)),
          backgroundColor: primaryBlue,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return Center(child: CircularProgressIndicator(color: primaryBlue));
                  } else if (state is SearchHistoryLoaded) {
                    return _buildSearchHistory(state.historyItems);
                  } else if (state is SearchHistoryFiltered) {
                    return _buildFilteredResults(state.filteredItems, state.filterQuery);
                  } else if (state is SearchError) {
                    return Center(child: Text(state.message, style: TextStyle(color: errorColor)));
                  } else if (state is SearchSuccess) {
                    // Return search query and pop back
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pop(state.query);
                    });
                    
                    return Center(child: CircularProgressIndicator(color: primaryBlue));
                  }
                  
                  return Center(
                    child: Text(
                      'Enter keywords to search',
                      style: TextStyle(color: textSecondary),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: primaryBlue,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: primaryBlue, size: 30,),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _searchBloc.add(LoadSearchHistory());
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _searchBloc.add(SearchQuerySubmitted(query));
                  Navigator.pop(context, query.trim());
                }
              },
              autofocus: widget.initialQuery == null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredResults(List<SearchHistoryItem> items, String query) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No results found for "$query"',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _searchBloc.add(SearchQuerySubmitted(query));
                Navigator.pop(context, query.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: whiteColor,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('Search for "$query"'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Results for "$query"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: item.weatherIcon != null ? 
                  Image.network(
                    item.weatherIcon!,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                      backgroundColor: accentColor.withOpacity(0.2),
                      child: Icon(Icons.history, color: primaryBlue),
                    ),
                  ) : 
                  CircleAvatar(
                    backgroundColor: accentColor.withOpacity(0.2),
                    child: Icon(Icons.history, color: primaryBlue),
                  ),
                title: _highlightMatchText(item.cityName ?? item.query, query),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightMatchText('Searched: ${item.query}', query, style: TextStyle(fontSize: 12, color: textSecondary)),
                    _highlightMatchText(
                      item.weatherDescription ?? formattedDate.toString(), 
                      query,
                      style: TextStyle(fontSize: 12, color: textSecondary)
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 18, color: primaryBlue),
                  onPressed: () {
                    _searchBloc.add(SearchHistoryItemSelected(item.query));
                    Navigator.pop(context, item.query);
                  },
                ),
                onTap: () {
                  _searchController.text = item.query;
                  _searchBloc.add(SearchHistoryItemSelected(item.query));
                  Navigator.pop(context, item.query);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Helper method to highlight matching text
  Widget _highlightMatchText(String text, String query, {TextStyle? style}) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(
        text,
        style: style ?? TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      );
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int start = 0;
    while (true) {
      final int matchIndex = lowerText.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        // No more matches, add the rest of the text
        if (start < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(start),
              style: style ?? TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
            ),
          );
        }
        break;
      }
      
      // Add text before match
      if (matchIndex > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, matchIndex),
            style: style ?? TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
        );
      }
      
      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            backgroundColor: accentColor.withOpacity(0.2),
          ),
        ),
      );
      
      // Update start index for next match
      start = matchIndex + query.length;
    }
    
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildSearchHistory(List<SearchHistoryItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No search history yet',
          style: TextStyle(fontSize: 16, color: textSecondary),
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
                'Search History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _searchBloc.add(ClearSearchHistory()),
                child: Text('Clear All', style: TextStyle(color: errorColor)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: item.weatherIcon != null ? 
                  Image.network(
                    item.weatherIcon!,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                      backgroundColor: accentColor.withOpacity(0.2),
                      child: Icon(Icons.history, color: primaryBlue),
                    ),
                  ) : 
                  CircleAvatar(
                    backgroundColor: accentColor.withOpacity(0.2),
                    child: Icon(Icons.history, color: primaryBlue),
                  ),
                title: Text(
                  item.cityName ?? item.query,
                  style: TextStyle(color: textPrimary),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.cityName != null && item.query != item.cityName)
                      Text(
                        'Searched: ${item.query}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    Text(
                      item.weatherDescription ?? formattedDate,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: textSecondary),
                      onPressed: () => _searchBloc.add(RemoveSearchHistoryItem(item.query)),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 18, color: primaryBlue),
                      onPressed: () {
                        _searchBloc.add(SearchHistoryItemSelected(item.query));
                        Navigator.pop(context, item.query);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  _searchController.text = item.query;
                  _searchBloc.add(SearchHistoryItemSelected(item.query));
                  Navigator.pop(context, item.query);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
