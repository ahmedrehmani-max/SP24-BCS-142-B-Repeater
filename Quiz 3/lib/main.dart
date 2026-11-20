// CSC303 - Mobile Application Development
// Quiz No. 3 (CLO-3): Color Water Sort Puzzle Game

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AudioService.instance.init();
  final settings = SettingsController();
  await settings.load();

  runApp(
    ChangeNotifierProvider<SettingsController>.value(
      value: settings,
      child: const ColorWaterSortApp(),
    ),
  );
}

class ColorWaterSortApp extends StatelessWidget {
  const ColorWaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Water Sort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2FF7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1B1035),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
