// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:creditbillsytems/features/auth/domain/auth_repository.dart';
import 'package:creditbillsytems/features/auth/domain/user_model.dart';
import 'package:creditbillsytems/features/auth/presentation/auth_provider.dart';
import 'package:creditbillsytems/features/auth/presentation/login_screen.dart';
import 'package:creditbillsytems/features/settings/domain/app_settings.dart';
import 'package:creditbillsytems/features/settings/domain/settings_repository.dart';
import 'package:creditbillsytems/features/settings/presentation/about_page.dart';
import 'package:creditbillsytems/features/settings/presentation/admin_help_settings_screen.dart';
import 'package:creditbillsytems/features/settings/presentation/admin_logo_input_page.dart';
import 'package:creditbillsytems/features/settings/presentation/app_version_page.dart';
import 'package:creditbillsytems/features/settings/presentation/contact_details_page.dart';
import 'package:creditbillsytems/features/settings/presentation/logout_confirmation_page.dart';
import 'package:creditbillsytems/features/settings/presentation/settings_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  bool failSignOut = false;
  int signOutCalls = 0;

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
  Future<void> signOut() async {
    signOutCalls++;
    if (failSignOut) throw StateError('sign-out failed');
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() async => const AppSettings();

  @override
  Future<void> saveLogoPath(String? logoPath) async {}
}

AuthProvider _signedInAuthProvider({bool failSignOut = false}) {
  return AuthProvider(
    authRepository: _FakeAuthRepository()..failSignOut = failSignOut,
    listenToAuthChanges: false,
  )..setUser(uid: 'non-admin-1', email: 'user@example.com');
}

Widget _hubApp(
  AuthProvider authProvider, {
  SettingsRepository? settingsRepository,
  bool provideSettingsRepository = true,
}) {
  return MultiProvider(
    providers: [
      if (provideSettingsRepository)
        Provider<SettingsRepository?>.value(
          value: settingsRepository ?? _FakeSettingsRepository(),
        ),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      home: const Scaffold(body: SettingsScreen()),
      routes: {'/login': (_) => const LoginScreen()},
    ),
  );
}

Future<void> _openEntryAndExpect(
  WidgetTester tester,
  Key entryKey,
  Finder destination,
) async {
  await tester.tap(find.byKey(entryKey));
  await tester.pumpAndSettle();
  expect(destination, findsOneWidget);

  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
  expect(find.byKey(SettingsScreen.screenKey), findsOneWidget);
}

void main() {
  testWidgets('hub lists all six destinations for a non-admin user', (
    tester,
  ) async {
    final auth = _signedInAuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth));

    expect(find.byKey(SettingsScreen.screenKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.adminEntryKey), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.byKey(SettingsScreen.helpSettingsEntryKey), findsOneWidget);
    expect(find.text('Help & Settings'), findsOneWidget);
    expect(find.byKey(SettingsScreen.aboutEntryKey), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.byKey(SettingsScreen.contactEntryKey), findsOneWidget);
    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.byKey(SettingsScreen.versionEntryKey), findsOneWidget);
    expect(find.text('App Version'), findsOneWidget);
    expect(find.byKey(SettingsScreen.logoutEntryKey), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('each entry opens its existing page and returns to the hub', (
    tester,
  ) async {
    final auth = _signedInAuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth));

    await _openEntryAndExpect(
      tester,
      SettingsScreen.adminEntryKey,
      find.byKey(AdminLogoInputPage.pageKey),
    );

    await _openEntryAndExpect(
      tester,
      SettingsScreen.helpSettingsEntryKey,
      find.byKey(AdminHelpSettingsScreen.uploadButtonKey),
    );

    await _openEntryAndExpect(
      tester,
      SettingsScreen.aboutEntryKey,
      find.byKey(AboutPage.contentKey),
    );

    await _openEntryAndExpect(
      tester,
      SettingsScreen.contactEntryKey,
      find.byKey(ContactDetailsPage.emailKey),
    );

    await _openEntryAndExpect(
      tester,
      SettingsScreen.versionEntryKey,
      find.byKey(AppVersionPage.versionKey),
    );

    await _openEntryAndExpect(
      tester,
      SettingsScreen.logoutEntryKey,
      find.byKey(LogoutConfirmationPage.confirmKey),
    );
  });

  testWidgets('help page admin link still opens the logo input page', (
    tester,
  ) async {
    final auth = _signedInAuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth));
    await tester.tap(find.byKey(SettingsScreen.helpSettingsEntryKey));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-logo-input-link')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-logo-input-link')));
    await tester.pumpAndSettle();

    expect(find.byKey(AdminLogoInputPage.pageKey), findsOneWidget);
    expect(find.text('Admin Logo Input'), findsOneWidget);
  });

  testWidgets('repository-unavailable path shows a message instead of crashing', (
    tester,
  ) async {
    final auth = _signedInAuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth, provideSettingsRepository: false));

    expect(find.byKey(SettingsScreen.adminEntryKey), findsOneWidget);
    await tester.tap(find.byKey(SettingsScreen.adminEntryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Settings are unavailable right now.'), findsOneWidget);
    expect(find.byKey(AdminLogoInputPage.pageKey), findsNothing);

    await tester.tap(find.byKey(SettingsScreen.helpSettingsEntryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(AdminHelpSettingsScreen.uploadButtonKey), findsNothing);
    expect(find.byType(SnackBar), findsWidgets);
  });

  testWidgets('cancelling logout keeps the user signed in', (tester) async {
    final auth = _signedInAuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth));
    await tester.tap(find.byKey(SettingsScreen.logoutEntryKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogoutConfirmationPage.cancelKey));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isTrue);
    expect(find.byKey(SettingsScreen.screenKey), findsOneWidget);
    expect(find.byKey(LogoutConfirmationPage.confirmKey), findsNothing);
  });

  testWidgets('confirming logout clears session and redirects to login', (
    tester,
  ) async {
    final auth = _signedInAuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth));
    await tester.tap(find.byKey(SettingsScreen.logoutEntryKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogoutConfirmationPage.confirmKey));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(SettingsScreen.screenKey), findsNothing);
  });

  testWidgets('failed logout shows error and does not redirect', (tester) async {
    final auth = _signedInAuthProvider(failSignOut: true);
    addTearDown(auth.dispose);

    await tester.pumpWidget(_hubApp(auth));
    await tester.tap(find.byKey(SettingsScreen.logoutEntryKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogoutConfirmationPage.confirmKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(auth.isAuthenticated, isTrue);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Logout failed. Please try again.'), findsOneWidget);
  });
}
