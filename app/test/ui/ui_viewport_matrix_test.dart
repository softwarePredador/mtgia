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
      '844x390',
      '915x412',
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

  test('documents and guards the app orientation policy', () {
    final policy = matrix['orientation_policy'] as Map<String, dynamic>;
    final appShell = policy['app_shell'] as Map<String, dynamic>;
    final lifeCounter = policy['life_counter_native'] as Map<String, dynamic>;
    final webPwa = policy['web_pwa'] as Map<String, dynamic>;

    expect(appShell['mode'], 'responsive');
    expect((appShell['supported_postures'] as List<dynamic>).toSet(), {
      'portrait',
      'landscape',
    });
    expect(webPwa['mode'], 'responsive');
    expect((webPwa['supported_postures'] as List<dynamic>).toSet(), {
      'portrait',
      'landscape',
    });

    final androidManifest = File(
      appShell['android_manifest'] as String,
    ).readAsStringSync();
    expect(
      androidManifest,
      isNot(contains('android:screenOrientation=')),
      reason: 'the Android app shell must remain responsive to rotation',
    );

    final iosManifest = File(
      appShell['ios_manifest'] as String,
    ).readAsStringSync();
    expect(iosManifest, contains('UIInterfaceOrientationPortrait'));
    expect(iosManifest, contains('UIInterfaceOrientationLandscapeLeft'));
    expect(iosManifest, contains('UIInterfaceOrientationLandscapeRight'));

    final pwaManifest =
        jsonDecode(File(webPwa['manifest'] as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(pwaManifest['orientation'], webPwa['manifest_orientation']);
    expect(pwaManifest['orientation'], 'any');

    expect(lifeCounter['mode'], 'route_scoped_landscape_lock');
    final lifeCounterSource = lifeCounter['source'] as String;
    final orientationOwners = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains(
            'SystemChrome.setPreferredOrientations',
          ),
        )
        .map((file) => file.path)
        .toSet();
    expect(
      orientationOwners,
      {lifeCounterSource},
      reason: 'only the native Life Counter route may lock orientation',
    );

    final lifeCounterEntrySource = lifeCounter['entry_source'] as String;
    final presentationModeClients = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains(
            'LotusPresentationMode.instance.enter()',
          ),
        )
        .map((file) => file.path)
        .toSet();
    expect(
      presentationModeClients,
      {lifeCounterEntrySource},
      reason: 'no app route besides Life Counter may enter landscape mode',
    );
    final entrySource = File(lifeCounterEntrySource).readAsStringSync();
    expect(entrySource, contains(lifeCounter['web_exclusion_guard']));
    expect(
      entrySource,
      matches(RegExp(r'_ownsPresentationMode\s*=\s*!kIsWeb\s*&&')),
      reason: 'Web and installed PWA must never enter native landscape mode',
    );

    final source = File(lifeCounterSource).readAsStringSync();
    for (final orientation
        in (lifeCounter['allowed_device_orientations'] as List<dynamic>)
            .cast<String>()) {
      expect(source, contains(orientation));
    }
    expect(
      source,
      contains(
        'SystemChrome.setPreferredOrientations(DeviceOrientation.values)',
      ),
      reason: 'leaving Life Counter must restore every app orientation',
    );
    _expectTestContains(
      lifeCounter['test'] as String,
      lifeCounter['anchor'] as String,
    );
  });

  test(
    'covers reference phones in portrait and landscape by logical width',
    () {
      final viewportsById = {
        for (final viewport in _viewports(matrix)) viewport['id']: viewport,
      };

      for (final pair in const [
        ('mobile-reference', 'mobile-reference-landscape'),
        ('mobile-large', 'mobile-large-landscape'),
      ]) {
        final portrait = viewportsById[pair.$1]!;
        final landscape = viewportsById[pair.$2]!;

        expect(portrait['width'], landscape['height']);
        expect(portrait['height'], landscape['width']);
        expect(portrait['orientation'], 'portrait');
        expect(landscape['orientation'], 'landscape');
        expect(portrait['class'], 'compact');
        expect(landscape['class'], 'expanded');
      }
    },
  );

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
