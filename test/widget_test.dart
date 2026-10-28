import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_bus_ai/screens/student/student_dashboard.dart';

void main() {
  testWidgets('Student dashboard renders the CampusBusAI 360 branding', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: StudentDashboard()),
    );

    expect(find.text('CampusBusAI 360'), findsWidgets);
    expect(find.text('Track • Predict • Protect'), findsOneWidget);
    expect(find.textContaining('Hello, Atharv'), findsOneWidget);
  });
}
