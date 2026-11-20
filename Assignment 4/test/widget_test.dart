// Tests for JSON parsing and the error handling the UI depends on.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:weather_app/models/forecast_day.dart';
import 'package:weather_app/models/weather.dart';
import 'package:weather_app/services/weather_service.dart';

const currentJson = '''
{"weather":[{"id":802,"main":"Clouds","description":"scattered clouds","icon":"03d"}],
 "main":{"temp":19.99,"feels_like":19.72,"temp_min":18.0,"temp_max":21.5,
         "pressure":1018,"humidity":64},
 "visibility":4000,"wind":{"speed":2.5},"dt":1795191305,
 "sys":{"country":"PK","sunrise":1795138480,"sunset":1795176118},
 "name":"Lahore","timezone":18000,"cod":200}
''';

String forecastJson(int dayOffset) {
  final base = DateTime.now().add(Duration(days: dayOffset));
  DateTime at(int hour) =>
      DateTime(base.year, base.month, base.day, hour);
  String entry(int hour, double min, double max) => '''
    {"dt":${at(hour).millisecondsSinceEpoch ~/ 1000},
     "main":{"temp":$max,"temp_min":$min,"temp_max":$max},
     "weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}]}
  ''';
  return '{"list":[${entry(6, 10, 14)},${entry(12, 15, 22)},${entry(21, 11, 16)}]}';
}

void main() {
  group('Weather.fromJson', () {
    test('reads every field the UI shows', () {
      final weather =
          Weather.fromJson(jsonDecode(currentJson) as Map<String, dynamic>);

      expect(weather.city, 'Lahore');
      expect(weather.country, 'PK');
      expect(weather.temperature, 19.99);
      expect(weather.conditionCode, 802);
      expect(weather.humidity, 64);
      expect(weather.windSpeed, 2.5);
      expect(weather.describedNicely, 'Scattered clouds');
      expect(weather.isNight, isFalse);
    });

    test('shows times in the city timezone, not the device one', () {
      final weather =
          Weather.fromJson(jsonDecode(currentJson) as Map<String, dynamic>);

      // 1795138480 is 01:34 UTC; Lahore is UTC+5 (timezone: 18000).
      expect(weather.sunrise.hour, 6);
      expect(weather.sunrise.minute, 34);
    });
  });

  group('ForecastDay', () {
    test('collapses the 3-hourly list into one entry per day', () {
      final days = ForecastDay.fromForecastJson(
        jsonDecode(forecastJson(1)) as Map<String, dynamic>,
      );

      expect(days.length, 1);
      expect(days.single.minTemp, 10);
      expect(days.single.maxTemp, 22);
      // The midday entry is the one that describes the day.
      expect(days.single.date.hour, 12);
    });

    test('drops today, which the current weather already covers', () {
      final days = ForecastDay.fromForecastJson(
        jsonDecode(forecastJson(0)) as Map<String, dynamic>,
      );
      expect(days, isEmpty);
    });
  });

  group('WeatherService error handling', () {
    WeatherService serviceReturning(int status, [String body = '{}']) =>
        WeatherService(
          client: MockClient((_) async => http.Response(body, status)),
        );

    test('rejects an empty city before calling the API', () {
      expect(
        () => WeatherService(
          client: MockClient((_) async => throw StateError('must not be called')),
        ).fetchByCity('   '),
        throwsA(isA<WeatherException>()),
      );
    });

    test('404 becomes a readable "not found" message', () async {
      await expectLater(
        serviceReturning(404).fetchByCity('Nowhereville'),
        throwsA(
          isA<WeatherException>().having(
            (e) => e.message,
            'message',
            contains('Nowhereville'),
          ),
        ),
      );
    });

    test('401 points at the API key', () async {
      await expectLater(
        serviceReturning(401).fetchByCity('Lahore'),
        throwsA(
          isA<WeatherException>()
              .having((e) => e.message, 'message', contains('API key')),
        ),
      );
    });

    test('a successful call returns current weather and forecast', () async {
      final service = WeatherService(
        client: MockClient((request) async => http.Response(
              request.url.path.endsWith('forecast')
                  ? forecastJson(1)
                  : currentJson,
              200,
            )),
      );

      final report = await service.fetchByCity('Lahore');
      expect(report.current.city, 'Lahore');
      expect(report.forecast.length, 1);
    });
  });
}
