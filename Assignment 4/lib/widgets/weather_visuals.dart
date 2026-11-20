import 'package:flutter/material.dart';

/// Maps OpenWeatherMap condition ids to an icon and a background gradient, so
/// the screen looks different for rain, snow, clear skies and so on.
///
/// Condition id ranges come from https://openweathermap.org/weather-conditions
class WeatherVisuals {
  static IconData icon(int conditionCode, {bool isNight = false}) {
    if (conditionCode >= 200 && conditionCode < 300) return Icons.thunderstorm;
    if (conditionCode >= 300 && conditionCode < 400) return Icons.grain;
    if (conditionCode >= 500 && conditionCode < 600) return Icons.water_drop;
    if (conditionCode >= 600 && conditionCode < 700) return Icons.ac_unit;
    if (conditionCode >= 700 && conditionCode < 800) return Icons.foggy;
    if (conditionCode == 800) {
      return isNight ? Icons.nightlight_round : Icons.wb_sunny;
    }
    if (conditionCode == 801 || conditionCode == 802) {
      return isNight ? Icons.nights_stay : Icons.wb_cloudy;
    }
    return Icons.cloud;
  }

  static List<Color> gradient(int conditionCode, {bool isNight = false}) {
    if (isNight) return const [Color(0xFF1A237E), Color(0xFF3949AB)];
    if (conditionCode >= 200 && conditionCode < 300) {
      return const [Color(0xFF373B44), Color(0xFF4286F4)];
    }
    if (conditionCode >= 300 && conditionCode < 600) {
      return const [Color(0xFF3A6073), Color(0xFF16222A)];
    }
    if (conditionCode >= 600 && conditionCode < 700) {
      return const [Color(0xFF83A4D4), Color(0xFFB6FBFF)];
    }
    if (conditionCode >= 700 && conditionCode < 800) {
      return const [Color(0xFF606C88), Color(0xFF3F4C6B)];
    }
    if (conditionCode == 800) {
      return const [Color(0xFF2193B0), Color(0xFF6DD5ED)];
    }
    return const [Color(0xFF4B79A1), Color(0xFF283E51)];
  }
}
