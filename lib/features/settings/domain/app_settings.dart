/// App-level settings persisted locally.
class AppSettings {
  static const String logoPathKey = 'logo_path';

  final String? logoPath;

  const AppSettings({this.logoPath});

  AppSettings copyWith({String? logoPath, bool clearLogoPath = false}) {
    return AppSettings(
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
    );
  }
}
