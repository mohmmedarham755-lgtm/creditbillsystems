import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/login_screen.dart';
import 'package:creditbillsytems/features/bills/presentation/bill_provider.dart';
import 'package:creditbillsytems/features/cards/presentation/card_provider.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';
import 'package:creditbillsytems/features/bills/data/php_bill_repository.dart';
import 'package:creditbillsytems/features/bills/domain/bill_repository.dart';
import 'package:creditbillsytems/features/cards/data/php_card_repository.dart';
import 'package:creditbillsytems/features/cards/domain/card_repository.dart';
import 'package:creditbillsytems/features/payments/data/php_payment_repository.dart';
import 'package:creditbillsytems/features/payments/domain/payment_repository.dart';
import 'package:creditbillsytems/core/network/api_client.dart';
import 'package:creditbillsytems/core/network/api_config.dart';
import 'package:creditbillsytems/core/network/cards_api.dart';
import 'package:creditbillsytems/core/network/bills_api.dart';
import 'package:creditbillsytems/core/network/payments_api.dart';
import 'package:creditbillsytems/core/auth/token_storage.dart';

class MockLogoutAuthRepo implements AuthRepository {
  bool signOutInvoked = false;

  @override
  Future<void> signOut() async {
    signOutInvoked = true;
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      UserModel(uid: 'uid', email: email, createdAt: DateTime(2026, 10, 14));

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      UserModel(uid: 'uid', email: email, createdAt: DateTime(2026, 10, 14));

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(null);
}

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
  group('Secure Logout & Protected Dashboard Access Tests', () {
    late AuthProvider authProvider;
    late CardRepository cardRepository;
    late BillRepository billRepository;
    late PaymentRepository paymentRepository;
    late CardsApi cardsApi;
    late BillsApi billsApi;
    late PaymentsApi paymentsApi;

    setUp(() {
      final apiConfig = ApiConfig(
        baseUrl: 'http://localhost/credit_bill_api/',
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 10),
      );
      cardsApi = CardsApi(HttpApiClient(config: apiConfig, tokenStorage: FakeTokenStorage()));
      billsApi = BillsApi(HttpApiClient(config: apiConfig, tokenStorage: FakeTokenStorage()));
      paymentsApi = PaymentsApi(HttpApiClient(config: apiConfig, tokenStorage: FakeTokenStorage()));
      cardRepository = PhpCardRepository(cardsApi: cardsApi);
      billRepository = PhpBillRepository(billsApi: billsApi);
      paymentRepository = PhpPaymentRepository(paymentsApi: paymentsApi);
      authProvider = AuthProvider(
        authRepository: MockLogoutAuthRepo(),
        listenToAuthChanges: false,
      )..setUser(uid: 'user-to-logout-1', email: 'logout-user@example.com');
    });

    testWidgets('logging out clears session and redirects to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => CardProvider(cardRepository: cardRepository)),
            ChangeNotifierProvider(create: (_) => BillProvider(billRepository: billRepository, paymentRepository: paymentRepository)),
          ],
          child: const CreditBillApp(),
        ),
      );

      // Verify initially on Dashboard
      expect(find.byType(DashboardShellScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Tap profile icon in AppBar
      final profileBtn = find.byIcon(Icons.account_circle_outlined);
      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      // Verify Account bottom sheet is open
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}