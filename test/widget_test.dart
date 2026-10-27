import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';
import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/api_config.dart';
import 'package:creditbillsytems/core/network/auth_api.dart';
import 'package:creditbillsytems/core/network/cards_api.dart';
import 'package:creditbillsytems/core/network/bills_api.dart';
import 'package:creditbillsytems/core/network/payments_api.dart';
import 'package:creditbillsytems/features/auth/data/php_auth_repository.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/bills/data/php_bill_repository.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/data/php_card_repository.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/payments/data/php_payment_repository.dart';

// Fake implementations for testing
class FakeTokenStorage implements TokenStorage {
  String? _token;
  String? _userId;
  DateTime? _expiresAt;

  @override
  Future<void> saveToken(String token, String userId, DateTime expiresAt) async {
    _token = token;
    _userId = userId;
    _expiresAt = expiresAt;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<String?> getUserId() async => _userId;

  @override
  Future<DateTime?> getExpiresAt() async => _expiresAt;

  @override
  Future<void> clear() async {
    _token = null;
    _userId = null;
    _expiresAt = null;
  }

  @override
  Future<bool> isTokenValid() async {
    if (_token == null || _token!.isEmpty) return false;
    if (_expiresAt == null) return false;
    return DateTime.now().add(const Duration(minutes: 5)).isBefore(_expiresAt!);
  }
}

void main() {
  testWidgets('CreditBillApp bootstrap and navigation smoke test', (
    WidgetTester tester,
  ) async {
    // Set up PHP backend services for testing
    final apiConfig = ApiConfig(
      baseUrl: 'http://localhost/credit_bill_api/',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 10),
    );
    final tokenStorage = FakeTokenStorage();
    final apiClient = HttpApiClient(config: apiConfig, tokenStorage: tokenStorage);

    final authApi = AuthApi(apiClient);
    final cardsApi = CardsApi(apiClient);
    final billsApi = BillsApi(apiClient);
    final paymentsApi = PaymentsApi(apiClient);

    final authRepository = PhpAuthRepository(authApi: authApi, tokenStorage: FakeTokenStorage());
    final cardRepository = PhpCardRepository(cardsApi: cardsApi);
    final billRepository = PhpBillRepository(billsApi: billsApi);
    final paymentRepository = PhpPaymentRepository(paymentsApi: paymentsApi);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(
                  authRepository: authRepository,
                  listenToAuthChanges: false,
                )
                  ..setUser(uid: 'smoke-test-uid', email: 'smoke@example.com'),
          ),
          ChangeNotifierProvider(create: (_) => CardProvider(cardRepository: cardRepository)),
          ChangeNotifierProvider(
              create: (_) => BillProvider(
                  billRepository: billRepository,
                  paymentRepository: paymentRepository)),
        ],
        child: const CreditBillApp(),
      ),
    );

    // Verify App Bar
    expect(find.text('Credit Bill System'), findsOneWidget);

    // Verify Bottom Navigation Bar Destinations
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Dashboard'),
      findsNWidgets(2),
    ); // heading and nav destination
    expect(find.text('Your cards'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Tap on Bills tab
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();

    // Verify Bills tab is displayed
    expect(find.text('Log Bill'), findsOneWidget);

    // Tap on Calendar tab
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // Verify Calendar tab is displayed
    expect(find.text('Calendar storage is unavailable.'), findsOneWidget);
  });
}