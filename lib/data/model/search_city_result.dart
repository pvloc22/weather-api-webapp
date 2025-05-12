class SearchCityResult {
  final int id;
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String url;

  SearchCityResult({
    required this.id,
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.url,
  });

  factory SearchCityResult.fromMap(Map<String, dynamic> map) {
    return SearchCityResult(
      id: map['id'],
      name: map['name'],
      region: map['region'],
      country: map['country'],
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      url: map['url'],
    );
  }

  @override
  String toString() {
    return '$name, $country';
  }
}
