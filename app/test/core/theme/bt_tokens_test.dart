import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/theme/bt_tokens.dart';

/// BT-UX-KIT-001: the kit tokens are a [ThemeExtension] registered in the
/// app theme, built only from [AppTheme] colors, with a fallback that never
/// throws.
void main() {
  test('the dark theme registers the kit tokens', () {
    final tokens = AppTheme.darkTheme.extension<BtTokens>();
    expect(tokens, isNotNull);
    expect(tokens!.palette.brass, AppTheme.brass400);
    expect(tokens.palette.ember, AppTheme.error);
    expect(tokens.palette.wine, AppTheme.btWine);
  });

  testWidgets('of() resolves the registered extension', (tester) async {
    BtTokens? resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            resolved = BtTokens.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, same(AppTheme.darkTheme.extension<BtTokens>()));
  });

  testWidgets('of() falls back to the standard tokens without throwing', (
    tester,
  ) async {
    BtTokens? resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Builder(
          builder: (context) {
            resolved = BtTokens.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(resolved, same(BtTokens.standard));
  });

  test('copyWith and lerp keep the tokens', () {
    final base = BtTokens.standard;
    expect(base.lerp(null, 0.5), same(base));
    final copy = base.copyWith();
    expect(copy.palette, same(base.palette));
    expect(copy.metrics, same(base.metrics));
    final same0 = base.lerp(base, 0.5);
    expect(same0.palette.brass, base.palette.brass);
    expect(same0.metrics.radiusTile, base.metrics.radiusTile);
    expect(same0.metrics.touchTarget, 48);
    expect(same0.metrics.armTimeout, const Duration(seconds: 6));
  });

  test('metrics follow the ruler (F5/F6, 48 dp targets)', () {
    const metrics = BtMetrics();
    expect(metrics.radiusTile, 22);
    expect(metrics.radiusRule, 20);
    expect(metrics.radiusAction, 12);
    expect(metrics.touchTarget, 48);
    expect(metrics.disabledOpacity, 0.38);
  });

  test('display styles pin wght, clamped opsz, WONK 1 and SOFT 0', () {
    final style = BtTokens.standard.numeral(AppNumeralScale.resultado);
    final variations = {for (final v in style.fontVariations!) v.axis: v.value};
    expect(style.fontFamily, AppTheme.displayFontFamily);
    expect(variations['wght'], 700);
    expect(variations['WONK'], 1);
    expect(variations['SOFT'], 0);
    expect(variations['opsz'], 92);
    final huge = BtTokens.standard.numeral(AppNumeralScale.mesa, fontSize: 246);
    final hugeAxes = {for (final v in huge.fontVariations!) v.axis: v.value};
    expect(hugeAxes['opsz'], 144, reason: 'Fraunces opsz stops at 144');
    expect(
      style.fontFeatures,
      containsAll(const [FontFeature.liningFigures()]),
    );
  });

  test('Inter styles clamp opsz at 32', () {
    final label = BtTokens.standard.typography.label;
    final axes = {for (final v in label.fontVariations!) v.axis: v.value};
    expect(label.fontFamily, AppTheme.uiFontFamily);
    expect(axes['opsz'], inInclusiveRange(14, 32));
    expect(axes['wght'], 800);
  });

  test('BtAngleGradient builds a shader in RTL and keeps its type', () {
    const gradient = BtAngleGradient(
      angle: 115,
      colors: [AppTheme.btLight, AppTheme.btShade],
    );
    expect(
      gradient.createShader(
        const Rect.fromLTWH(0, 0, 100, 40),
        textDirection: TextDirection.rtl,
      ),
      isNotNull,
    );
    expect(gradient.withOpacity(0.5), isA<BtAngleGradient>());
  });
}
