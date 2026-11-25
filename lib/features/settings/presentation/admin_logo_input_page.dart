// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../domain/settings_repository.dart';
import 'admin_help_settings_screen.dart';

/// Dedicated page for uploading or replacing the settings-page logo.
class AdminLogoInputPage extends StatelessWidget {
  const AdminLogoInputPage({
    super.key,
    required this.settingsRepository,
    this.pickImage,
    this.retrieveLostData,
    this.getAppDirectory,
    this.logoPreviewBuilder,
  });

  final SettingsRepository settingsRepository;
  final ImagePickCallback? pickImage;
  final LostDataCallback? retrieveLostData;
  final AppDirectoryCallback? getAppDirectory;
  final LogoPreviewBuilder? logoPreviewBuilder;

  static const Key pageKey = Key('admin-logo-input-page');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Logo Input')),
      body: KeyedSubtree(
        key: pageKey,
        child: AdminHelpSettingsScreen(
          settingsRepository: settingsRepository,
          showHelpSection: false,
          showLogoHelp: true,
          pickImage: pickImage,
          retrieveLostData: retrieveLostData,
          getAppDirectory: getAppDirectory,
          logoPreviewBuilder: logoPreviewBuilder,
        ),
      ),
    );
  }
}
