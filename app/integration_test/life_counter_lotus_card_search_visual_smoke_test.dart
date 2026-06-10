import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

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
  const storageKey = '__manaloom_test_card_search_overlay_state';
  const nonceKey = '__manaloom_test_card_search_overlay_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    localStorage.setItem('$storageKey', JSON.stringify({
      menu_overlay_open: !!document.querySelector('.menu-button-overlay'),
      card_search_overlay_open: !!document.querySelector('.card-search-overlay'),
      history_overlay_open: !!document.querySelector('.life-history-overlay'),
      native_card_search_present: !!document.querySelector('[data-testid="life-counter-card-search-overlay"]')
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

Future<void> _clickLotusMenuEntry(
  dynamic screenState,
  List<String> selectors,
) async {
  final encodedSelectors = jsonEncode(selectors);
  await screenState.debugRunJavaScript('''
(() => {
  const dispatchClick = (target) => {
    if (!(target instanceof HTMLElement)) {
      return;
    }
    target.dispatchEvent(
      new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window,
      }),
    );
    if (typeof target.click === 'function') {
      target.click();
    }
  };
  const selectors = $encodedSelectors;
  for (const selector of selectors) {
    const matches = Array.from(document.querySelectorAll(selector));
    const element = matches.findLast((candidate) => {
      if (!(candidate instanceof HTMLElement)) {
        return false;
      }
      return candidate.getClientRects().length > 0;
    }) ?? matches.at(-1);
    if (!element) {
      continue;
    }

    dispatchClick(element);
    if (element.firstElementChild instanceof HTMLElement) {
      dispatchClick(element.firstElementChild);
    }
    return;
  }
})()
''');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens Lotus card search overlay from the radial menu', (
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

    await _clickLotusMenuEntry(screenState, <String>[
      '.menu-button-overlay .card-search-btn',
    ]);
    await tester.pump(const Duration(seconds: 1));

    final searchState = await _readOverlayState(
      tester,
      snapshotStore,
      screenState,
    );
    expect(searchState['card_search_overlay_open'], isTrue);
    expect(searchState['native_card_search_present'], isFalse);
    expect(searchState['history_overlay_open'], isFalse);

    await screenState.debugRunJavaScript('''
(() => {
  const overlay = document.querySelector('.card-search-overlay');
  const input = overlay?.querySelector('input.search-input, input[type="text"], input, textarea');
  if (input instanceof HTMLInputElement || input instanceof HTMLTextAreaElement) {
    const setter = Object.getOwnPropertyDescriptor(
      Object.getPrototypeOf(input),
      'value',
    )?.set;
    input.focus();
    if (setter) {
      setter.call(input, 'Sol Ring');
    } else {
      input.value = 'Sol Ring';
    }
    input.value = 'Sol Ring';
    input.dispatchEvent(new InputEvent('input', {
      bubbles: true,
      cancelable: true,
      inputType: 'insertText',
      data: 'Sol Ring',
    }));
    input.dispatchEvent(new KeyboardEvent('keyup', {
      bubbles: true,
      cancelable: true,
      key: 'g',
    }));
    input.dispatchEvent(new Event('change', { bubbles: true, cancelable: true }));
    input.blur();
  }
})()
''');
    await tester.pump(const Duration(seconds: 4));

    await binding.convertFlutterSurfaceToImage();
    final screenshot = await binding.takeScreenshot(
      'lotus_card_search_overlay',
    );
    _emitScreenshot('lotus_card_search_overlay', screenshot);

    await screenState.debugRunJavaScript(
      "document.querySelector('.close-card-search-overlay')?.click();",
    );
    await tester.pump(const Duration(seconds: 1));
  });
}
