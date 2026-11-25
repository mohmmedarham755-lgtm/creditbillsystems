import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/settings/data/sqlite_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('SQLite settings repository round-trips the persisted logo path', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    final repository = SqliteSettingsRepository(
      dbHelper: DatabaseHelper.withDatabase(db),
    );

    expect((await repository.getSettings()).logoPath, isNull);

    const logoPath = '/app/documents/branding/logo.png';
    await repository.saveLogoPath(logoPath);

    // A fresh repository/helper pair models the next app session reading the
    // same database file; the path must come back from SQLite, not UI state.
    final nextSession = SqliteSettingsRepository(
      dbHelper: DatabaseHelper.withDatabase(db),
    );
    expect((await nextSession.getSettings()).logoPath, logoPath);

    await nextSession.saveLogoPath(null);
    expect((await repository.getSettings()).logoPath, isNull);
  });

  test(
    'SQLite settings repository reads/writes on legacy v2 setting_key schema',
    () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE app_settings (
                setting_key TEXT PRIMARY KEY,
                value BLOB NOT NULL
              );
            ''');
            await db.insert('app_settings', {
              'setting_key': 'logo_path',
              'value': '/legacy/logo.png',
            });
          },
        ),
      );
      addTearDown(() async => db.close());

      final repository = SqliteSettingsRepository(
        dbHelper: DatabaseHelper.withDatabase(db),
      );

      expect((await repository.getSettings()).logoPath, '/legacy/logo.png');

      await repository.saveLogoPath('/legacy/new-logo.png');
      expect((await repository.getSettings()).logoPath, '/legacy/new-logo.png');

      final columns = await db.rawQuery('PRAGMA table_info(app_settings);');
      final names = columns.map((c) => c['name']).toSet();
      expect(names, containsAll(<String>{'key', 'value'}));
      expect(names, isNot(contains('setting_key')));
    },
  );
}
