import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _resetHarness() async {
  await LotusStorageSnapshotStore().clear();
  await LotusUiSnapshotStore().clear();
  await LifeCounterSessionStore().clear();
  await LifeCounterSettingsStore().clear();
  await LifeCounterHistoryStore().clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
}

Future<void> _seedFourPlayerSession() async {
  await LifeCounterSettingsStore().save(LifeCounterSettings.defaults);
  await LifeCounterSessionStore().save(
    LifeCounterSession.initial(playerCount: 4),
  );
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

Future<void> _tryCaptureScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    await binding.convertFlutterSurfaceToImage().timeout(
      const Duration(seconds: 20),
    );
    final screenshot = await binding
        .takeScreenshot(name)
        .timeout(const Duration(seconds: 30));
    _emitScreenshot(name, screenshot);
  } catch (error) {
    // Screenshot capture is evidence-only; DOM probes below still validate runtime.
    // ignore: avoid_print
    print('LOTUS_SCREENSHOT_NOT_PROVEN $name ${error.runtimeType}');
  }
}

Future<Map<String, dynamic>?> _probeViaShellBridge(
  WidgetTester tester,
  dynamic screenState, {
  required String probeType,
  required String javascriptBody,
}) async {
  final requestId = DateTime.now().microsecondsSinceEpoch;
  final shellProbeType =
      probeType.startsWith('debug_') ? probeType : 'debug_$probeType';
  screenState.debugClearLastShellMessage();
  await screenState.debugRunJavaScript('''
(() => {
  try {
    const payload = (() => {
      $javascriptBody
    })();
    FlutterManaLoomShellBridge.postMessage(JSON.stringify({
      type: '$shellProbeType',
      request_id: $requestId,
      payload,
    }));
  } catch (error) {
    FlutterManaLoomShellBridge.postMessage(JSON.stringify({
      type: '$shellProbeType',
      request_id: $requestId,
      error: true,
      message: String(error),
    }));
  }
})()
''');

  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    final raw = screenState.debugGetLastShellMessage();
    if (raw == null) {
      continue;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map &&
        decoded['type'] == shellProbeType &&
        decoded['request_id'] == requestId) {
      return Map<String, dynamic>.from(decoded);
    }
  }

  return null;
}

Future<Map<String, dynamic>> _waitForLotusReady(
  WidgetTester tester,
  dynamic screenState, {
  int expectedFirstStoredLife = 40,
}) async {
  Map<String, dynamic>? lastProbe;
  for (var attempt = 0; attempt < 45; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    final probe = await _probeViaShellBridge(
      tester,
      screenState,
      probeType: 'life_counter_lotus_runtime_ready_probe',
      javascriptBody: r'''
const decodeLifeText = (node) => {
  const digits = Array.from(node?.querySelectorAll('.font') ?? []);
  const decodeDigit = (digit) => {
    const classes = Array.from(digit.classList);
    const charClass = classes.find((className) => className.startsWith('char-'));
    if (!charClass) {
      return '';
    }
    const charName = charClass.substring('char-'.length);
    if (charName === 'plus') {
      return '+';
    }
    if (charName === 'minus') {
      return '-';
    }
    return charName;
  };
  return digits.map(decodeDigit).join('');
};
const lifeDigitsFit = (node) => {
  const digits = Array.from(node?.querySelectorAll('.font') ?? []);
  if (!node || digits.length === 0) {
    return false;
  }
  const containerRect = node.getBoundingClientRect();
  if (containerRect.width <= 0 || containerRect.height <= 0) {
    return false;
  }
  return digits.every((digit) => {
    const rect = digit.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 &&
      rect.left >= containerRect.left - 2 &&
      rect.right <= containerRect.right + 2 &&
      rect.top >= containerRect.top - 2 &&
      rect.bottom <= containerRect.bottom + 2;
  });
};
const playerCards = Array.from(document.querySelectorAll('.player-card'));
const players = JSON.parse(localStorage.getItem('players') ?? '[]');
const firstLifeNode = playerCards[0]?.querySelector('.player-life-count');
const firstLifeFont = firstLifeNode?.querySelector('.font') ?? firstLifeNode;
const lifeStyle = firstLifeFont ? window.getComputedStyle(firstLifeFont) : null;
const lifeRect = firstLifeFont ? firstLifeFont.getBoundingClientRect() : null;
return {
  readyState: document.readyState,
  title: document.title,
  playerCardCount: playerCards.length,
  playerLifeCount: document.querySelectorAll('.player-life-count').length,
  menuCount: document.querySelectorAll('.menu-button').length,
  increaseCount: document.querySelectorAll('.increase-button.life').length,
  decreaseCount: document.querySelectorAll('.decrease-button.life').length,
  firstLifeText: decodeLifeText(firstLifeNode),
  rawFirstLifeText: (firstLifeNode?.textContent ?? '').trim(),
  firstStoredLife: players[0]?.life ?? null,
  secondStoredLife: players[1]?.life ?? null,
  lifeFontSize: lifeStyle ? parseFloat(lifeStyle.fontSize) : 0,
  lifeColor: lifeStyle?.color ?? null,
  lifeTextShadow: lifeStyle?.textShadow ?? null,
  lifeRectWidth: lifeRect?.width ?? 0,
  lifeRectHeight: lifeRect?.height ?? 0,
  lifeDigitCount: firstLifeNode?.querySelectorAll('.font').length ?? 0,
  lifeContentFits: lifeDigitsFit(firstLifeNode),
  horizontalOverflow:
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 2,
  webViewErrorText: document.body.innerText.includes('Life counter unavailable'),
};
''',
    );
    if (probe != null) {
      lastProbe = probe;
      if (probe['error'] == true) {
        continue;
      }
      final payload = Map<String, dynamic>.from(probe['payload'] as Map);
      if ((payload['playerCardCount'] as num?)?.toInt() == 4 &&
          (payload['menuCount'] as num?)?.toInt() == 1 &&
          payload['firstStoredLife'] == expectedFirstStoredLife) {
        return payload;
      }
    }
  }

  fail('Lotus did not reach the expected runtime state. lastProbe=$lastProbe');
}

Future<Map<String, dynamic>> _clickLifeButtonAndProbe(
  WidgetTester tester,
  dynamic screenState, {
  required String selector,
  required int expectedLife,
  required String probeType,
}) async {
  await _probeViaShellBridge(
    tester,
    screenState,
    probeType: '${probeType}_click',
    javascriptBody: '''
const target = document.querySelector($selector);
if (!target) {
  return { clicked: false, reason: 'target_not_found' };
}
const rect = target.getBoundingClientRect();
const options = {
  bubbles: true,
  cancelable: true,
  view: window,
  clientX: rect.left + rect.width / 2,
  clientY: rect.top + rect.height / 2,
};
for (const type of ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click']) {
  const event = type.startsWith('pointer') && typeof PointerEvent === 'function'
    ? new PointerEvent(type, options)
    : new MouseEvent(type, options);
  target.dispatchEvent(event);
}
return { clicked: true };
''',
  );

  Map<String, dynamic>? lastProbe;
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 300));
    final probe = await _probeViaShellBridge(
      tester,
      screenState,
      probeType: probeType,
      javascriptBody: r'''
const decodeLifeText = (node) => {
  const digits = Array.from(node?.querySelectorAll('.font') ?? []);
  const decodeDigit = (digit) => {
    const classes = Array.from(digit.classList);
    const charClass = classes.find((className) => className.startsWith('char-'));
    if (!charClass) {
      return '';
    }
    const charName = charClass.substring('char-'.length);
    if (charName === 'plus') {
      return '+';
    }
    if (charName === 'minus') {
      return '-';
    }
    return charName;
  };
  return digits.map(decodeDigit).join('');
};
const players = JSON.parse(localStorage.getItem('players') ?? '[]');
const firstCard = document.querySelector('.player-card');
const firstLifeNode = firstCard?.querySelector('.player-life-count');
return {
  firstStoredLife: players[0]?.life ?? null,
  firstLifeText: decodeLifeText(firstLifeNode),
  rawFirstLifeText: (firstLifeNode?.textContent ?? '').trim(),
  snapshotLength: localStorage.getItem('players')?.length ?? 0,
};
''',
    );
    if (probe != null) {
      lastProbe = probe;
      if (probe['error'] == true) {
        continue;
      }
      final payload = Map<String, dynamic>.from(probe['payload'] as Map);
      if (payload['firstStoredLife'] == expectedLife) {
        return payload;
      }
    }
  }

  fail(
    'Life button did not set player one to $expectedLife. '
    'lastProbe=$lastProbe',
  );
}

Future<Map<String, dynamic>> _probePersistedSession(
  WidgetTester tester,
  dynamic screenState,
) async {
  final probe = await _probeViaShellBridge(
    tester,
    screenState,
    probeType: 'life_counter_lotus_runtime_reopen_probe',
    javascriptBody: r'''
const decodeLifeText = (node) => {
  const digits = Array.from(node?.querySelectorAll('.font') ?? []);
  const decodeDigit = (digit) => {
    const classes = Array.from(digit.classList);
    const charClass = classes.find((className) => className.startsWith('char-'));
    if (!charClass) {
      return '';
    }
    const charName = charClass.substring('char-'.length);
    if (charName === 'plus') {
      return '+';
    }
    if (charName === 'minus') {
      return '-';
    }
    return charName;
  };
  return digits.map(decodeDigit).join('');
};
const players = JSON.parse(localStorage.getItem('players') ?? '[]');
const playerCards = Array.from(document.querySelectorAll('.player-card'));
const firstLifeNode = playerCards[0]?.querySelector('.player-life-count');
return {
  playerCardCount: playerCards.length,
  firstStoredLife: players[0]?.life ?? null,
  visibleLifeText: decodeLifeText(firstLifeNode),
  rawVisibleLifeText: (firstLifeNode?.textContent ?? '').trim(),
  webViewErrorText: document.body.innerText.includes('Life counter unavailable'),
};
''',
  );
  expect(probe, isNotNull);
  expect(probe!['error'], isNot(true));
  return Map<String, dynamic>.from(probe['payload'] as Map);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'proves Lotus life counter visual runtime, controls, and persistence',
    (tester) async {
      await _resetHarness();
      await _seedFourPlayerSession();

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final readyPayload = await _waitForLotusReady(tester, screenState);
      // ignore: avoid_print
      print('LOTUS_RUNTIME_READY ${jsonEncode(readyPayload)}');

      expect(readyPayload['webViewErrorText'], isFalse);
      expect(readyPayload['playerLifeCount'], 4);
      expect(readyPayload['increaseCount'], 4);
      expect(readyPayload['decreaseCount'], 4);
      expect(readyPayload['firstLifeText'], '40');
      expect(readyPayload['firstStoredLife'], 40);
      expect(readyPayload['secondStoredLife'], 40);
      expect(readyPayload['lifeDigitCount'], 2);
      expect((readyPayload['lifeFontSize'] as num).toDouble(), greaterThan(12));
      expect(
        (readyPayload['lifeRectWidth'] as num).toDouble(),
        greaterThan(40),
      );
      expect(
        (readyPayload['lifeRectHeight'] as num).toDouble(),
        greaterThan(40),
      );
      expect(readyPayload['lifeTextShadow'], isNot('none'));
      expect(readyPayload['lifeContentFits'], isTrue);
      expect(readyPayload['horizontalOverflow'], isFalse);
      expect(
        find.text(
          'External shortcut disabled while ManaLoom owns the life counter shell.',
        ),
        findsNothing,
      );

      await _tryCaptureScreenshot(
        binding,
        'life_counter_lotus_runtime_initial',
      );

      final afterPlus = await _clickLifeButtonAndProbe(
        tester,
        screenState,
        selector: "'.player-card:first-of-type .increase-button.life'",
        expectedLife: 41,
        probeType: 'life_counter_lotus_runtime_after_plus_probe',
      );
      expect(afterPlus['firstStoredLife'], 41);
      expect(afterPlus['firstLifeText'], '41');
      // ignore: avoid_print
      print('LOTUS_RUNTIME_AFTER_PLUS ${jsonEncode(afterPlus)}');

      final afterMinus = await _clickLifeButtonAndProbe(
        tester,
        screenState,
        selector: "'.player-card:first-of-type .decrease-button.life'",
        expectedLife: 40,
        probeType: 'life_counter_lotus_runtime_after_minus_probe',
      );
      expect(afterMinus['firstStoredLife'], 40);
      expect(afterMinus['firstLifeText'], '40');
      // ignore: avoid_print
      print('LOTUS_RUNTIME_AFTER_MINUS ${jsonEncode(afterMinus)}');

      await _clickLifeButtonAndProbe(
        tester,
        screenState,
        selector: "'.player-card:first-of-type .increase-button.life'",
        expectedLife: 41,
        probeType: 'life_counter_lotus_runtime_persist_plus_probe',
      );
      final persistedSession = await LifeCounterSessionStore().load();
      expect(persistedSession, isNotNull);
      expect(persistedSession!.lives.first, 41);

      await _tryCaptureScreenshot(
        binding,
        'life_counter_lotus_runtime_after_plus',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic reopenedState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      await _waitForLotusReady(
        tester,
        reopenedState,
        expectedFirstStoredLife: 41,
      );
      final reopenedPayload = await _probePersistedSession(
        tester,
        reopenedState,
      );
      // ignore: avoid_print
      print('LOTUS_RUNTIME_REOPEN ${jsonEncode(reopenedPayload)}');

      expect(reopenedPayload['webViewErrorText'], isFalse);
      expect(reopenedPayload['playerCardCount'], 4);
      expect(reopenedPayload['firstStoredLife'], 41);
      expect(reopenedPayload['visibleLifeText'], '41');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
