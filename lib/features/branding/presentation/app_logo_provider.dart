import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/branding_repository.dart';

class AppLogoProvider extends ChangeNotifier {
  final BrandingRepository _repository;

  Uint8List? _logoBytes;
  bool _isLoaded = false;
  bool _isSaving = false;
  String? _errorMessage;

  AppLogoProvider({required BrandingRepository repository})
    : _repository = repository;

  Uint8List? get logoBytes => _logoBytes;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadLogo() async {
    try {
      _logoBytes = await _repository.getLogo();
      _errorMessage = null;
    } on DatabaseException catch (_) {
      _errorMessage = 'Unable to load the saved app logo.';
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<bool> saveLogo(Uint8List bytes) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveLogo(bytes);
      _logoBytes = Uint8List.fromList(bytes);
      return true;
    } on DatabaseException catch (_) {
      _errorMessage = 'Unable to save the app logo. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
