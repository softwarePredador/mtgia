import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_default_host_web.dart';
import 'package:manaloom/features/home/lotus/lotus_shell_policy.dart';
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
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  return JSON.stringify({
    playerCards: document.querySelectorAll('.player-card').length,
    visualSkin: !!document.getElementById('manaloom-lotus-visual-skin'),
    contract: !!window.__ManaLoomLotusContract,
    localizedControls: Array.from(settings.querySelectorAll('h1, button')).map((node) => node.textContent.trim()),
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
      expect(web.window.localStorage.getItem(hostSentinelKey), 'keep');
      expect(persistedValues?['lotusOnly'], 'yes');
      expect(persistedValues, isNot(contains(hostSentinelKey)));
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'web host mirrors the Lotus board into canonical app state',
    () async {
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
      addTearDown(controller.dispose);
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
}
