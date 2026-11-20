import 'package:flutter/material.dart';

import '../models/forecast_day.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_list.dart';
import '../widgets/weather_visuals.dart';

/// Search a city and show its current weather plus a 5-day forecast.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = WeatherService();
  final searchController = TextEditingController();

  Weather? weather;
  List<ForecastDay> forecast = [];
  String? error;
  bool loading = false;
  bool metric = true;

  /// Cities already looked up this session, newest first.
  final recent = <String>[];

  @override
  void initState() {
    super.initState();
    search('Lahore');
  }

  @override
  void dispose() {
    searchController.dispose();
    service.dispose();
    super.dispose();
  }

  Future<void> search(String city) async {
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final report = await service.fetchByCity(
        city,
        units: metric ? 'metric' : 'imperial',
      );
      if (!mounted) return;
      setState(() {
        weather = report.current;
        forecast = report.forecast;
        loading = false;
        recent
          ..remove(report.current.city)
          ..insert(0, report.current.city);
        if (recent.length > 5) recent.removeLast();
      });
    } on WeatherException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.message;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Something went wrong: $e';
        loading = false;
      });
    }
  }

  /// Switching units re-fetches so the API converts the values.
  Future<void> toggleUnits() async {
    setState(() => metric = !metric);
    final city = weather?.city ?? searchController.text;
    if (city.trim().isNotEmpty) await search(city);
  }

  @override
  Widget build(BuildContext context) {
    final colors = weather == null
        ? const [Color(0xFF4B79A1), Color(0xFF283E51)]
        : WeatherVisuals.gradient(
            weather!.conditionCode,
            isNight: weather!.isNight,
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weather App'),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: loading ? null : toggleUnits,
            child: Text(
              metric ? '°C' : '°F',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loading || weather == null
                ? null
                : () => search(weather!.city),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => search(weather?.city ?? 'Lahore'),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _searchBar(),
                if (recent.length > 1) _recentChips(),
                const SizedBox(height: 18),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (error != null)
                  _errorBox(error!)
                else if (weather != null) ...[
                  CurrentWeatherCard(weather: weather!, metric: metric),
                  const SizedBox(height: 28),
                  ForecastList(days: forecast, metric: metric),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: search,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search for a city',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        suffixIcon: IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          onPressed: () => search(searchController.text),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _recentChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        children: [
          for (final city in recent.skip(1))
            ActionChip(
              label: Text(city),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              labelStyle: const TextStyle(color: Colors.white),
              side: BorderSide.none,
              onPressed: () => search(city),
            ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 54),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => search(
              searchController.text.trim().isEmpty
                  ? (weather?.city ?? 'Lahore')
                  : searchController.text,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
