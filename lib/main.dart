import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/auth/token_storage_impl.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/sqlite_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/bills/data/sqlite_bill_repository.dart';
import 'features/bills/domain/bill_repository.dart';
import 'features/bills/presentation/bill_provider.dart';
import 'features/cards/data/sqlite_card_repository.dart';
import 'features/cards/domain/card_repository.dart';
import 'features/cards/presentation/card_provider.dart';
import 'features/payments/data/sqlite_payment_repository.dart';
import 'features/payments/domain/payment_repository.dart';
import 'features/calendar/data/calendar_repository_impl.dart';
import 'features/calendar/presentation/calendar_provider.dart';

Widget buildAppWithProviders({
  Widget child = const CreditBillApp(),
  AuthProvider? authProvider,
  AuthRepository? authRepository,
  CardRepository? cardRepository,
  BillRepository? billRepository,
  PaymentRepository? paymentRepository,
  DatabaseHelper? dbHelper,
}) {
  final helper = dbHelper ?? DatabaseHelper();
  final tokenStorage = TokenStorageImpl();

  final authRepo = authRepository ??
      SqliteAuthRepository(dbHelper: helper, tokenStorage: tokenStorage);
  final cardRepo = cardRepository ?? SqliteCardRepository(dbHelper: helper);
  final billRepo = billRepository ?? SqliteBillRepository(dbHelper: helper);
  final paymentRepo = paymentRepository ??
      SqlitePaymentRepository(
        dbHelper: helper,
        onDataMutated: (userId) {
          if (billRepo is SqliteBillRepository) {
            billRepo.notifyWatchers(userId);
          }
        },
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => authProvider ?? AuthProvider(authRepository: authRepo),
      ),
      ChangeNotifierProxyProvider<AuthProvider, CardProvider>(
        create: (_) => CardProvider(cardRepository: cardRepo),
        update: (_, auth, cards) {
          final cardProvider = cards ?? CardProvider(cardRepository: cardRepo);
          cardProvider.bindAuthProvider(auth);
          return cardProvider;
        },
      ),
      ChangeNotifierProxyProvider<AuthProvider, BillProvider>(
        create: (_) => BillProvider(
          billRepository: billRepo,
          paymentRepository: paymentRepo,
        ),
        update: (_, auth, bills) {
          final billProvider = bills ??
              BillProvider(
                billRepository: billRepo,
                paymentRepository: paymentRepo,
              );
          billProvider.bindAuthProvider(auth);
          return billProvider;
        },
      ),
      ChangeNotifierProxyProvider<AuthProvider, CalendarProvider>(
        create: (_) => CalendarProvider(
          repository: CalendarRepositoryImpl(billRepository: billRepo),
        ),
        update: (_, auth, calendar) {
          final provider = calendar ??
              CalendarProvider(
                repository: CalendarRepositoryImpl(billRepository: billRepo),
              );
          provider.bindAuthProvider(auth);
          return provider;
        },
      ),
    ],
    child: child,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().initialize();
  } catch (_) {
    // Best-effort initialization in environments without notification service
  }
  runApp(buildAppWithProviders());
}
