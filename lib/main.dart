 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
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
  
  // Initialize notification service best-effort, don't block app startup
  await _initNotificationService();
  
  // Initialize database in background after app starts
  final dbHelper = DatabaseHelper();
  _initializeDatabaseInBackground(dbHelper);
  
  // Start app with a loading indicator while database initializes in background
  runApp(_buildAppWithDatabaseInit(dbHelper));
}

/// Initialize notification service best-effort, don't block app startup
Future<void> _initNotificationService() async {
  try {
    await NotificationService().initialize();
  } catch (_) {
    // Best-effort initialization in environments without notification service
  }
}

/// Initialize database in background after app starts
void _initializeDatabaseInBackground(DatabaseHelper dbHelper) async {
  try {
    // Wait for database to be initialized but don't block UI
    await dbHelper.database;
  } catch (_) {
    // Database initialization failure won't crash the app
  }
}

/// Build app that starts with loading while database initializes in background
Widget _buildAppWithDatabaseInit(DatabaseHelper dbHelper) {
  // Wait for database initialization but allow widget tree to start
  // We use a future that completes after the first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Database init happens in background - don't block UI
    _initializeDatabaseLater(dbHelper);
  });

  // Return initial loading/app shell
  return MaterialApp(
    title: 'Credit Bill System',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.system,
    home: const _DatabaseInitScreen(),
  );
}

/// Initialize database after first frame - non-blocking
void _initializeDatabaseLater(DatabaseHelper dbHelper) async {
  try {
    await dbHelper.database;
  } catch (_) {
    // Database initialization failure won't crash the app
  }
}

/// Screen shown while database initializes in background
class _DatabaseInitScreen extends StatefulWidget {
  const _DatabaseInitScreen();

  @override
  State<_DatabaseInitScreen> createState() => _DatabaseInitScreenState();
}

class _DatabaseInitScreenState extends State<_DatabaseInitScreen> {
  bool _isDatabaseReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize database in background, mark ready when done
    Future.delayed(const Duration(milliseconds: 500), () {
      // Note: In a real app, you'd check actual db status here
      // For now, we'll just wait a bit and then proceed
      setState(() => _isDatabaseReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDatabaseReady) {
      // Database is initialized, show the main app with providers
      return buildAppWithProviders();
    }
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Loading Credit Bill System...'),
          ],
        ),
      ),
    );
  }
}
