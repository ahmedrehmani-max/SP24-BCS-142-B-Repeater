import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather.dart';
import 'weather_visuals.dart';

/// City name, big temperature, condition icon and the detail chips.
class CurrentWeatherCard extends StatelessWidget {
  final Weather weather;
  final bool metric;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.metric,
  });

  String get degrees => metric ? '°C' : '°F';
  String get speedUnit => metric ? 'm/s' : 'mph';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          weather.country.isEmpty
              ? weather.city
              : '${weather.city}, ${weather.country}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          DateFormat('EEEE, d MMMM  •  HH:mm').format(weather.observedAt),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Icon(
          WeatherVisuals.icon(weather.conditionCode, isNight: weather.isNight),
          size: 96,
          color: Colors.white,
        ),
        const SizedBox(height: 10),
        Text(
          '${weather.temperature.round()}$degrees',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            height: 1,
          ),
        ),
        Text(
          weather.describedNicely,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        Text(
          'Feels like ${weather.feelsLike.round()}$degrees  •  '
          'H ${weather.tempMax.round()}$degrees  L ${weather.tempMin.round()}$degrees',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _Detail(
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              value: '${weather.humidity}%',
            ),
            _Detail(
              icon: Icons.air,
              label: 'Wind',
              value: '${weather.windSpeed.toStringAsFixed(1)} $speedUnit',
            ),
            _Detail(
              icon: Icons.speed,
              label: 'Pressure',
              value: '${weather.pressure} hPa',
            ),
            _Detail(
              icon: Icons.visibility_outlined,
              label: 'Visibility',
              value: '${(weather.visibility / 1000).toStringAsFixed(1)} km',
            ),
            _Detail(
              icon: Icons.wb_twilight,
              label: 'Sunrise',
              value: DateFormat('HH:mm').format(weather.sunrise),
            ),
            _Detail(
              icon: Icons.nightlight_outlined,
              label: 'Sunset',
              value: DateFormat('HH:mm').format(weather.sunset),
            ),
          ],
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
