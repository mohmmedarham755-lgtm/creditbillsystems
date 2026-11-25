import 'dart:io';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:creditbillsytems/core/constants/app_version.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/domain/bill_model.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_status.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/payments/domain/payment_model.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';
import 'package:creditbillsytems/features/settings/domain/app_settings.dart';
import 'package:creditbillsytems/features/settings/domain/settings_repository.dart';
import 'package:creditbillsytems/features/settings/presentation/about_page.dart';
import 'package:creditbillsytems/features/settings/presentation/admin_help_settings_screen.dart';
import 'package:creditbillsytems/features/settings/presentation/admin_logo_input_page.dart';
import 'package:creditbillsytems/features/settings/presentation/app_version_page.dart';
import 'package:creditbillsytems/features/settings/presentation/contact_details_page.dart';
import 'package:creditbillsytems/features/settings/presentation/history_page.dart';
import 'package:creditbillsytems/features/settings/presentation/logout_confirmation_page.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;
  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();
  @override
  Future<UserModel?> getCurrentUser() async => null;
  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) => throw UnimplementedError();
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
  @override
  Future<void> signOut() async {}
}

class _FakeBillRepository implements BillRepository {
  @override
  Future<BillModel> createBill({
    required String userId,
    required BillModel bill,
  }) async => bill;
  @override
  Future<BillModel?> getBill({
    required String userId,
    required String billId,
  }) async => null;
  @override
  Future<List<BillModel>> getBills({required String userId}) async => const [];
  @override
  Stream<List<BillModel>> watchBills({required String userId}) async* {
    yield [
      BillModel(
        id: 'bill-1',
        cardId: 'card-1',
        statementDate: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 20),
        totalAmountDue: 1250,
        remainingBalance: 250,
        minimumDue: 50,
        status: BillStatus.partiallyPaid,
      ),
    ];
  }

  @override
  Future<void> updateBill({
    required String userId,
    required BillModel bill,
  }) async {}
  @override
  Future<void> deleteBill({
    required String userId,
    required String billId,
  }) async {}
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<PaymentModel> recordPayment({
    required String userId,
    required PaymentModel payment,
  }) async => payment;
  @override
  Future<PaymentModel?> getPayment({
    required String userId,
    required String paymentId,
  }) async => null;
  @override
  Future<List<PaymentModel>> getPayments({required String userId}) async =>
      const [];
  @override
  Stream<List<PaymentModel>> watchPayments({required String userId}) async* {
    yield [
      PaymentModel(
        id: 'payment-1',
        billId: 'bill-1',
        cardId: 'card-1',
        amount: 1000,
        date: DateTime(2026, 10, 10),
        note: 'Part payment',
      ),
    ];
  }

  @override
  Future<void> deletePayment({
    required String userId,
    required String paymentId,
  }) async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() async => const AppSettings();
  @override
  Future<void> saveLogoPath(String? logoPath) async {}
}

Widget _pageApp(Widget page) {
  return MaterialApp(home: page);
}

Future<void> _openLogoutPage(
  WidgetTester tester,
  Future<void> Function() onConfirm,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LogoutConfirmationPage(onConfirm: onConfirm),
                  ),
                );
              },
              child: const Text('Open logout'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open logout'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About and Contact pages render their content', (tester) async {
    await tester.pumpWidget(_pageApp(const AboutPage()));
    expect(find.byKey(const Key('about-page-content')), findsOneWidget);
    expect(find.text('What you can do'), findsOneWidget);

    await tester.pumpWidget(_pageApp(const ContactDetailsPage()));
    await tester.pump();
    expect(find.byKey(ContactDetailsPage.emailKey), findsOneWidget);
    expect(find.text(ContactDetailsPage.supportEmail), findsOneWidget);
    expect(find.text(ContactDetailsPage.supportPhone), findsOneWidget);
  });

  testWidgets('App Version page shows the configured version', (tester) async {
    await tester.pumpWidget(_pageApp(const AppVersionPage()));
    expect(find.byKey(AppVersionPage.versionKey), findsOneWidget);
    expect(find.text(appVersionLabel), findsOneWidget);
  });

  testWidgets('Logout confirmation confirms and cancels', (tester) async {
    var confirmCalls = 0;
    Future<void> onConfirm() async {
      confirmCalls++;
    }

    await _openLogoutPage(tester, onConfirm);
    await tester.tap(find.byKey(LogoutConfirmationPage.cancelKey));
    await tester.pumpAndSettle();
    expect(confirmCalls, 0);

    await _openLogoutPage(tester, onConfirm);
    await tester.tap(find.byKey(LogoutConfirmationPage.confirmKey));
    await tester.pumpAndSettle();
    expect(confirmCalls, 1);
  });

  testWidgets('Admin Logo Input page reuses logo upload without help text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageApp(
        AdminLogoInputPage(
          settingsRepository: _FakeSettingsRepository(),
          getAppDirectory: () async => Directory.systemTemp,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(AdminLogoInputPage.pageKey), findsOneWidget);
    expect(find.text('Admin Logo Input'), findsOneWidget);
    expect(find.byKey(AdminHelpSettingsScreen.uploadButtonKey), findsOneWidget);
    expect(find.text('Help & About'), findsNothing);
  });

  testWidgets('History page shows bills and payments for signed-in user', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: _FakeAuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'user-1', email: 'user@example.com');
    final billProvider = BillProvider(
      billRepository: _FakeBillRepository(),
      paymentRepository: _FakePaymentRepository(),
      authProvider: authProvider,
    );
    addTearDown(authProvider.dispose);
    addTearDown(billProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
        ],
        child: const MaterialApp(home: HistoryPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(HistoryPage.billsKey), findsOneWidget);
    expect(find.byKey(HistoryPage.paymentsKey), findsOneWidget);
    expect(find.text('Part payment'), findsOneWidget);
    expect(find.textContaining('1,250.00'), findsWidgets);
  });
}
