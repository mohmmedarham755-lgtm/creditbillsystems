import 'package:flutter_test/flutter_test.dart';
import 'package:creditbillsytems/core/constants/app_colors.dart';
import 'package:creditbillsytems/core/theme/app_theme.dart';

void main() {
  group('AppTheme Material 3 Verification Tests', () {
    test('light theme uses Material 3 and DESIGN.md palette tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.surfaceBase);
      expect(theme.colorScheme.primary, AppColors.brandPrimary);
      expect(theme.colorScheme.surface, AppColors.surfaceCard);
    });

    test('dark theme uses Material 3 and dark tokens', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.surfaceBaseDark);
      expect(theme.colorScheme.primary, AppColors.brandPrimaryDark);
      expect(theme.colorScheme.surface, AppColors.surfaceCardDark);
    });
  });
}
