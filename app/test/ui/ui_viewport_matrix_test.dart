import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/responsive_page_frame.dart';

void main() {
  final matrix = _loadJson('test/ui/fixtures/ui_viewport_matrix.json');
  final inventory = _loadJson('test/ui/fixtures/ui_surface_inventory.json');

  test('declares the complete canonical viewport and boundary matrix', () {
    final viewports = _viewports(matrix);
    final dimensions = {
      for (final viewport in viewports)
        '${viewport['width']}x${viewport['height']}',
    };
    const expected = {
      '320x568',
      '390x844',
      '412x915',
      '768x1024',
      '1024x768',
      '599x844',
      '600x844',
      '839x1024',
      '840x1024',
      '1199x900',
      '1200x900',
      '1280x900',
      '1440x900',
      '1599x900',
      '1600x900',
      '1920x1080',
    };

    expect(dimensions, expected);
    expect(
      viewports.map((viewport) => viewport['id']).toSet(),
      hasLength(viewports.length),
    );

    for (final viewport in viewports) {
      final width = (viewport['width'] as num).toDouble();
      final height = (viewport['height'] as num).toDouble();
      final expectedOrientation = width > height ? 'landscape' : 'portrait';
      expect(viewport['orientation'], expectedOrientation);
      expect(
        viewport['class'],
        AppTheme.viewportClassForWidth(width).name,
        reason: 'wrong class for ${viewport['id']}',
      );
    }
  });

  test(
    'keyboard, 200% text and every product domain have executable evidence',
    () {
      final adaptations = matrix['adaptations'] as Map<String, dynamic>;
      final keyboard = adaptations['virtual_keyboard'] as Map<String, dynamic>;
      final largeText = adaptations['text_200_percent'] as Map<String, dynamic>;
      final viewports = _viewports(matrix);
      final viewportIds = viewports.map((viewport) => viewport['id']).toSet();

      expect(keyboard['bottom_inset'], greaterThanOrEqualTo(300));
      expect(largeText['scale'], 2.0);
      expect(viewportIds, contains(keyboard['viewport_id']));
      expect(viewportIds, contains(largeText['viewport_id']));
      _expectTestContains(
        keyboard['test'] as String,
        keyboard['anchor'] as String,
      );
      _expectTestContains(
        largeText['test'] as String,
        largeText['anchor'] as String,
      );

      final evidence = matrix['domain_evidence'] as Map<String, dynamic>;
      final inventoryDomains =
          (inventory['domain_contracts'] as Map<String, dynamic>).keys.toSet();
      expect(evidence.keys.toSet(), inventoryDomains);

      for (final entry in evidence.entries) {
        final tests = (entry.value as List<dynamic>).cast<String>();
        expect(
          tests,
          isNotEmpty,
          reason: '${entry.key} has no viewport evidence',
        );
        for (final path in tests) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: 'missing $path');
          expect(
            file.readAsStringSync(),
            contains('testWidgets('),
            reason: '$path is not executable widget evidence',
          );
        }
      }
    },
  );

  testWidgets('shared page frame remains bounded in every canonical viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final viewport in _viewports(matrix)) {
      final size = Size(
        (viewport['width'] as num).toDouble(),
        (viewport['height'] as num).toDouble(),
      );
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsivePageFrame(
                child: SizedBox(
                  key: Key('viewport-content'),
                  width: double.infinity,
                  height: 120,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rect = tester.getRect(find.byKey(const Key('viewport-content')));
      final expectedWidth =
          (size.width > AppTheme.contentMaxWidth
              ? AppTheme.contentMaxWidth
              : size.width) -
          (AppTheme.horizontalGutterForWidth(size.width) * 2);
      expect(rect.left, greaterThanOrEqualTo(0), reason: '${viewport['id']}');
      expect(
        rect.right,
        lessThanOrEqualTo(size.width),
        reason: '${viewport['id']}',
      );
      expect(
        rect.width,
        closeTo(expectedWidth, 0.1),
        reason: '${viewport['id']}',
      );
      expect(tester.takeException(), isNull, reason: '${viewport['id']}');
    }
  });

  testWidgets('adaptive master detail owns both sides of the 1200 boundary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final fixture in const [
      (width: 1199.0, horizontal: false),
      (width: 1200.0, horizontal: true),
    ]) {
      tester.view.physicalSize = Size(fixture.width, 900);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveMasterDetail(
              master: SizedBox(key: Key('matrix-master'), height: 80),
              detail: SizedBox(key: Key('matrix-detail'), height: 80),
            ),
          ),
        ),
      );
      await tester.pump();

      final master = tester.getRect(find.byKey(const Key('matrix-master')));
      final detail = tester.getRect(find.byKey(const Key('matrix-detail')));
      if (fixture.horizontal) {
        expect(detail.left, greaterThan(master.right));
      } else {
        expect(detail.top, greaterThan(master.bottom));
      }
      expect(tester.takeException(), isNull);
    }
  });
}

Map<String, dynamic> _loadJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _viewports(Map<String, dynamic> matrix) {
  return (matrix['viewports'] as List<dynamic>).cast<Map<String, dynamic>>();
}

void _expectTestContains(String path, String anchor) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing $path');
  expect(
    file.readAsStringSync(),
    contains(anchor),
    reason: '$path lost $anchor',
  );
}
