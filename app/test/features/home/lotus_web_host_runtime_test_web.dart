import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_default_host_web.dart';
import 'package:manaloom/features/home/lotus/lotus_host_controller.dart'
    show lotusStorageValuesFingerprint;
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_shell_policy.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_visual_skin.dart';
import 'package:manaloom/features/home/lotus/lotus_web_document.dart';
import 'package:manaloom/features/home/lotus/lotus_webview_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

void main() {
  test(
    'boots the Lotus browser shell inside isolated storage',
    () async {
      const bridgeToken = 'lotus-browser-runtime-test';
      const hostSentinelKey = 'manaloom_lotus_host_sentinel_test';
      final frame =
          web.HTMLIFrameElement()..setAttribute(
            'sandbox',
            'allow-scripts allow-same-origin allow-downloads allow-modals',
          );
      final ready = Completer<Map<String, Object?>>();
      final evaluation = Completer<Object?>();
      Map<String, String>? persistedValues;
      final subscription = web.window.onMessage.listen((event) {
        final rawData = event.data?.dartify();
        if (rawData is! Map) {
          return;
        }
        final data = rawData.map(
          (key, value) => MapEntry<String, Object?>(key.toString(), value),
        );
        if (data['manaloomLotusWeb'] != true || data['token'] != bridgeToken) {
          return;
        }
        switch (data['kind']) {
          case 'ready':
            if (!ready.isCompleted) {
              ready.complete(data);
            }
            return;
          case 'storage':
            final rawValues = data['values'];
            if (rawValues is Map) {
              persistedValues = <String, String>{
                for (final entry in rawValues.entries)
                  if (entry.key is String && entry.value is String)
                    entry.key as String: entry.value as String,
              };
            }
            return;
          case 'eval-result':
            if (!evaluation.isCompleted) {
              final error = data['error'];
              if (error is String) {
                evaluation.completeError(StateError(error));
              } else {
                evaluation.complete(data['result']);
              }
            }
            return;
          case 'fatal':
            if (!ready.isCompleted) {
              ready.completeError(
                StateError(data['detail']?.toString() ?? 'fatal'),
              );
            }
            return;
        }
      });

      web.window.localStorage.setItem(hostSentinelKey, 'keep');
      addTearDown(() async {
        await subscription.cancel();
        frame.remove();
        web.window.localStorage.removeItem(hostSentinelKey);
      });

      const sourceHtml = '''
<!doctype html>
<html lang="en" style="background:#000">
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
    <meta charset="utf-8">
    <title>ManaLoom Life Counter</title>
    <link rel="stylesheet" href="css/styles.min.css">
    <script src="flutter_bootstrap.js"></script>
  </head>
  <body>
    <div id="Content" style="display:none" aria-hidden="true"></div>
  </body>
</html>
''';
      frame.srcdoc =
          buildLotusWebDocument(
            sourceHtml: sourceHtml,
            assetBaseUrl: Uri.base.resolve('assets/assets/lotus/').toString(),
            bridgeToken: bridgeToken,
            initialStorage: const <String, String>{},
            injectedScripts: <String>[
              lotusInjectedContractScript,
              lotusInjectedVisualSkinScript,
              lotusShellCleanupScript,
            ],
          ).toJS;
      web.document.body!.appendChild(frame);

      final readyMessage = await ready.future.timeout(
        const Duration(seconds: 12),
      );
      expect(readyMessage['runtimeReady'], isA<bool>());

      frame.contentWindow!.postMessage(
        <String, Object?>{
          'manaloomLotusWeb': true,
          'token': bridgeToken,
          'kind': 'eval',
          'id': 1,
          'script': '''
(async () => {
  localStorage.clear();
  localStorage.setItem('lotusOnly', 'yes');
  const settings = document.createElement('section');
  settings.className = 'settings-overlay';
  settings.innerHTML = '<h1>Settings</h1><button>Restart Game</button><button>Cancel</button>';
  document.body.appendChild(settings);
  const dice = document.createElement('section');
  dice.className = 'dice-overlay';
  dice.innerHTML = `
    <div class="rng-list">
      <div class="roller d20"></div>
      <div class="roller custom">
        <input value="5000">
        <div class="roll-btn">Roll</div>
      </div>
    </div>
    <button class="close-dice-overlay-btn"></button>
  `;
  document.body.appendChild(dice);
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  const customDiceInput = dice.querySelector('.roller.custom input');
  const horizontalCard = document.createElement('section');
  horizontalCard.className = 'player-card rotate-left';
  horizontalCard.style.setProperty('--width', '200px');
  horizontalCard.style.setProperty('--height', '100px');
  horizontalCard.style.setProperty('--aspect-ratio-card', '0.5');
  const horizontalInner = document.createElement('div');
  horizontalInner.className = 'player-card-inner';
  horizontalInner.innerHTML = `
    <div class="decrease-button life">−</div>
    <div class="player-life-count">40</div>
    <div class="increase-button life">+</div>
    <div class="counters-on-card"><div class="counter poison">2</div></div>
  `;
  horizontalCard.appendChild(horizontalInner);
  document.body.appendChild(horizontalCard);
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  const horizontalInnerStyle = getComputedStyle(horizontalInner);
  const horizontalLifeStyle = getComputedStyle(
    horizontalInner.querySelector('.player-life-count'),
  );
  const horizontalCardTransform = horizontalInnerStyle.transform;
  horizontalInner.style.transform = 'translateY(25px)';
  const horizontalSwipeTransform = getComputedStyle(horizontalInner).transform;
  horizontalInner.style.removeProperty('transform');
  const horizontalResetTransform = getComputedStyle(horizontalInner).transform;
  const horizontalPreview = document.createElement('div');
  horizontalPreview.style.position = 'absolute';
  horizontalPreview.style.height = '50px';
  horizontalPreview.style.width = 'auto';
  horizontalPreview.style.aspectRatio = 'var(--aspect-ratio-card)';
  horizontalCard.appendChild(horizontalPreview);
  const horizontalPreviewStyle = getComputedStyle(horizontalPreview);
  return JSON.stringify({
    playerCards: document.querySelectorAll('.player-card').length,
    visualSkin: !!document.getElementById('manaloom-lotus-visual-skin'),
    contract: !!window.__ManaLoomLotusContract,
    localizedControls: Array.from(settings.querySelectorAll('h1, button')).map((node) => node.textContent.trim()),
    diceDialogLabel: dice.getAttribute('aria-label'),
    d20Label: dice.querySelector('.roller.d20')?.getAttribute('aria-label'),
    customRollLabel: dice.querySelector('.roll-btn')?.getAttribute('aria-label'),
    customDiceInputLabel: customDiceInput?.getAttribute('aria-label'),
    customDiceValue: customDiceInput?.value,
    customDiceMin: customDiceInput?.getAttribute('min'),
    customDiceMax: customDiceInput?.getAttribute('max'),
    horizontalCardTransform,
    horizontalSwipeTransform,
    horizontalResetTransform,
    horizontalCardWidth: horizontalInnerStyle.width,
    horizontalCardHeight: horizontalInnerStyle.height,
    horizontalLifeWritingMode: horizontalLifeStyle.writingMode,
    horizontalCardAspectRatio: getComputedStyle(horizontalCard)
      .getPropertyValue('--aspect-ratio-card').trim(),
    horizontalPreviewAspectRatio: horizontalPreviewStyle.aspectRatio,
    horizontalPreviewWidth: horizontalPreviewStyle.width,
    horizontalPreviewHeight: horizontalPreviewStyle.height,
  });
})()
''',
        }.jsify(),
        '*'.toJS,
      );
      final rawProbe = await evaluation.future.timeout(
        const Duration(seconds: 3),
      );
      final probe = jsonDecode(rawProbe! as String) as Map<String, dynamic>;
      expect(probe['playerCards'], isA<int>());
      expect(probe['visualSkin'], isTrue);
      expect(probe['contract'], isTrue);
      expect(probe['localizedControls'], <String>[
        'Configurações',
        'Reiniciar partida',
        'Cancelar',
      ]);
      expect(probe['diceDialogLabel'], 'Dados');
      expect(probe['d20Label'], 'Rolar dado de 20 lados');
      expect(probe['customRollLabel'], 'Rolar dado personalizado');
      expect(
        probe['customDiceInputLabel'],
        'Número de lados do dado personalizado',
      );
      expect(probe['customDiceValue'], '999');
      expect(probe['customDiceMin'], '2');
      expect(probe['customDiceMax'], '999');
      expect(probe['horizontalCardTransform'], 'none');
      expect(probe['horizontalSwipeTransform'], isNot('none'));
      expect(probe['horizontalResetTransform'], 'none');
      expect(probe['horizontalCardWidth'], '200px');
      expect(probe['horizontalCardHeight'], '100px');
      expect(probe['horizontalLifeWritingMode'], 'horizontal-tb');
      expect(probe['horizontalCardAspectRatio'], '2');
      expect(probe['horizontalPreviewAspectRatio'], '2 / 1');
      expect(probe['horizontalPreviewWidth'], '100px');
      expect(probe['horizontalPreviewHeight'], '50px');
      expect(web.window.localStorage.getItem(hostSentinelKey), 'keep');
      expect(persistedValues?['lotusOnly'], 'yes');
      expect(persistedValues, isNot(contains(hostSentinelKey)));
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'web host mirrors the Lotus board into canonical app state',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LifeCounterSessionStore().save(
        LifeCounterSession.initial(playerCount: 4),
      );
      final controller = LotusWebHostController(
        onAppReviewRequested: (_) {},
        onShellMessageRequested: (_) {},
        sourceHtmlLoader:
            () async => '''
<!doctype html>
<html lang="en" style="background:#000">
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
    <meta charset="utf-8">
    <title>ManaLoom Life Counter</title>
    <script>
      window.__ManaloomLotusStorageBridge = {
        flushSnapshot: () => ({ ok: true }),
        receivePatch: (payload) => {
          const values = payload && payload.values ? payload.values : {};
          Object.entries(values).forEach(([key, value]) => {
            if (value === null) localStorage.removeItem(key);
            else localStorage.setItem(key, value);
          });
          return { ok: true };
        },
      };
      document.addEventListener('DOMContentLoaded', () => {
        for (let index = 0; index < 4; index += 1) {
          const player = document.createElement('section');
          player.className = 'player-card';
          player.dataset.playerId = String(index);
          document.body.appendChild(player);
        }
      });
    </script>
  </head>
  <body>
    <div id="Content" style="display:none" aria-hidden="true"></div>
  </body>
</html>
''',
      );
      addTearDown(() {
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();

      await controller.loadBundle();
      final playerCount = await controller.runJavaScriptReturningResult('''
(() => {
  const players = JSON.parse(localStorage.getItem('players') || '[]');
  if (!players.length) return 0;
  players[0].life = 37;
  localStorage.setItem('players', JSON.stringify(players));
  return players.length;
})()
''');
      expect((playerCount as num).toInt(), greaterThanOrEqualTo(2));
      expect(
        await controller.flushStorageSnapshot(reason: 'web_runtime_test'),
        isTrue,
      );

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.lives.first, 37);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  test(
    'pending browser mirror survives immediate reload and repairs canonical state',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      final pendingSession = canonicalSession.copyWith(
        lives: const <int>[41, 40, 40, 40],
      );
      final canonicalValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(canonicalSession);
      final pendingValues = LotusLifeCounterSessionAdapter.buildSnapshotValues(
        pendingSession,
      );
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(values: canonicalValues),
      );
      web.window.localStorage
        ..setItem(lotusWebStorageKey, jsonEncode(pendingValues))
        ..setItem(
          lotusWebStoragePendingFingerprintKey,
          _lotusWebStorageFingerprint(pendingValues),
        );

      final controller = _createLotusRuntimeController();
      addTearDown(() {
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();

      await controller.loadBundle();

      expect(controller.errorMessage.value, isNull);
      expect(await _readFirstPlayerLife(controller), 41);
      final repairedSession = await LifeCounterSessionStore().load();
      final repairedSnapshot = await LotusStorageSnapshotStore().load();
      expect(repairedSession?.lives.first, 41);
      expect(repairedSnapshot!.values['players'], pendingValues['players']);
      expect(
        web.window.localStorage.getItem(lotusWebStoragePendingFingerprintKey),
        isNull,
      );
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  test(
    'browser mirror without a pending journal cannot override canonical state',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      final staleBrowserSession = canonicalSession.copyWith(
        lives: const <int>[41, 40, 40, 40],
      );
      final canonicalValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(canonicalSession);
      final staleBrowserValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(
            staleBrowserSession,
          );
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(values: canonicalValues),
      );
      web.window.localStorage.setItem(
        lotusWebStorageKey,
        jsonEncode(staleBrowserValues),
      );

      final controller = _createLotusRuntimeController();
      addTearDown(() {
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();

      await controller.loadBundle();

      expect(controller.errorMessage.value, isNull);
      expect(await _readFirstPlayerLife(controller), 40);
      expect((await LifeCounterSessionStore().load())?.lives.first, 40);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  test(
    'real host journal recovers a life change before its mirror completes',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(
          values: LotusLifeCounterSessionAdapter.buildSnapshotValues(
            canonicalSession,
          ),
        ),
      );
      final mirrorBlocked = Completer<void>();
      final releaseMirror = Completer<void>();
      final firstController = _createLotusRuntimeController(
        canonicalMirrorBarrierForTesting: (values) async {
          final session = LotusLifeCounterSessionAdapter.tryBuildSession(
            LotusStorageSnapshot(values: values),
          );
          if (session?.lives.first != 41) {
            return;
          }
          if (!mirrorBlocked.isCompleted) {
            mirrorBlocked.complete();
          }
          await releaseMirror.future;
        },
      );
      LotusWebHostController? recoveryController;
      addTearDown(() {
        if (!releaseMirror.isCompleted) {
          releaseMirror.complete();
        }
        firstController.dispose();
        recoveryController?.dispose();
        _clearLotusHostStorage();
      });
      firstController.mountFrameForTesting();
      await firstController.loadBundle();

      expect(
        await firstController.runJavaScriptReturningResult('''
(() => {
  const players = JSON.parse(localStorage.getItem('players') || '[]');
  players[0].life = 41;
  localStorage.setItem('players', JSON.stringify(players));
  return players[0].life;
})()
'''),
        41,
      );
      await mirrorBlocked.future.timeout(const Duration(seconds: 3));
      final pendingValues = _readLotusHostStorage();
      expect(
        web.window.localStorage.getItem(lotusWebStoragePendingFingerprintKey),
        _lotusWebStorageFingerprint(pendingValues),
      );
      expect(
        LotusLifeCounterSessionAdapter.tryBuildSession(
          LotusStorageSnapshot(values: pendingValues),
        )?.lives.first,
        41,
      );

      firstController.dispose();
      recoveryController = _createLotusRuntimeController();
      recoveryController.mountFrameForTesting();
      await recoveryController.loadBundle();

      expect(recoveryController.errorMessage.value, isNull);
      expect(await _readFirstPlayerLife(recoveryController), 41);
      expect(
        await recoveryController.flushStorageSnapshot(
          reason: 'immediate_reload_recovery_test',
        ),
        isTrue,
      );
      expect((await LifeCounterSessionStore().load())?.lives.first, 41);
      expect(
        web.window.localStorage.getItem(lotusWebStoragePendingFingerprintKey),
        isNull,
      );
      releaseMirror.complete();
      await firstController.settleStorageMirrorForTesting();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'intentional canonical mutation invalidates an older pending journal',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(
          values: LotusLifeCounterSessionAdapter.buildSnapshotValues(
            canonicalSession,
          ),
        ),
      );
      final controller = _createLotusRuntimeController();
      addTearDown(() {
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();
      await controller.loadBundle();
      await controller.flushStorageSnapshot(reason: 'mutation_test_boot');

      final staleBrowserValues =
          LotusLifeCounterSessionAdapter.buildSnapshotValues(
            canonicalSession.copyWith(lives: const <int>[41, 40, 40, 40]),
          );
      web.window.localStorage
        ..setItem(lotusWebStorageKey, jsonEncode(staleBrowserValues))
        ..setItem(
          lotusWebStoragePendingFingerprintKey,
          _lotusWebStorageFingerprint(staleBrowserValues),
        );

      final updated = await controller.mutateCanonicalStorageAndRebase(
        mutation: () {
          return LifeCounterSessionStore().save(
            canonicalSession.copyWith(lives: const <int>[42, 40, 40, 40]),
          );
        },
        reason: 'canonical_mutation_wins_test',
      );

      expect(updated, isTrue);
      expect(await _readFirstPlayerLife(controller), 42);
      expect((await LifeCounterSessionStore().load())?.lives.first, 42);
      expect(
        web.window.localStorage.getItem(lotusWebStoragePendingFingerprintKey),
        isNull,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'stale iframe storage cannot overwrite an in-flight canonical mutation',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(
          values: LotusLifeCounterSessionAdapter.buildSnapshotValues(
            canonicalSession,
          ),
        ),
      );
      final mutationSaved = Completer<void>();
      final releaseCanonicalRebase = Completer<void>();
      final controller = _createLotusRuntimeController(
        canonicalMutationAfterMutationBarrierForTesting: () async {
          mutationSaved.complete();
          await releaseCanonicalRebase.future;
        },
      );
      addTearDown(() {
        if (!releaseCanonicalRebase.isCompleted) {
          releaseCanonicalRebase.complete();
        }
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();
      await controller.loadBundle();

      final mutationFuture = controller.mutateCanonicalStorageAndRebase(
        mutation: () {
          return LifeCounterSessionStore().save(
            canonicalSession.copyWith(lives: const <int>[42, 40, 40, 40]),
          );
        },
        reason: 'stale_iframe_race_test',
      );
      await mutationSaved.future.timeout(const Duration(seconds: 3));

      expect(
        await controller.runJavaScriptReturningResult('''
(() => {
  const players = JSON.parse(localStorage.getItem('players') || '[]');
  players[0].life = 41;
  localStorage.setItem('players', JSON.stringify(players));
  return players[0].life;
})()
'''),
        41,
      );
      releaseCanonicalRebase.complete();

      expect(await mutationFuture, isTrue);
      expect(await _readFirstPlayerLife(controller), 42);
      expect((await LifeCounterSessionStore().load())?.lives.first, 42);
      expect(
        LotusLifeCounterSessionAdapter.tryBuildSession(
          LotusStorageSnapshot(values: _readLotusHostStorage()),
        )?.lives.first,
        42,
      );
      expect(
        web.window.localStorage.getItem(lotusWebStoragePendingFingerprintKey),
        isNull,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'failed live patch reloads from canonical state before accepting storage',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(
          values: LotusLifeCounterSessionAdapter.buildSnapshotValues(
            canonicalSession,
          ),
        ),
      );
      final controller = _createLotusRuntimeController(
        sourceHtml: _lotusRuntimeSourceHtml.replaceFirst(
          'return { ok: true };',
          'return { ok: false };',
        ),
      );
      addTearDown(() {
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();
      await controller.loadBundle();

      final updated = await controller.mutateCanonicalStorageAndRebase(
        mutation: () {
          return LifeCounterSessionStore().save(
            canonicalSession.copyWith(lives: const <int>[42, 40, 40, 40]),
          );
        },
        reason: 'failed_patch_reload_test',
      );

      expect(updated, isFalse);
      expect(controller.errorMessage.value, isNull);
      expect(await _readFirstPlayerLife(controller), 42);
      expect((await LifeCounterSessionStore().load())?.lives.first, 42);
      expect(
        LotusLifeCounterSessionAdapter.tryBuildSession(
          LotusStorageSnapshot(values: _readLotusHostStorage()),
        )?.lives.first,
        42,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'early fallback load failure rejects delayed storage from stale iframe',
    () async {
      _clearLotusHostStorage();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final canonicalSession = LifeCounterSession.initial(playerCount: 4);
      await LifeCounterSessionStore().save(canonicalSession);
      await LotusStorageSnapshotStore().save(
        LotusStorageSnapshot(
          values: LotusLifeCounterSessionAdapter.buildSnapshotValues(
            canonicalSession,
          ),
        ),
      );
      final staleStorageSource = _lotusRuntimeSourceHtml.replaceFirst(
        'return { ok: true };',
        '''
          setTimeout(() => {
            const stalePlayers = JSON.parse(localStorage.getItem('players') || '[]');
            stalePlayers[0].life = 41;
            localStorage.setItem('players', JSON.stringify(stalePlayers));
          }, 100);
          return { ok: false };
        ''',
      );
      var sourceLoadCount = 0;
      final controller = _createLotusRuntimeController(
        sourceHtmlLoader: () async {
          sourceLoadCount += 1;
          if (sourceLoadCount == 1) {
            return staleStorageSource;
          }
          throw StateError('forced early fallback load failure');
        },
      );
      addTearDown(() {
        controller.dispose();
        _clearLotusHostStorage();
      });
      controller.mountFrameForTesting();
      await controller.loadBundle();

      final updated = await controller.mutateCanonicalStorageAndRebase(
        mutation: () {
          return LifeCounterSessionStore().save(
            canonicalSession.copyWith(lives: const <int>[42, 40, 40, 40]),
          );
        },
        reason: 'failed_early_fallback_load_test',
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(updated, isFalse);
      expect(controller.errorMessage.value, isNotNull);
      expect((await LifeCounterSessionStore().load())?.lives.first, 42);
      expect(
        LotusLifeCounterSessionAdapter.tryBuildSession(
          LotusStorageSnapshot(values: _readLotusHostStorage()),
        )?.lives.first,
        42,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

LotusWebHostController _createLotusRuntimeController({
  Future<void> Function(Map<String, String>)? canonicalMirrorBarrierForTesting,
  Future<void> Function()? canonicalMutationAfterMutationBarrierForTesting,
  String sourceHtml = _lotusRuntimeSourceHtml,
  Future<String> Function()? sourceHtmlLoader,
}) {
  return LotusWebHostController(
    onAppReviewRequested: (_) {},
    onShellMessageRequested: (_) {},
    sourceHtmlLoader: sourceHtmlLoader ?? () async => sourceHtml,
    canonicalMirrorBarrierForTesting: canonicalMirrorBarrierForTesting,
    canonicalMutationAfterMutationBarrierForTesting:
        canonicalMutationAfterMutationBarrierForTesting,
  );
}

Future<int> _readFirstPlayerLife(LotusWebHostController controller) async {
  final rawLife = await controller.runJavaScriptReturningResult('''
(() => {
  const players = JSON.parse(localStorage.getItem('players') || '[]');
  return players.length ? players[0].life : -1;
})()
''');
  return (rawLife as num).toInt();
}

String _lotusWebStorageFingerprint(Map<String, String> values) {
  return sha256
      .convert(utf8.encode(lotusStorageValuesFingerprint(values)))
      .toString();
}

void _clearLotusHostStorage() {
  web.window.localStorage
    ..removeItem(lotusWebStorageKey)
    ..removeItem(lotusWebStoragePendingFingerprintKey);
}

Map<String, String> _readLotusHostStorage() {
  final raw = web.window.localStorage.getItem(lotusWebStorageKey);
  final decoded = jsonDecode(raw!) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, value as String));
}

const String _lotusRuntimeSourceHtml = '''
<!doctype html>
<html lang="en" style="background:#000">
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
    <meta charset="utf-8">
    <title>ManaLoom Life Counter</title>
    <script>
      window.__ManaloomLotusStorageBridge = {
        flushSnapshot: () => ({ ok: true }),
        receivePatch: (payload) => {
          const values = payload && payload.values ? payload.values : {};
          Object.entries(values).forEach(([key, value]) => {
            if (value === null) localStorage.removeItem(key);
            else localStorage.setItem(key, value);
          });
          return { ok: true };
        },
      };
      document.addEventListener('DOMContentLoaded', () => {
        for (let index = 0; index < 4; index += 1) {
          const player = document.createElement('section');
          player.className = 'player-card';
          player.dataset.playerId = String(index);
          document.body.appendChild(player);
        }
      });
    </script>
  </head>
  <body>
    <div id="Content" style="display:none" aria-hidden="true"></div>
  </body>
</html>
''';
