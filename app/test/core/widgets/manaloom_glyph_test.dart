import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/manaloom_glyph.dart';

void main() {
  test('ships every original ManaLoom glyph as a 24 by 24 SVG', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/icons/'));

    for (final kind in ManaLoomGlyphKind.values) {
      final asset = File(kind.assetPath);
      expect(
        asset.existsSync(),
        isTrue,
        reason: 'Missing original ManaLoom glyph ${kind.assetPath}',
      );

      final source = asset.readAsStringSync();
      expect(source, contains('viewBox="0 0 24 24"'));
      expect(source, contains('fill="none"'));
      expect(source, contains('stroke-linecap="round"'));
      expect(source, isNot(contains('<text')));
    }
  });

  testWidgets('renders every kind and exposes an explicit semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final kind in ManaLoomGlyphKind.values)
              ManaLoomGlyph(kind, semanticLabel: 'ManaLoom ${kind.name}'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(SvgPicture),
      findsNWidgets(ManaLoomGlyphKind.values.length),
    );
    for (final kind in ManaLoomGlyphKind.values) {
      expect(find.bySemanticsLabel('ManaLoom ${kind.name}'), findsOneWidget);
    }
    semantics.dispose();
  });

  testWidgets('inherits size and color from IconTheme', (tester) async {
    const glyphKey = ValueKey('themed-glyph');
    const inheritedColor = Color(0xFFC58B2A);

    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 31, color: inheritedColor),
          child: ManaLoomGlyph(ManaLoomGlyphKind.deck, key: glyphKey),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final svg = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(glyphKey),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(svg.width, 31);
    expect(svg.height, 31);
    expect(svg.colorFilter, isNotNull);
  });

  testWidgets('explicit size and color override IconTheme', (tester) async {
    const glyphKey = ValueKey('overridden-glyph');

    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 31, color: Colors.red),
          child: ManaLoomGlyph(
            ManaLoomGlyphKind.shuffle,
            key: glyphKey,
            size: 18,
            color: Colors.blue,
            semanticLabel: 'Embaralhar',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final svg = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(glyphKey),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(svg.width, 18);
    expect(svg.height, 18);
    expect(svg.colorFilter, isNotNull);
    expect(find.bySemanticsLabel('Embaralhar'), findsOneWidget);
  });
}
