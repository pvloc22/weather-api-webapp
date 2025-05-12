class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final String? cityName;
  final String? weatherIcon;
  final String? weatherDescription;

  SearchHistoryItem({
    required this.query,
    required this.timestamp,
    this.cityName,
    this.weatherIcon,
    this.weatherDescription,
  });

  // Create from JSON
  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      cityName: json['cityName'] as String?,
      weatherIcon: json['weatherIcon'] as String?,
      weatherDescription: json['weatherDescription'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'cityName': cityName,
      'weatherIcon': weatherIcon,
      'weatherDescription': weatherDescription,
    };
  }
} 