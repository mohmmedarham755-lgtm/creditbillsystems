// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/settings_repository.dart';

typedef ImagePickCallback = Future<XFile?> Function(ImageSource source);
typedef LostDataCallback = Future<LostDataResponse> Function();
typedef AppDirectoryCallback = Future<Directory> Function();
typedef LogoPreviewBuilder = Widget Function(String path);

/// Admin-only Help & Settings page with logo upload.
class AdminHelpSettingsScreen extends StatefulWidget {
  final SettingsRepository settingsRepository;
  final ImagePickCallback? pickImage;
  final LostDataCallback? retrieveLostData;
  final AppDirectoryCallback? getAppDirectory;

  /// Optional preview builder used by tests to avoid decoding real image files.
  final LogoPreviewBuilder? logoPreviewBuilder;

  /// When false, only the logo-upload card is shown.
  final bool showHelpSection;

  /// Optional action that opens the dedicated Admin Logo Input page.
  final VoidCallback? onOpenLogoInput;

  const AdminHelpSettingsScreen({
    super.key,
    required this.settingsRepository,
    this.pickImage,
    this.retrieveLostData,
    this.getAppDirectory,
    this.logoPreviewBuilder,
    this.showHelpSection = true,
    this.onOpenLogoInput,
  });

  @visibleForTesting
  static const Key logoPreviewKey = Key('admin-logo-preview');

  @visibleForTesting
  static const Key uploadButtonKey = Key('admin-logo-upload');

  @visibleForTesting
  static const Key fallbackIconKey = Key('admin-logo-fallback');

  @override
  State<AdminHelpSettingsScreen> createState() =>
      _AdminHelpSettingsScreenState();
}

class _AdminHelpSettingsScreenState extends State<AdminHelpSettingsScreen> {
  String? _logoPath;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final settings = await widget.settingsRepository.getSettings();
      if (!mounted) return;
      setState(() {
        _logoPath = settings.logoPath;
        _isLoading = false;
      });
      await _recoverLostImage();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load settings.';
        _isLoading = false;
      });
    }
  }

  Future<XFile?> _pickImage(ImageSource source) {
    final picker = widget.pickImage;
    if (picker != null) return picker(source);
    return ImagePicker().pickImage(source: source);
  }

  Future<LostDataResponse> _retrieveLostData() {
    final retriever = widget.retrieveLostData;
    if (retriever != null) return retriever();
    return ImagePicker().retrieveLostData();
  }

  Future<void> _recoverLostImage() async {
    if (_isSaving) return;
    try {
      final lost = await _retrieveLostData();
      if (lost.isEmpty) return;
      final file = lost.file;
      if (file != null) {
        await _persistPickedImage(file);
        return;
      }
      if (lost.exception != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update logo. Please try again.'),
          ),
        );
      }
    } catch (_) {
      // Best-effort recovery; ignore if platform doesn't support it.
    }
  }

  Future<Directory> _getAppDirectory() {
    final getter = widget.getAppDirectory;
    if (getter != null) return getter();
    return getApplicationDocumentsDirectory();
  }

  Future<void> _persistPickedImage(XFile picked) async {
    final previousPath = _logoPath;
    try {
      if (mounted) {
        setState(() {
          _isSaving = true;
        });
      }

      final appDir = await _getAppDirectory();
      final logoDir = Directory(p.join(appDir.path, 'branding'));
      if (!logoDir.existsSync()) {
        logoDir.createSync(recursive: true);
      }

      final ext = p.extension(picked.path);
      final safeExt = ext.isNotEmpty ? ext : '.png';
      final unique =
          DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(1 << 30);
      final fileName = 'admin_logo_$unique$safeExt';
      final targetPath = p.join(logoDir.path, fileName);

      try {
        final src = File(picked.path);
        if (picked.path.isNotEmpty && src.existsSync()) {
          src.copySync(targetPath);
        } else {
          final bytes = await picked.readAsBytes();
          await File(targetPath).writeAsBytes(bytes, flush: true);
        }
      } catch (_) {
        final bytes = await picked.readAsBytes();
        await File(targetPath).writeAsBytes(bytes, flush: true);
      }

      await widget.settingsRepository.saveLogoPath(targetPath);

      if (!mounted) return;
      setState(() {
        _logoPath = targetPath;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logoPath = previousPath;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update logo. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handlePickImage() async {
    if (_isSaving) return;
    try {
      // Set saving state before awaiting the platform picker: on some
      // platforms the picker future completes in a microtask and a second tap
      // or async gap otherwise lets the handler run twice.
      setState(() {
        _isSaving = true;
      });

      final picked = await _pickImage(ImageSource.gallery);
      if (picked == null) {
        // Android may destroy/recreate the activity during picking; check for
        // a lost image before treating this as a plain cancel.
        final lost = await _retrieveLostData();
        if (!mounted) return;
        if (!lost.isEmpty && lost.file != null) {
          await _persistPickedImage(lost.file!);
          return;
        }
        setState(() {
          _isSaving = false;
        });
        if (lost.exception != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to update logo. Please try again.'),
            ),
          );
        }
        return;
      }

      await _persistPickedImage(picked);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update logo. Please try again.'),
        ),
      );
    }
  }

  bool get _hasValidLogo {
    final path = _logoPath;
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _loadError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('admin-settings-retry'),
                          onPressed: _isLoading ? null : _loadSettings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                if (widget.onOpenLogoInput != null) ...[
                  Card(
                    child: ListTile(
                      key: const Key('admin-logo-input-link'),
                      leading: const Icon(Icons.image_outlined),
                      title: const Text('Open Admin Logo Input Page'),
                      subtitle: const Text(
                        'Upload or replace the logo on its own page.',
                      ),
                      onTap: widget.onOpenLogoInput,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.showHelpSection) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help & About',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Credit Bill System helps you track cards, bills, payments, and due dates in one place. '
                            'Use the Dashboard for an overview, Bills to manage statements, and Calendar for upcoming due dates.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Branding',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload a logo to personalize this settings page.',
                        ),
                        const SizedBox(height: 16),
                        Center(child: _buildLogoPreview(context)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: AdminHelpSettingsScreen.uploadButtonKey,
                            onPressed: _isSaving ? null : _handlePickImage,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    key: Key('admin-logo-saving-indicator'),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _logoPath == null
                                  ? 'Upload Logo'
                                  : 'Replace Logo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogoPreview(BuildContext context) {
    if (_hasValidLogo) {
      final path = _logoPath!;
      final builder = widget.logoPreviewBuilder;
      if (builder != null) {
        return builder(path);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          key: AdminHelpSettingsScreen.logoPreviewKey,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildLogoFallback(context),
        ),
      );
    }
    return _buildLogoFallback(context);
  }

  Widget _buildLogoFallback(BuildContext context) {
    return Container(
      key: AdminHelpSettingsScreen.fallbackIconKey,
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
