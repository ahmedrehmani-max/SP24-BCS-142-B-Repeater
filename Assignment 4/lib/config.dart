/// OpenWeatherMap configuration.
///
/// The key is compiled in so the app runs straight after `flutter run`.
/// It can be overridden without touching the code:
///   flutter run --dart-define=OWM_API_KEY=your_key_here
class Config {
  static const apiKey = String.fromEnvironment(
    'OWM_API_KEY',
    defaultValue: 'e3c92490a29585f9dd058f0a020bfad6',
  );

  static const baseUrl = 'https://api.openweathermap.org/data/2.5';
}
