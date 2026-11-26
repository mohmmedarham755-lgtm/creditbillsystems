import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app.dart';
import 'core/auth/admin_initializer.dart';
import 'core/auth/token_storage_impl.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/sqlite_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/bills/data/sqlite_bill_repository.dart';
import 'features/bills/domain/bill_repository.dart';
import 'features/bills/presentation/bill_provider.dart';
import 'features/calendar/data/calendar_repository_impl.dart';
import 'features/calendar/presentation/calendar_provider.dart';
import 'features/cards/data/sqlite_card_repository.dart';
import 'features/cards/domain/card_repository.dart';
import 'features/cards/presentation/card_provider.dart';
import 'features/payments/data/sqlite_payment_repository.dart';
import 'features/payments/domain/payment_repository.dart';
import 'features/settings/data/sqlite_settings_repository.dart';
import 'features/settings/domain/settings_repository.dart';
import 'features/settings/domain/welcome_layout.dart';
import 'welcome_screen.dart';

Widget buildAppWithProviders({
  Widget child = const CreditBillApp(),
  AuthProvider? authProvider,
  AuthRepository? authRepository,
  CardRepository? cardRepository,

  BillRepository? billRepository,
  PaymentRepository? paymentRepository,
  SettingsRepository? settingsRepository,
  DatabaseHelper? dbHelper,
}) {
  final helper = dbHelper ?? DatabaseHelper();
  final tokenStorage = TokenStorageImpl();

  final authRepo =
      authRepository ??
      SqliteAuthRepository(dbHelper: helper, tokenStorage: tokenStorage);
  final cardRepo = cardRepository ?? SqliteCardRepository(dbHelper: helper);
  final billRepo = billRepository ?? SqliteBillRepository(dbHelper: helper);
  final paymentRepo =
      paymentRepository ??
      SqlitePaymentRepository(
        dbHelper: helper,
        onDataMutated: (userId) {
          if (billRepo is SqliteBillRepository) {
            billRepo.notifyWatchers(userId);
          }
        },
      );
  final settingsRepo =
      settingsRepository ?? SqliteSettingsRepository(dbHelper: helper);

  return MultiProvider(
    providers: [
      Provider<SettingsRepository>.value(value: settingsRepo),
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
          final billProvider =
              bills ??
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
          final provider =
              calendar ??
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite factory for Flutter Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize notification service
  await _initNotificationService();

  // Initialize database before starting the app
  final dbHelper = DatabaseHelper();

  await dbHelper.database;

  // Initialize admin account
  final tokenStorage = TokenStorageImpl();
  await ensureAdminAccount(dbHelper, tokenStorage);

  // Restore any customized welcome page action order.
  await WelcomeLayout.load(SqliteSettingsRepository(dbHelper: dbHelper));

  // Start application
  runApp(
    buildAppWithProviders(
      dbHelper: dbHelper,
      child: const CreditBillApp(home: WelcomeScreen()),
    ),
  );
}

/// Initialize notification service best-effort, don't block app startup
Future<void> _initNotificationService() async {
  try {
    await NotificationService().initialize();
  } catch (_) {
    // Best-effort initialization in environments without notification service
  }
}
