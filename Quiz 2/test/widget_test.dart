// Basic smoke test: the app builds and shows the patient list screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:quiz2_doctor_app/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App starts on the patient list screen', (tester) async {
    await tester.pumpWidget(const DoctorApp());

    expect(find.text('My Patients'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Add Patient'), findsOneWidget);
  });
}
