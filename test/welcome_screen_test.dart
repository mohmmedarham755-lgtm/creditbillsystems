// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/welcome_screen.dart';

Widget _testApp({required ThemeData theme, VoidCallback? onGetStarted}) {
  return MaterialApp(
    theme: theme,
    home: WelcomeScreen(onGetStarted: onGetStarted),
  );
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows the branded introduction and primary action', (
      tester,
    ) async {
      await tester.pumpWidget(_testApp(theme: AppTheme.lightTheme));

      expect(find.byKey(WelcomeScreen.screenKey), findsOneWidget);
      expect(find.byKey(WelcomeScreen.heroKey), findsOneWidget);
      expect(find.text('Credit Bill System'), findsOneWidget);
      expect(find.text('Stay ahead of every bill'), findsOneWidget);
      expect(find.text('Every bill. One clear view.'), findsOneWidget);
      expect(
        find.text(
          'Track cards, catch due dates, and log payments in seconds — all '
          'in one calm place.',
        ),
        findsOneWidget,
      );

      expect(find.byKey(WelcomeScreen.featuresKey), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.byKey(WelcomeScreen.getStartedKey), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);
    });

    testWidgets('Get Started hands off through the callback', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _testApp(theme: AppTheme.lightTheme, onGetStarted: () => calls++),
      );

      final button = find.byKey(WelcomeScreen.getStartedKey);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('renders with the dark theme', (tester) async {
      await tester.pumpWidget(_testApp(theme: AppTheme.darkTheme));

      expect(find.byKey(WelcomeScreen.screenKey), findsOneWidget);
      expect(find.text('Every bill. One clear view.'), findsOneWidget);
      expect(find.byKey(WelcomeScreen.getStartedKey), findsOneWidget);
    });
  });
}
