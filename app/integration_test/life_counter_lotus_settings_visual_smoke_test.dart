import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
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

Future<Map<String, dynamic>> _readOverlayState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_settings_overlay_state';
  const nonceKey = '__manaloom_test_settings_overlay_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    localStorage.setItem('$storageKey', JSON.stringify({
      menu_overlay_open: !!document.querySelector('.menu-button-overlay'),
      settings_overlay_open: !!document.querySelector('.settings-overlay'),
      native_settings_present: !!document.querySelector('[data-testid="life-counter-settings-overlay"]')
    }));
    localStorage.setItem('$nonceKey', '$nonce');
  } catch (_) {}
})()
''');

  String? encodedState;
  for (var attempt = 0; attempt < 20 && encodedState == null; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 300));
    final snapshot = await snapshotStore.load();
    if (snapshot == null) {
      continue;
    }
    if (snapshot.values[nonceKey] != nonce) {
      continue;
    }
    encodedState = snapshot.values[storageKey];
  }

  expect(encodedState, isNotNull);
  final decoded = jsonDecode(encodedState!);
  return Map<String, dynamic>.from(decoded as Map);
}

Future<void> _openLotusMenu(dynamic screenState) async {
  await screenState.debugRunJavaScript('''
(() => {
  const button = document.querySelector('.menu-button');
  if (button) {
    button.click();
  }
})()
''');
}

Future<void> _clickSettings(dynamic screenState) async {
  await screenState.debugRunJavaScript('''
(() => {
  const dispatchClick = (target) => {
    if (!(target instanceof HTMLElement)) {
      return;
    }
    target.dispatchEvent(new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      view: window,
    }));
    if (typeof target.click === 'function') {
      target.click();
    }
  };

  const matches = Array.from(document.querySelectorAll('body *'));
  const element = matches.findLast((candidate) => {
    if (!(candidate instanceof HTMLElement)) {
      return false;
    }
    if (candidate.getClientRects().length === 0) {
      return false;
    }
    const className = typeof candidate.className === 'string' ? candidate.className : '';
    return className.toLowerCase().includes('settings');
  });

  if (!element) {
    return;
  }

  dispatchClick(element);
  const buttonLike = element.closest('button, [role="button"], .btn, .menu-item, .settings-list-item');
  if (buttonLike instanceof HTMLElement && buttonLike !== element) {
    dispatchClick(buttonLike);
  }
  if (element.firstElementChild instanceof HTMLElement) {
    dispatchClick(element.firstElementChild);
  }
})()
''');
}

Future<void> _pumpUntilSettingsOpen(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 300));
    final state = await _readOverlayState(tester, snapshotStore, screenState);
    if (state['settings_overlay_open'] == true) {
      return;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens Lotus settings overlay from the radial menu', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final uiSnapshotStore = LotusUiSnapshotStore();

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final dynamic screenState = tester.state(
      find.byType(LotusLifeCounterScreen),
    );

    await _openLotusMenu(screenState);
    await tester.pump(const Duration(seconds: 1));

    final menuState = await _readOverlayState(
      tester,
      snapshotStore,
      screenState,
    );
    expect(menuState['menu_overlay_open'], isTrue);

    await _clickSettings(screenState);
    await _pumpUntilSettingsOpen(tester, snapshotStore, screenState);
    await tester.pump(const Duration(seconds: 1));

    final settingsState = await _readOverlayState(
      tester,
      snapshotStore,
      screenState,
    );
    expect(settingsState['settings_overlay_open'], isTrue);
    expect(settingsState['native_settings_present'], isFalse);
  });
}
