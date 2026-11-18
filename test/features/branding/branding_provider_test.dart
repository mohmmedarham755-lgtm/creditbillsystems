import 'dart:typed_data';

import 'package:creditbillsytems/app.dart';
import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/branding/domain/branding_repository.dart';
import 'package:creditbillsytems/features/branding/presentation/admin_logo_screen.dart';
import 'package:creditbillsytems/features/branding/presentation/app_logo_provider.dart';
import 'package:creditbillsytems/features/dashboard/presentation/dashboard_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MemoryBrandingRepository implements BrandingRepository {
  Uint8List? logo;

  @override
  Future<Uint8List?> getLogo() async => logo;

  @override
  Future<void> saveLogo(Uint8List bytes) async {
    logo = Uint8List.fromList(bytes);
  }
}

class _AuthRepository implements AuthRepository {
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

void main() {
  test('loads and saves the persisted logo', () async {
    final repository = _MemoryBrandingRepository()
      ..logo = Uint8List.fromList([1, 2]);
    final provider = AppLogoProvider(repository: repository);
    addTearDown(provider.dispose);

    await provider.loadLogo();
    expect(provider.logoBytes, orderedEquals([1, 2]));

    final saved = await provider.saveLogo(Uint8List.fromList([3, 4]));
    expect(saved, isTrue);
    expect(provider.logoBytes, orderedEquals([3, 4]));
    expect(repository.logo, orderedEquals([3, 4]));
  });

  testWidgets('only the seeded admin can open logo controls', (tester) async {
    final repository = _MemoryBrandingRepository();
    final logoProvider = AppLogoProvider(repository: repository);
    final authProvider = AuthProvider(
      authRepository: _AuthRepository(),
      listenToAuthChanges: false,
    );
    addTearDown(logoProvider.dispose);
    addTearDown(authProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AppLogoProvider>.value(value: logoProvider),
        ],
        child: const MaterialApp(home: AdminLogoScreen()),
      ),
    );

    expect(find.text('Admin access required.'), findsOneWidget);
    expect(find.byKey(const Key('admin-logo.choose')), findsNothing);

    authProvider.setUser(uid: 'admin', email: 'admin@gmail.com');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-logo.choose')), findsOneWidget);
    expect(find.text('Set Logo'), findsOneWidget);
  });

  testWidgets('admin account menu opens logo settings', (tester) async {
    final authProvider = AuthProvider(
      authRepository: _AuthRepository(),
      listenToAuthChanges: false,
    )..setUser(uid: 'admin', email: 'admin@gmail.com');
    final logoProvider = AppLogoProvider(
      repository: _MemoryBrandingRepository(),
    );
    addTearDown(authProvider.dispose);
    addTearDown(logoProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AppLogoProvider>.value(value: logoProvider),
        ],
        child: const CreditBillApp(home: DashboardShellScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Set or change the app logo'), findsOneWidget);

    await tester.tap(find.text('App Logo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-logo.choose')), findsOneWidget);
  });
}
