/// App-level settings persisted locally.
class AppSettings {
  static const String logoPathKey = 'logo_path';
  static const String welcomeOrderKey = 'welcome_order';
  static const String bankNameKey = 'bank_name';

  final String? logoPath;
  final String? bankName;

  const AppSettings({this.logoPath, this.bankName});

  AppSettings copyWith({
    String? logoPath,
    bool clearLogoPath = false,
    String? bankName,
    bool clearBankName = false,
  }) {
    return AppSettings(
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      bankName: clearBankName ? null : (bankName ?? this.bankName),
    );
  }
}
