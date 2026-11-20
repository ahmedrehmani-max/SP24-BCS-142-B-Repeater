import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/forecast_day.dart';
import 'weather_visuals.dart';

/// Horizontal strip with the next five days.
class ForecastList extends StatelessWidget {
  final List<ForecastDay> days;
  final bool metric;

  const ForecastList({super.key, required this.days, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final degrees = metric ? '°' : '°';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '5-day forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final day = days[index];
              return Container(
                width: 104,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      DateFormat('EEE').format(day.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM').format(day.date),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Icon(
                      WeatherVisuals.icon(day.conditionCode),
                      color: Colors.white,
                      size: 30,
                    ),
                    Text(
                      '${day.maxTemp.round()}$degrees / ${day.minTemp.round()}$degrees',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
