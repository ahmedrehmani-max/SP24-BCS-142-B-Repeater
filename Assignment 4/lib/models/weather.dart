/// Current weather for one city, parsed from /data/2.5/weather.
class Weather {
  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String condition; // e.g. "Clouds"
  final String description; // e.g. "scattered clouds"
  final int conditionCode; // OpenWeatherMap condition id
  final String iconCode; // e.g. "03n"
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;
  /// Times are shifted into the searched city's own timezone, so a city in
  /// another country shows its local sunrise rather than the phone's.
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime observedAt;

  const Weather({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.description,
    required this.conditionCode,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.observedAt,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = (json['wind'] as Map<String, dynamic>?) ?? const {};
    final sys = (json['sys'] as Map<String, dynamic>?) ?? const {};

    // OpenWeatherMap returns UTC timestamps plus the city's offset in seconds.
    final offset = Duration(
      seconds: (json['timezone'] as num?)?.toInt() ?? 0,
    );
    DateTime fromUnix(Object? value) => DateTime.fromMillisecondsSinceEpoch(
          ((value as num?)?.toInt() ?? 0) * 1000,
          isUtc: true,
        ).add(offset);

    return Weather(
      city: json['name'] as String? ?? 'Unknown',
      country: sys['country'] as String? ?? '',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      condition: weather['main'] as String? ?? '',
      description: weather['description'] as String? ?? '',
      conditionCode: (weather['id'] as num?)?.toInt() ?? 800,
      iconCode: weather['icon'] as String? ?? '01d',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      pressure: (main['pressure'] as num?)?.toInt() ?? 0,
      visibility: (json['visibility'] as num?)?.toInt() ?? 0,
      sunrise: fromUnix(sys['sunrise']),
      sunset: fromUnix(sys['sunset']),
      observedAt: fromUnix(json['dt']),
    );
  }

  /// "scattered clouds" -> "Scattered clouds"
  String get describedNicely => description.isEmpty
      ? condition
      : description[0].toUpperCase() + description.substring(1);

  /// The icon code ends with 'd' for day and 'n' for night.
  bool get isNight => iconCode.endsWith('n');
}
