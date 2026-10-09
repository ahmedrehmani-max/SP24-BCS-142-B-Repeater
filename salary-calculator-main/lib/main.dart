import 'package:flutter/material.dart';

import 'screens/salary_form_screen.dart';

void main() {
  runApp(const SalaryCalculatorApp());
}

/// Root widget of the Salary Calculator application.
class SalaryCalculatorApp extends StatelessWidget {
  const SalaryCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salary Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const SalaryFormScreen(),
    );
  }
}
