
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    print('DBG_DB: opened in setUpAll');
  });

  tearDownAll(() async {
    await db.close();
    print('DBG_DB: closed in tearDownAll');
  });

  testWidgets('db then trivial widget', (tester) async {
    print('DBG_DB: pumping');
    await tester.pumpWidget(const MaterialApp(home: Text('hello')));
    print('DBG_DB: pumped');
    expect(find.text('hello'), findsOneWidget);
  });
}
