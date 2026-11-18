import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../domain/branding_repository.dart';

class SqliteBrandingRepository implements BrandingRepository {
  static const _logoSettingKey = 'app_logo';

  final DatabaseHelper _databaseHelper;

  const SqliteBrandingRepository({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  @override
  Future<Uint8List?> getLogo() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'setting_key = ?',
      whereArgs: [_logoSettingKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final value = rows.first['value'];
    if (value is Uint8List) return Uint8List.fromList(value);
    if (value is List<int>) return Uint8List.fromList(value);
    throw StateError('The saved app logo is not stored as image bytes.');
  }

  @override
  Future<void> saveLogo(Uint8List bytes) async {
    final db = await _databaseHelper.database;
    await db.insert('app_settings', {
      'setting_key': _logoSettingKey,
      'value': Uint8List.fromList(bytes),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
