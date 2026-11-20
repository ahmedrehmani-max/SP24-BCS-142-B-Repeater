/// One day of the 5-day forecast, built from the 3-hourly /forecast list.
class ForecastDay {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int conditionCode;
  final String description;

  const ForecastDay({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.conditionCode,
    required this.description,
  });

  /// Groups the 3-hourly entries by calendar day and reduces each group to a
  /// min/max plus the condition reported closest to midday.
  static List<ForecastDay> fromForecastJson(Map<String, dynamic> json) {
    final entries = (json['list'] as List).cast<Map<String, dynamic>>();
    final byDay = <String, List<Map<String, dynamic>>>{};

    for (final entry in entries) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        (entry['dt'] as num).toInt() * 1000,
      );
      final key = '${date.year}-${date.month}-${date.day}';
      byDay.putIfAbsent(key, () => []).add(entry);
    }

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    final days = <ForecastDay>[];
    for (final group in byDay.entries) {
      if (group.key == todayKey) continue; // "today" is the current weather

      var min = double.infinity;
      var max = double.negativeInfinity;
      Map<String, dynamic>? middayEntry;
      var smallestDistanceToNoon = 25;

      for (final entry in group.value) {
        final main = entry['main'] as Map<String, dynamic>;
        min = (main['temp_min'] as num).toDouble() < min
            ? (main['temp_min'] as num).toDouble()
            : min;
        max = (main['temp_max'] as num).toDouble() > max
            ? (main['temp_max'] as num).toDouble()
            : max;

        final hour = DateTime.fromMillisecondsSinceEpoch(
          (entry['dt'] as num).toInt() * 1000,
        ).hour;
        final distance = (hour - 12).abs();
        if (distance < smallestDistanceToNoon) {
          smallestDistanceToNoon = distance;
          middayEntry = entry;
        }
      }

      final representative = middayEntry ?? group.value.first;
      final weather =
          (representative['weather'] as List).first as Map<String, dynamic>;

      days.add(ForecastDay(
        date: DateTime.fromMillisecondsSinceEpoch(
          (representative['dt'] as num).toInt() * 1000,
        ),
        minTemp: min,
        maxTemp: max,
        conditionCode: (weather['id'] as num?)?.toInt() ?? 800,
        description: weather['description'] as String? ?? '',
      ));
    }

    days.sort((a, b) => a.date.compareTo(b.date));
    return days.take(5).toList();
  }
}
