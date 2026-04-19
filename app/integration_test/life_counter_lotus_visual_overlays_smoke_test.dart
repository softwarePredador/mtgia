import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<Map<String, dynamic>?> _probeLotusDomViaShellBridge(
  WidgetTester tester,
  dynamic screenState, {
  required int requestId,
}) async {
  screenState.debugClearLastShellMessage();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const payload = {
      type: 'debug_dom_probe',
      request_id: $requestId,
      menuCount: document.querySelectorAll('.menu-button').length,
      playerCardCount: document.querySelectorAll('.player-card').length,
      overlayCount: document.querySelectorAll('[class*="overlay"]').length,
      readyState: document.readyState,
      title: document.title,
    };
    FlutterManaLoomShellBridge.postMessage(JSON.stringify(payload));
  } catch (e) {
    FlutterManaLoomShellBridge.postMessage(JSON.stringify({
      type: 'debug_dom_probe',
      request_id: $requestId,
      error: true,
      message: String(e),
    }));
  }
})()
''');

  for (var attempt = 0; attempt < 10; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 200));
    final raw = screenState.debugGetLastShellMessage();
    if (raw == null) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map &&
          decoded['type'] == 'debug_dom_probe' &&
          decoded['request_id'] == requestId) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
  }

  return null;
}

Future<void> _pumpUntilLotusReady(
  WidgetTester tester,
  dynamic screenState,
) async {
  Map<String, dynamic>? lastProbe;

  for (var attempt = 0; attempt < 45; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));

    final requestId = DateTime.now().microsecondsSinceEpoch;
    final probe = await _probeLotusDomViaShellBridge(
      tester,
      screenState,
      requestId: requestId,
    );

    if (probe != null) {
      lastProbe = probe;
      if (attempt == 0 || attempt == 10 || attempt == 25 || attempt == 44) {
        // ignore: avoid_print
        print(
          '[life_counter_overlays_smoke] ready probe @$attempt: $lastProbe',
        );
      }

      final menuCount = (probe['menuCount'] as num?)?.toInt() ?? 0;
      if (menuCount > 0) {
        return;
      }
    }
  }

  fail('Lotus not ready: menu button not found. lastProbe=$lastProbe');
}

Future<Map<String, dynamic>> _readOverlayState(
  WidgetTester tester,
  dynamic screenState,
) async {
  final requestId = DateTime.now().microsecondsSinceEpoch;

  await _runStep('post_overlay_probe', () async {
    screenState.debugClearLastShellMessage();
    await screenState.debugRunJavaScript('''
(() => {
  try {
    FlutterManaLoomShellBridge.postMessage(JSON.stringify({
      type: 'debug_overlay_probe',
      request_id: $requestId,
      menu_overlay_open: !!document.querySelector('.menu-button-overlay'),
      settings_overlay_open: !!document.querySelector('.settings-overlay'),
      history_overlay_open: !!document.querySelector('.life-history-overlay'),
      search_overlay_open: !!document.querySelector('.card-search-overlay') ||
        !!document.querySelector('.search-overlay'),
      native_settings_present: !!document.querySelector('[data-testid="life-counter-settings-overlay"]'),
      native_history_present: !!document.querySelector('[data-testid="life-counter-history-overlay"]'),
      native_card_search_present: !!document.querySelector('[data-testid="life-counter-card-search-overlay"]')
    }));
  } catch (e) {
    FlutterManaLoomShellBridge.postMessage(JSON.stringify({
      type: 'debug_overlay_probe',
      request_id: $requestId,
      error: true,
      message: String(e),
    }));
  }
})()
''');
  });

  for (var attempt = 0; attempt < 10; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 200));
    final raw = screenState.debugGetLastShellMessage();
    if (raw == null) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map &&
          decoded['type'] == 'debug_overlay_probe' &&
          decoded['request_id'] == requestId) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
  }

  fail('Overlay probe not received (request_id=$requestId)');
}

const Duration _jsCallTimeout = Duration(seconds: 20);

Future<T> _runStep<T>(
  String name,
  Future<T> Function() body, {
  Duration? timeout,
}) async {
  // print() shows up reliably in flutter test output.
  // ignore: avoid_print
  print('[life_counter_overlays_smoke] STEP start: $name');
  final effectiveTimeout = timeout ?? _jsCallTimeout;
  final result = await body().timeout(effectiveTimeout);
  // ignore: avoid_print
  print('[life_counter_overlays_smoke] STEP done:  $name');
  return result;
}

Future<void> _openLotusMenu(dynamic screenState) async {
  await _runStep('open_menu', () {
    return screenState.debugRunJavaScript('''
(() => {
  const button = document.querySelector('.menu-button');
  if (button) {
    button.click();
  }
})()
''');
  });
}

Future<void> _clickLotusMenuEntry(
  dynamic screenState,
  List<String> selectors,
) async {
  final encodedSelectors = jsonEncode(selectors);
  await _runStep('click_menu_entry ${selectors.join(',')}', () {
    return screenState.debugRunJavaScript('''
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
  });
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'opens Lotus menu and history overlay',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );

      await _runStep(
        'wait_lotus_ready',
        () => _pumpUntilLotusReady(tester, screenState),
        timeout: const Duration(seconds: 150),
      );

      await _openLotusMenu(screenState);
      await tester.pump(const Duration(seconds: 1));

      final menuState = await _readOverlayState(tester, screenState);
      expect(menuState['menu_overlay_open'], isTrue);

      await _clickLotusMenuEntry(screenState, <String>[
        '.menu-button-overlay .life-history-btn',
      ]);
      await tester.pump(const Duration(seconds: 1));

      final historyState = await _readOverlayState(tester, screenState);
      expect(historyState['history_overlay_open'], isTrue);
      expect(historyState['native_history_present'], isFalse);

      await _runStep('close_history_overlay', () {
        return screenState.debugRunJavaScript(
          "document.querySelector('.close-life-history-overlay-btn')?.click();",
        );
      });
      await tester.pump(const Duration(seconds: 1));

      await _openLotusMenu(screenState);
      await tester.pump(const Duration(seconds: 1));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
