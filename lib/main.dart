import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/auth/token_storage.dart';
import 'core/auth/token_storage_impl.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/network/auth_api.dart';
import 'core/network/cards_api.dart';
import 'core/network/bills_api.dart';
import 'core/network/payments_api.dart';
import 'features/auth/data/php_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/bills/data/php_bill_repository.dart';
import 'features/bills/domain/bill_repository.dart';
import 'features/bills/presentation/bill_provider.dart';
import 'features/cards/data/php_card_repository.dart';
import 'features/cards/domain/card_repository.dart';
import 'features/cards/presentation/card_provider.dart';
import 'features/payments/data/php_payment_repository.dart';
import 'features/payments/domain/payment_repository.dart';

Widget buildAppWithProviders({
  Widget child = const CreditBillApp(),
  AuthProvider? authProvider,
  CardRepository? cardRepository,
  BillRepository? billRepository,
  PaymentRepository? paymentRepository,
}) {
  // Initialize PHP backend services
  final apiConfig = ApiConfig.platform();
  final tokenStorage = TokenStorageImpl();
  final apiClient = HttpApiClient(config: apiConfig, tokenStorage: tokenStorage);
  
  final authApi = AuthApi(apiClient);
  final cardsApi = CardsApi(apiClient);
  final billsApi = BillsApi(apiClient);
  final paymentsApi = PaymentsApi(apiClient);
  
  final authRepo = PhpAuthRepository(authApi: authApi, tokenStorage: tokenStorage);
  final cardRepo = cardRepository ?? PhpCardRepository(cardsApi: cardsApi);
  final billRepo = billRepository ?? PhpBillRepository(billsApi: billsApi);
  final paymentRepo = paymentRepository ?? PhpPaymentRepository(paymentsApi: paymentsApi);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => authProvider ?? AuthProvider(authRepository: authRepo)),
      ChangeNotifierProxyProvider<AuthProvider, CardProvider>(
        create: (_) => CardProvider(cardRepository: cardRepo),
        update: (_, auth, cards) {
          final cardProvider = cards ?? CardProvider(cardRepository: cardRepo);
          cardProvider.bindAuthProvider(auth);
          return cardProvider;
        },
      ),
      ChangeNotifierProvider(create: (_) => BillProvider(billRepository: billRepo, paymentRepository: paymentRepo)),
    ],
    child: child,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(buildAppWithProviders());
}