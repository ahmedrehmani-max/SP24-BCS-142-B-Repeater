import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/forecast_day.dart';
import '../models/weather.dart';

/// Thrown for every failure the UI should show as a readable message.
class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

/// Everything returned for one search.
class WeatherReport {
  final Weather current;
  final List<ForecastDay> forecast;

  const WeatherReport({required this.current, required this.forecast});
}

class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches current weather + 5-day forecast for [city].
  ///
  /// Throws [WeatherException] with a message meant for the user: an empty or
  /// unknown city, a rejected API key, or no internet connection.
  Future<WeatherReport> fetchByCity(String city, {String units = 'metric'}) async {
    final query = city.trim();
    if (query.isEmpty) {
      throw const WeatherException('Please enter a city name.');
    }

    final current = await _getJson('weather', query, units);
    final forecast = await _getJson('forecast', query, units);

    return WeatherReport(
      current: Weather.fromJson(current),
      forecast: ForecastDay.fromForecastJson(forecast),
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String endpoint,
    String city,
    String units,
  ) async {
    final uri = Uri.parse('${Config.baseUrl}/$endpoint').replace(
      queryParameters: {
        'q': city,
        'units': units,
        'appid': Config.apiKey,
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const WeatherException(
        'No internet connection. Check your network and try again.',
      );
    } on TimeoutException {
      throw const WeatherException(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const WeatherException(
        'Could not reach the weather service. Check your connection.',
      );
    }

    switch (response.statusCode) {
      case 200:
        return jsonDecode(response.body) as Map<String, dynamic>;
      case 400:
      case 404:
        throw WeatherException('"$city" was not found. Check the spelling.');
      case 401:
        throw const WeatherException(
          'The API key was rejected. Check the key in lib/config.dart.',
        );
      case 429:
        throw const WeatherException(
          'Too many requests for this API key. Try again in a minute.',
        );
      default:
        throw WeatherException(
          'Weather service error (${response.statusCode}). Try again later.',
        );
    }
  }

  void dispose() => _client.close();
}
