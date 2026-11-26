// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creditbillsytems/core/theme/app_theme.dart';
import 'package:creditbillsytems/features/settings/domain/welcome_layout.dart';
import 'package:creditbillsytems/features/settings/presentation/contact_details_page.dart';
import 'package:creditbillsytems/welcome_screen.dart';

Widget _testApp({required ThemeData theme, VoidCallback? onGetStarted}) {
  return MaterialApp(
    theme: theme,
    home: WelcomeScreen(onGetStarted: onGetStarted),
  );
}

void main() {
  setUp(() {
    WelcomeLayout.setOrder(WelcomeLayout.defaultOrder);
  });

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
      expect(find.byKey(WelcomeScreen.helpKey), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.byKey(WelcomeScreen.settingsKey), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
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

    testWidgets('Help link opens instructions and support phone', (
      tester,
    ) async {
      await tester.pumpWidget(_testApp(theme: AppTheme.lightTheme));

      final link = find.byKey(WelcomeScreen.helpKey);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pump();

      expect(find.text('How to use Credit Bill System'), findsOneWidget);
      expect(find.text('1. Get Started to sign in or create an account.'), findsOneWidget);
      expect(find.text('3. Open Bills and tap Add Bill for a statement.'), findsOneWidget);
      expect(find.text('4. Tap Record Payment on a bill to pay it.'), findsOneWidget);
      expect(find.byKey(WelcomeScreen.helpDialogInstructionsKey), findsOneWidget);
      expect(
        find.text('Need help? Call ${ContactDetailsPage.supportPhone}'),
        findsOneWidget,
      );
      expect(find.byKey(WelcomeScreen.helpDialogPhoneKey), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pump();
      expect(find.text('How to use Credit Bill System'), findsNothing);
    });

    testWidgets('Help dialog Get Started hands off through the callback', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _testApp(theme: AppTheme.lightTheme, onGetStarted: () => calls++),
      );

      final link = find.byKey(WelcomeScreen.helpKey);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pump();

      await tester.tap(find.byKey(WelcomeScreen.helpDialogStartKey));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('Settings link routes visitors to sign-in', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _testApp(theme: AppTheme.lightTheme, onGetStarted: () => calls++),
      );

      final link = find.byKey(WelcomeScreen.settingsKey);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pump();

      expect(find.text('Settings'), findsNWidgets(2));
      expect(
        find.textContaining('Settings are available after you sign in'),
        findsOneWidget,
      );
      expect(
        find.text('Need help? Call ${ContactDetailsPage.supportPhone}'),
        findsOneWidget,
      );
      expect(find.byKey(WelcomeScreen.settingsDialogPhoneKey), findsOneWidget);

      await tester.tap(find.byKey(WelcomeScreen.settingsDialogStartKey));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('shows Help and Settings below Get Started by default', (
      tester,
    ) async {
      await tester.pumpWidget(_testApp(theme: AppTheme.lightTheme));

      final getStartedTop = tester.getTopLeft(
        find.byKey(WelcomeScreen.getStartedKey),
      ).dy;
      final helpTop = tester.getTopLeft(find.byKey(WelcomeScreen.helpKey)).dy;
      final settingsTop = tester.getTopLeft(
        find.byKey(WelcomeScreen.settingsKey),
      ).dy;

      expect(getStartedTop, lessThan(helpTop));
      expect(helpTop, lessThan(settingsTop));
    });

    testWidgets('renders actions in the configured order', (tester) async {
      WelcomeLayout.setOrder([
        WelcomeItemId.settings,
        WelcomeItemId.getStarted,
        WelcomeItemId.help,
      ]);
      await tester.pumpWidget(_testApp(theme: AppTheme.lightTheme));

      final settingsTop = tester.getTopLeft(
        find.byKey(WelcomeScreen.settingsKey),
      ).dy;
      final getStartedTop = tester.getTopLeft(
        find.byKey(WelcomeScreen.getStartedKey),
      ).dy;
      final helpTop = tester.getTopLeft(find.byKey(WelcomeScreen.helpKey)).dy;

      expect(settingsTop, lessThan(getStartedTop));
      expect(getStartedTop, lessThan(helpTop));
    });

    testWidgets('renders with the dark theme', (tester) async {
      await tester.pumpWidget(_testApp(theme: AppTheme.darkTheme));

      expect(find.byKey(WelcomeScreen.screenKey), findsOneWidget);
      expect(find.text('Every bill. One clear view.'), findsOneWidget);
      expect(find.byKey(WelcomeScreen.getStartedKey), findsOneWidget);
    });
  });
}
