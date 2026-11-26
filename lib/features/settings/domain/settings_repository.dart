import 'app_settings.dart';

/// Persistence contract for app-level settings.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<void> saveLogoPath(String? logoPath);

  /// Stored welcome action order, or `null` when never customized.
  Future<List<String>?> getWelcomeOrder();

  Future<void> saveWelcomeOrder(List<String> order);

  /// Default bank name offered when setting up a new card, or `null`.
  Future<String?> getBankName();

  Future<void> saveBankName(String? bankName);
}
