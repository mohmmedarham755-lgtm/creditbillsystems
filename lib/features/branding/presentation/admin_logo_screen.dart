import 'dart:io';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_provider.dart';
import 'app_brand_logo.dart';
import 'app_logo_provider.dart';

class AdminLogoScreen extends StatefulWidget {
  const AdminLogoScreen({super.key});

  @override
  State<AdminLogoScreen> createState() => _AdminLogoScreenState();
}

class _AdminLogoScreenState extends State<AdminLogoScreen> {
  static const _maxLogoBytes = 2 * 1024 * 1024;
  bool _isPicking = false;

  Future<void> _pickLogo() async {
    setState(() => _isPicking = true);
    try {
      final result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted) return;

      if (result.isEmpty) return;
      final path = result.single.path;
      final bytes = path == null ? null : await File(path).readAsBytes();
      if (bytes == null) {
        _showMessage('Could not read the selected image.');
        return;
      }
      if (bytes.isEmpty) {
        _showMessage('Could not read the selected image.');
        return;
      }
      if (bytes.length > _maxLogoBytes) {
        _showMessage('Choose an image smaller than 2 MB.');
        return;
      }

      // ignore: use_build_context_synchronously
      final branding = (context.read<AppLogoProvider?>());
      if (branding == null) {
        _showMessage('Logo settings are unavailable.');
        return;
      }
      final saved = await branding.saveLogo(bytes);
      if (!mounted) return;
      _showMessage(
        saved
            ? 'App logo updated.'
            : branding.errorMessage ?? 'Unable to save the app logo.',
      );
    } on PlatformException catch (_) {
      if (mounted) _showMessage('Unable to open the image picker.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Logo')),
        body: const Center(child: Text('Admin access required.')),
      );
    }

    final branding = context.watch<AppLogoProvider?>();
    if (branding == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Logo')),
        body: const Center(child: Text('Logo settings are unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('App Logo')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: AppBrandLogo(size: 144)),
                const SizedBox(height: 24),
                Text(
                  'Set the logo shown on the welcome and sign-in screens.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (branding.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    branding.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('admin-logo.choose'),
                  onPressed: _isPicking || branding.isSaving ? null : _pickLogo,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _isPicking
                        ? 'Opening images...'
                        : branding.logoBytes == null
                        ? 'Set Logo'
                        : 'Change Logo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a PNG or JPEG image up to 2 MB.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
