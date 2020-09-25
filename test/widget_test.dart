// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:directory_picker/directory_picker.dart';

import 'package:quicktag/main.dart';

void main() {
  testWidgets('Scaffold with correct title', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Quick Tag'), findsOneWidget);

    expect(find.byWidget(new DirectoryPickerData()), findsNothing);
    await tester.tap(find.byIcon(Icons.folder));
    await tester.pump();
    expect(find.byWidget(new DirectoryPickerData()),
        Platform.isAndroid ? findsOneWidget : findsNothing);
    // // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);
  });
}
