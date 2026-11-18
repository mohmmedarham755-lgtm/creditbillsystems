import 'dart:typed_data';

import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/branding/data/sqlite_branding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persists and replaces the app logo bytes', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE app_settings (
              setting_key TEXT PRIMARY KEY,
              value BLOB NOT NULL
            )
          ''');
        },
      ),
    );
    final helper = DatabaseHelper.withDatabase(db);
    final repository = SqliteBrandingRepository(databaseHelper: helper);
    addTearDown(() async {
      await helper.close();
      DatabaseHelper.resetInstance();
    });

    expect(await repository.getLogo(), isNull);

    await repository.saveLogo(Uint8List.fromList([4, 8, 15]));
    expect(await repository.getLogo(), orderedEquals([4, 8, 15]));

    await repository.saveLogo(Uint8List.fromList([16, 23, 42]));
    expect(await repository.getLogo(), orderedEquals([16, 23, 42]));
  });
}
