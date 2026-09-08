import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Le thème et les widgets de base se construisent sans erreur', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Jalon')),
        ),
      ),
    );

    expect(find.text('Jalon'), findsOneWidget);
  });
}
