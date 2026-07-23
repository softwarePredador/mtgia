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

  group('AppTheme responsive boundaries', () {
    test('owns every pixel around the canonical breakpoints', () {
      expect(AppTheme.viewportClassForWidth(599), AppViewportClass.compact);
      expect(AppTheme.viewportClassForWidth(600), AppViewportClass.medium);
      expect(AppTheme.viewportClassForWidth(839), AppViewportClass.medium);
      expect(AppTheme.viewportClassForWidth(840), AppViewportClass.expanded);
      expect(AppTheme.viewportClassForWidth(1199), AppViewportClass.expanded);
      expect(AppTheme.viewportClassForWidth(1200), AppViewportClass.wide);
      expect(AppTheme.viewportClassForWidth(1599), AppViewportClass.wide);
      expect(AppTheme.viewportClassForWidth(1600), AppViewportClass.ultraWide);
    });

    test('uses compact gutters only below 600 logical pixels', () {
      expect(
        AppTheme.horizontalGutterForWidth(599),
        AppTheme.pageGutterCompact,
      );
      expect(AppTheme.horizontalGutterForWidth(600), AppTheme.pageGutter);
    });
  });
}
