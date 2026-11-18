import 'dart:typed_data';

abstract interface class BrandingRepository {
  Future<Uint8List?> getLogo();

  Future<void> saveLogo(Uint8List bytes);
}
