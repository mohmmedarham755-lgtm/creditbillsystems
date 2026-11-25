// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/settings_repository.dart';
import 'about_page.dart';
import 'admin_help_settings_screen.dart';
import 'admin_logo_input_page.dart';
import 'app_version_page.dart';
import 'contact_details_page.dart';
import 'logout_confirmation_page.dart';

/// Dedicated account and information hub shown by the Settings tab.
///
/// The hub owns no AppBar so it can live inside the dashboard shell without
/// duplicating the shell's title bar. Every destination is an existing page;
/// this screen only provides navigation to them.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onLogoChanged});

  /// Called after a page that can change the stored logo is popped.
  final VoidCallback? onLogoChanged;

  static const Key screenKey = Key('settings-screen');
  static const Key adminEntryKey = Key('admin-page-tile');
  static const Key helpSettingsEntryKey = Key('help-settings-tile');
  static const Key aboutEntryKey = Key('about-page-tile');
  static const Key contactEntryKey = Key('contact-details-tile');
  static const Key versionEntryKey = Key('app-version-page-tile');
  static const Key logoutEntryKey = Key('logout-confirmation-tile');

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: screenKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _SettingsEntry(
          entryKey: adminEntryKey,
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin',
          subtitle: 'Upload or replace the app logo',
          onTap: () => _openAdmin(context),
        ),
        const Divider(height: 1),
        _SettingsEntry(
          entryKey: helpSettingsEntryKey,
          icon: Icons.settings_outlined,
          title: 'Help & Settings',
          onTap: () => _openHelpSettings(context),
        ),
        const Divider(height: 1),
        _SettingsEntry(
          entryKey: aboutEntryKey,
          icon: Icons.info_outlined,
          title: 'About',
          onTap: () => _pushPage(context, const AboutPage()),
        ),
        const Divider(height: 1),
        _SettingsEntry(
          entryKey: contactEntryKey,
          icon: Icons.contact_support_outlined,
          title: 'Contact Details',
          onTap: () => _pushPage(context, const ContactDetailsPage()),
        ),
        const Divider(height: 1),
        _SettingsEntry(
          entryKey: versionEntryKey,
          icon: Icons.code,
          title: 'App Version',
          onTap: () => _pushPage(context, const AppVersionPage()),
        ),
        const Divider(height: 1),
        _SettingsEntry(
          entryKey: logoutEntryKey,
          icon: Icons.logout,
          iconColor: AppColors.healthRisk,
          title: 'Log Out',
          titleStyle: const TextStyle(
            color: AppColors.healthRisk,
            fontWeight: FontWeight.w600,
          ),
          onTap: () => _openLogout(context),
        ),
      ],
    );
  }

  void _showSettingsUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings are unavailable right now.')),
    );
  }

  Future<void> _pushPage(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openAdmin(BuildContext context) {
    final repository = context.read<SettingsRepository?>();
    if (repository == null) {
      _showSettingsUnavailable(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminLogoInputPage(settingsRepository: repository),
      ),
    );
  }

  Future<void> _openHelpSettings(BuildContext context) async {
    final repository = context.read<SettingsRepository?>();
    if (repository == null) {
      _showSettingsUnavailable(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Help & Settings')),
          body: AdminHelpSettingsScreen(
            settingsRepository: repository,
            onOpenLogoInput: () => _openAdmin(context),
          ),
        ),
      ),
    );
    if (context.mounted) onLogoChanged?.call();
  }

  void _openLogout(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LogoutConfirmationPage(
          onConfirm: () async {
            await authProvider.logout();
            if (!context.mounted) return;
            if (authProvider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.errorMessage!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              return;
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          },
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.entryKey,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.titleStyle,
  });

  final Key entryKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: entryKey,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: titleStyle),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
