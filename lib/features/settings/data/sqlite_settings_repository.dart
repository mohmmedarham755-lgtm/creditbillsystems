import 'package:creditbillsytems/core/database/database_helper.dart';
import 'package:creditbillsytems/features/settings/domain/app_settings.dart';
import 'package:creditbillsytems/features/settings/domain/settings_repository.dart';
import 'package:creditbillsytems/features/settings/domain/welcome_layout.dart';

/// SQLite implementation of [SettingsRepository].
class SqliteSettingsRepository implements SettingsRepository {
  final DatabaseHelper _dbHelper;

  SqliteSettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<AppSettings> getSettings() async {
    final logoPath = await _dbHelper.getAppSetting(AppSettings.logoPathKey);
    final bankName = await _dbHelper.getAppSetting(AppSettings.bankNameKey);
    return AppSettings(logoPath: logoPath, bankName: bankName);
  }

  @override
  Future<void> saveLogoPath(String? logoPath) async {
    await _dbHelper.saveAppSetting(AppSettings.logoPathKey, logoPath);
  }

  @override
  Future<List<String>?> getWelcomeOrder() async {
    final raw = await _dbHelper.getAppSetting(AppSettings.welcomeOrderKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return WelcomeLayout.normalize(raw.split(','));
  }

  @override
  Future<void> saveWelcomeOrder(List<String> order) async {
    final normalized = WelcomeLayout.normalize(order);
    await _dbHelper.saveAppSetting(
      AppSettings.welcomeOrderKey,
      normalized.join(','),
    );
  }

  @override
  Future<String?> getBankName() async {
    return _dbHelper.getAppSetting(AppSettings.bankNameKey);
  }

  @override
  Future<void> saveBankName(String? bankName) async {
    await _dbHelper.saveAppSetting(AppSettings.bankNameKey, bankName);
  }
}
