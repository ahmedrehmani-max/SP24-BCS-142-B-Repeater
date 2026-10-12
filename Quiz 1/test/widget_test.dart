// Basic smoke test: the registration form renders all required widgets
// and the Submit button displays the selected values.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiz1_registration_form/main.dart';

void main() {
  // The form is taller than the default 800x600 test surface.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.devicePixelRatio = 1.0;
    view.physicalSize = const Size(800, 1400);
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('Registration form shows the required widgets', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Student Registration Form'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(Radio<String>), findsNWidgets(5)); // 2 gender + 3 shift
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
  });

  testWidgets('Submit shows the entered values', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byType(TextField).first, 'Ahmad');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pump();

    expect(find.textContaining('Name: Ahmad'), findsOneWidget);
    expect(find.textContaining('Gender: Male'), findsOneWidget);
  });
}
