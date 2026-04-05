import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';

void main() {
  group('AppTheme typography', () {
    test('uses local UI and display font families', () {
      final theme = AppTheme.darkTheme;

      expect(theme.textTheme.bodyLarge?.fontFamily, AppTheme.uiFontFamily);
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.uiFontFamily);
      expect(theme.textTheme.labelLarge?.fontFamily, AppTheme.uiFontFamily);
      expect(
        theme.textTheme.headlineMedium?.fontFamily,
        AppTheme.displayFontFamily,
      );
      expect(
        theme.textTheme.titleLarge?.fontFamily,
        AppTheme.displayFontFamily,
      );
      expect(
        theme.textTheme.displaySmall?.fontFamily,
        AppTheme.displayFontFamily,
      );
    });
  });
}
