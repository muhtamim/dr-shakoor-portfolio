// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drmdabdusshakoor/main.dart'; // Make sure this path is correct

void main() {
  testWidgets('Portfolio App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We are pumping PortfolioAndBlogApp() which is the root widget of our application.
    await tester.pumpWidget(PortfolioAndBlogApp());

    // Verify that the HomePage is being displayed.
    // We can check for a static element like the AppBar title.
    expect(find.text('Prof. Dr. Abdus Shakoor'), findsOneWidget);

    // Verify that the "Admin Login" button is present.
    expect(find.text('Admin Login'), findsOneWidget);

    // Example of a negative test: Verify a widget that doesn't exist is not found.
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
