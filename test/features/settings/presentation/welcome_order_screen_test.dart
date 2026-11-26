// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:creditbillsytems/features/settings/domain/app_settings.dart';
import 'package:creditbillsytems/features/settings/domain/settings_repository.dart';
import 'package:creditbillsytems/features/settings/domain/welcome_layout.dart';
import 'package:creditbillsytems/features/settings/presentation/welcome_order_screen.dart';

class _FakeSettingsRepository implements SettingsRepository {
  List<String>? savedOrder;

  @override
  Future<AppSettings> getSettings() async => const AppSettings();

  @override
  Future<void> saveLogoPath(String? logoPath) async {}

  @override
  Future<List<String>?> getWelcomeOrder() async => savedOrder;

  @override
  Future<void> saveWelcomeOrder(List<String> order) async {
    savedOrder = List<String>.from(order);
  }

  @override
  Future<String?> getBankName() async => null;

  @override
  Future<void> saveBankName(String? bankName) async {}
}

Widget _testApp(SettingsRepository repository) {
  return MultiProvider(
    providers: [
      Provider<SettingsRepository?>.value(value: repository),
    ],
    child: const MaterialApp(home: WelcomeOrderScreen()),
  );
}

void main() {
  setUp(() {
    WelcomeLayout.setOrder(WelcomeLayout.defaultOrder);
  });

  testWidgets('lists all welcome actions with boundary arrows disabled', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_FakeSettingsRepository()));

    expect(find.byKey(WelcomeOrderScreen.screenKey), findsOneWidget);
    expect(
      find.byKey(WelcomeOrderScreen.itemKey(WelcomeItemId.getStarted)),
      findsOneWidget,
    );
    expect(
      find.byKey(WelcomeOrderScreen.itemKey(WelcomeItemId.help)),
      findsOneWidget,
    );
    expect(
      find.byKey(WelcomeOrderScreen.itemKey(WelcomeItemId.settings)),
      findsOneWidget,
    );

    final firstUp = tester.widget<IconButton>(
      find.byKey(WelcomeOrderScreen.upKey(WelcomeItemId.getStarted)),
    );
    final lastDown = tester.widget<IconButton>(
      find.byKey(WelcomeOrderScreen.downKey(WelcomeItemId.settings)),
    );
    expect(firstUp.onPressed, isNull);
    expect(lastDown.onPressed, isNull);
  });

  testWidgets('moving an action updates shared order and persists it', (
    tester,
  ) async {
    final repository = _FakeSettingsRepository();
    await tester.pumpWidget(_testApp(repository));

    await tester.tap(
      find.byKey(WelcomeOrderScreen.downKey(WelcomeItemId.getStarted)),
    );
    await tester.pumpAndSettle();

    final expected = [WelcomeItemId.help, WelcomeItemId.getStarted, WelcomeItemId.settings];
    expect(WelcomeLayout.order.value, expected);
    expect(repository.savedOrder, expected);
  });

  testWidgets('moving back up restores the original order', (tester) async {
    await tester.pumpWidget(_testApp(_FakeSettingsRepository()));

    await tester.tap(
      find.byKey(WelcomeOrderScreen.downKey(WelcomeItemId.getStarted)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(WelcomeOrderScreen.upKey(WelcomeItemId.getStarted)),
    );
    await tester.pumpAndSettle();

    expect(WelcomeLayout.order.value, WelcomeLayout.defaultOrder);
  });
}
