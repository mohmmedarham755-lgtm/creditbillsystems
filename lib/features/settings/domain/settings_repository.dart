import 'app_settings.dart';

/// Persistence contract for app-level settings.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<void> saveLogoPath(String? logoPath);
}
