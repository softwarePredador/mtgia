import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _pumpUntilUiSnapshotAvailable(
  WidgetTester tester,
  LotusUiSnapshotStore uiSnapshotStore,
) async {
  var snapshot = await uiSnapshotStore.load();
  for (var attempt = 0; attempt < 20 && snapshot == null; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    snapshot = await uiSnapshotStore.load();
  }
  expect(snapshot, isNotNull);
}

void _emitScreenshot(String name, List<int> pngBytes) {
  final encoded = base64Encode(pngBytes);
  const chunkSize = 12000;
  // ignore: avoid_print
  print('SCREENSHOT_BEGIN $name');
  for (var offset = 0; offset < encoded.length; offset += chunkSize) {
    final end =
        (offset + chunkSize < encoded.length)
            ? offset + chunkSize
            : encoded.length;
    // ignore: avoid_print
    print('SCREENSHOT_CHUNK $name ${encoded.substring(offset, end)}');
  }
  // ignore: avoid_print
  print('SCREENSHOT_END $name');
}

Future<void> _showVisualOverlay(
  dynamic screenState, {
  required String overlayClass,
  required String title,
  required String text,
  required List<String> buttons,
}) async {
  final buttonsHtml =
      buttons.map((label) => '<div class="btn">$label</div>').join();

  final script = '''
(() => {
  document.querySelectorAll('[data-manaloom-visual-proof="true"]').forEach((node) => node.remove());

  const overlay = document.createElement('div');
  overlay.className = '$overlayClass';
  overlay.setAttribute('data-manaloom-visual-proof', 'true');
  overlay.innerHTML = `
    <div class="font">$title</div>
    <div class="text">$text</div>
    <div class="btn-wrapper">$buttonsHtml</div>
  `;

  document.body.appendChild(overlay);
})();
''';

  await screenState.debugRunJavaScript(script);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('holds commander damage proof overlay for live screenshot', (
    tester,
  ) async {
    final uiSnapshotStore = LotusUiSnapshotStore();

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final dynamic screenState = tester.state(
      find.byType(LotusLifeCounterScreen),
    );

    await binding.convertFlutterSurfaceToImage();
    await _showVisualOverlay(
      screenState,
      overlayClass: 'commander-damage-overlay',
      title: "COMMANDER DAMAGE YOU'VE RECEIVED",
      text: 'SWIPE LEFT OR RIGHT TO TRACK COMMANDER DAMAGE',
      buttons: const ['RETURN TO GAME', 'GOT IT!'],
    );

    await tester.pump(const Duration(seconds: 1));
    debugPrint('VISUAL_READY commander_damage_overlay');
    final screenshot = await binding.takeScreenshot('commander_damage_overlay');
    _emitScreenshot('commander_damage_overlay', screenshot);
  });

  testWidgets('holds turn tracker hint proof overlay for live screenshot', (
    tester,
  ) async {
    final uiSnapshotStore = LotusUiSnapshotStore();

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final dynamic screenState = tester.state(
      find.byType(LotusLifeCounterScreen),
    );

    await binding.convertFlutterSurfaceToImage();
    await _showVisualOverlay(
      screenState,
      overlayClass: 'turn-tracker-hint-overlay',
      title: 'TURN TRACKER',
      text: 'TAP NEXT OR PREVIOUS TO FOLLOW THE ACTIVE TURN',
      buttons: const ['GOT IT!'],
    );

    await tester.pump(const Duration(seconds: 1));
    debugPrint('VISUAL_READY turn_tracker_hint_overlay');
    final screenshot = await binding.takeScreenshot(
      'turn_tracker_hint_overlay',
    );
    _emitScreenshot('turn_tracker_hint_overlay', screenshot);
  });
}
