import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/settings/domain/app_settings.dart';
import 'package:creditbillsytems/features/settings/domain/settings_repository.dart';

/// SQLite implementation of [SettingsRepository].
class SqliteSettingsRepository implements SettingsRepository {
  final DatabaseHelper _dbHelper;

  SqliteSettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<AppSettings> getSettings() async {
    final logoPath = await _dbHelper.getAppSetting(AppSettings.logoPathKey);
    return AppSettings(logoPath: logoPath);
  }

  @override
  Future<void> saveLogoPath(String? logoPath) async {
    await _dbHelper.saveAppSetting(AppSettings.logoPathKey, logoPath);
  }
}
