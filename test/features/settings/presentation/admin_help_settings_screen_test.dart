import 'dart:convert';
import 'dart:io';

import 'package:creditbillsytems/features/settings/domain/app_settings.dart';
import 'package:creditbillsytems/features/settings/domain/settings_repository.dart';
import 'package:creditbillsytems/features/settings/presentation/admin_help_settings_screen.dart';
import 'package:creditbillsytems/features/settings/presentation/admin_logo_input_page.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

// 1x1 transparent PNG so Image.file can decode without scheduling endless
// retry frames in the widget-test environment.
final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZ+sAAAAASUVORK5CYII=',
);

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings;
  String? lastSavedLogoPath;
  bool shouldFailSave;
  bool shouldFailGet;
  int saveCalls = 0;
  int getCalls = 0;

  _FakeSettingsRepository({
    this.settings = const AppSettings(),
    this.shouldFailSave = false,
    this.shouldFailGet = false,
  });

  @override
  Future<AppSettings> getSettings() async {
    getCalls++;
    if (shouldFailGet) throw Exception('get failed');
    return settings;
  }

  @override
  Future<void> saveLogoPath(String? logoPath) async {
    saveCalls++;
    if (shouldFailSave) throw Exception('save failed');
    lastSavedLogoPath = logoPath;
    settings = AppSettings(logoPath: logoPath);
  }

  @override
  Future<List<String>?> getWelcomeOrder() async => null;

  @override
  Future<void> saveWelcomeOrder(List<String> order) async {}

  @override
  Future<String?> getBankName() async => null;

  @override
  Future<void> saveBankName(String? bankName) async {}
}

void main() {
  late Directory tempDir;
  late Directory appDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('settings_test_src_');
    appDir = Directory.systemTemp.createTempSync('settings_test_app_');
  });

  tearDown(() {
    for (final dir in [tempDir, appDir]) {
      if (dir.existsSync()) {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {
          // Best-effort cleanup; Windows may hold file handles briefly.
        }
      }
    }
  });

  XFile createTempXFile(String name) {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    file.writeAsBytesSync(_pngBytes);
    return XFile(file.path);
  }

  Future<void> pumpSettled(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Widget buildApp(
    _FakeSettingsRepository repo, {
    Future<XFile?> Function(ImageSource)? pickImage,
    Future<LostDataResponse> Function()? retrieveLostData,
    bool useRealImagePreview = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Help & Settings')),
        body: AdminHelpSettingsScreen(
          settingsRepository: repo,
          getAppDirectory: () async => appDir,
          pickImage: pickImage,
          retrieveLostData:
              retrieveLostData ?? () async => LostDataResponse.empty(),
          // Avoid real image decoding (and file locks) in ordinary widget
          // tests; the corrupt-file case opts into the real Image.file path.
          logoPreviewBuilder: useRealImagePreview
              ? null
              : (path) => SizedBox(
                  key: AdminHelpSettingsScreen.logoPreviewKey,
                  width: 120,
                  height: 120,
                ),
        ),
      ),
    );
  }

  testWidgets('renders help text and fallback when no logo is persisted', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository();

    await tester.pumpWidget(buildApp(repo));
    await pumpSettled(tester);

    expect(find.text('Help & Settings'), findsOneWidget);
    expect(find.text('Help & About'), findsOneWidget);
    expect(
      find.textContaining('Credit Bill System helps you track cards'),
      findsOneWidget,
    );
    expect(find.byKey(AdminHelpSettingsScreen.fallbackIconKey), findsOneWidget);
    expect(find.byKey(AdminHelpSettingsScreen.uploadButtonKey), findsOneWidget);
  });

  testWidgets('picking image copies file, persists path, and updates preview', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository();
    var pickCalls = 0;

    await tester.pumpWidget(
      buildApp(
        repo,
        pickImage: (_) async {
          pickCalls++;
          return createTempXFile('logo.png');
        },
      ),
    );
    await pumpSettled(tester);

    await tester.tap(find.byKey(AdminHelpSettingsScreen.uploadButtonKey));
    await pumpSettled(tester);

    expect(pickCalls, 1);
    expect(repo.saveCalls, 1);
    expect(repo.lastSavedLogoPath, isNotNull);
    expect(File(repo.lastSavedLogoPath!).existsSync(), isTrue);
    expect(
      repo.lastSavedLogoPath!,
      contains(
        '${Platform.pathSeparator}branding${Platform.pathSeparator}',
      ),
    );
    expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsOneWidget);
    expect(find.byKey(AdminHelpSettingsScreen.fallbackIconKey), findsNothing);
  });

  testWidgets('cancelled picker keeps existing logo unchanged', (
    tester,
  ) async {
    final existing = File(
      '${appDir.path}${Platform.pathSeparator}existing.png',
    );
    existing.writeAsBytesSync(_pngBytes);
    final repo = _FakeSettingsRepository(
      settings: AppSettings(logoPath: existing.path),
    );

    await tester.pumpWidget(buildApp(repo, pickImage: (_) async => null));
    await pumpSettled(tester);

    expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsOneWidget);

    await tester.tap(find.byKey(AdminHelpSettingsScreen.uploadButtonKey));
    await pumpSettled(tester);

    expect(repo.saveCalls, 0);
    expect(repo.settings.logoPath, existing.path);
    expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'copy/persist failure shows non-blocking error and keeps previous setting',
    (tester) async {
      final existing = File(
        '${appDir.path}${Platform.pathSeparator}existing.png',
      );
      existing.writeAsBytesSync(_pngBytes);
      final repo = _FakeSettingsRepository(
        settings: AppSettings(logoPath: existing.path),
        shouldFailSave: true,
      );

      await tester.pumpWidget(
        buildApp(repo, pickImage: (_) async => createTempXFile('new.png')),
      );
      await pumpSettled(tester);

      await tester.tap(find.byKey(AdminHelpSettingsScreen.uploadButtonKey));
      await pumpSettled(tester);

      expect(repo.saveCalls, 1);
      expect(repo.settings.logoPath, existing.path);
      expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsOneWidget);
      expect(
        find.text('Unable to update logo. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('missing persisted logo file shows fallback and no crash', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository(
      settings: AppSettings(
        logoPath: '${appDir.path}${Platform.pathSeparator}missing.png',
      ),
    );

    await tester.pumpWidget(buildApp(repo));
    await pumpSettled(tester);

    expect(find.byKey(AdminHelpSettingsScreen.fallbackIconKey), findsOneWidget);
    expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure shows error and retry reloads settings', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository(
      settings: const AppSettings(logoPath: 'initial.png'),
      shouldFailGet: true,
    );

    await tester.pumpWidget(buildApp(repo));
    await pumpSettled(tester);

    expect(find.text('Unable to load settings.'), findsOneWidget);
    expect(find.byKey(const Key('admin-settings-retry')), findsOneWidget);

    repo.shouldFailGet = false;
    repo.settings = AppSettings(
      logoPath: '${appDir.path}${Platform.pathSeparator}logo.png',
    );
    File(repo.settings.logoPath!).writeAsBytesSync(_pngBytes);

    await tester.tap(find.byKey(const Key('admin-settings-retry')));
    await pumpSettled(tester);

    expect(repo.getCalls, 2);
    expect(find.text('Unable to load settings.'), findsNothing);
    expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsOneWidget);
  });

  testWidgets('real image preview configures the fallback error builder', (
    tester,
  ) async {
    final logo = File('${appDir.path}${Platform.pathSeparator}logo.png');
    logo.writeAsBytesSync(_pngBytes);
    final repo = _FakeSettingsRepository(
      settings: AppSettings(logoPath: logo.path),
    );

    await tester.pumpWidget(buildApp(repo, useRealImagePreview: true));
    await pumpSettled(tester);

    final previewFinder = find.byKey(AdminHelpSettingsScreen.logoPreviewKey);
    final image = tester.widget<Image>(previewFinder);
    final errorBuilder = image.errorBuilder;
    expect(errorBuilder, isNotNull);

    final fallback = errorBuilder!(
      tester.element(previewFinder),
      Exception('decode failed'),
      StackTrace.current,
    );
    expect(fallback, isA<Container>());
    expect(
      (fallback as Container).key,
      AdminHelpSettingsScreen.fallbackIconKey,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovers lost image when picker returns null on Android resume', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository();
    final lostFile = createTempXFile('lost.png');
    var lostCalls = 0;

    await tester.pumpWidget(
      buildApp(
        repo,
        pickImage: (_) async => null,
        retrieveLostData: () async {
          lostCalls++;
          return lostCalls == 1
              ? LostDataResponse.empty()
              : LostDataResponse(file: lostFile, type: RetrieveType.image);
        },
      ),
    );
    await pumpSettled(tester);

    await tester.tap(find.byKey(AdminHelpSettingsScreen.uploadButtonKey));
    await pumpSettled(tester);

    expect(repo.saveCalls, 1);
    expect(repo.lastSavedLogoPath, isNotNull);
    expect(File(repo.lastSavedLogoPath!).existsSync(), isTrue);
    expect(find.byKey(AdminHelpSettingsScreen.logoPreviewKey), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Admin Logo Input page shows upload help above the uploader', (
    tester,
  ) async {
    final repo = _FakeSettingsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AdminLogoInputPage(
          settingsRepository: repo,
          getAppDirectory: () async => appDir,
          retrieveLostData: () async => LostDataResponse.empty(),
          logoPreviewBuilder: (_) => const SizedBox(
            key: AdminHelpSettingsScreen.logoPreviewKey,
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
    await pumpSettled(tester);

    expect(find.byKey(AdminLogoInputPage.pageKey), findsOneWidget);
    expect(find.byKey(AdminHelpSettingsScreen.logoHelpKey), findsOneWidget);
    expect(find.text('Logo upload help'), findsOneWidget);
    expect(find.textContaining('Choose a clear image'), findsOneWidget);
    expect(find.byKey(AdminHelpSettingsScreen.uploadButtonKey), findsOneWidget);

    final helpRect = tester.getRect(
      find.byKey(AdminHelpSettingsScreen.logoHelpKey),
    );
    final uploadRect = tester.getRect(
      find.byKey(AdminHelpSettingsScreen.uploadButtonKey),
    );
    expect(helpRect.bottom, lessThan(uploadRect.top));
  });
}
