import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

import 'visual_capture_helpers.dart';

Future<Map<String, dynamic>> _readLotusCommanderSurface(
  dynamic screenState,
) async {
  dynamic decoded = await screenState.debugRunJavaScriptReturningResult('''
JSON.stringify({
  infoCards: document.querySelectorAll('.info-card').length,
  commanderCards: document.querySelectorAll('.commander-damage-card').length,
  damageValues: Array.from(
    document.querySelectorAll('.damage-display')
  ).map((node) => node.getAttribute('aria-valuenow')),
  returnToGameLabel:
    document.querySelector('.return-to-game-button')
      ?.getAttribute('aria-label') ?? null,
  lifeValues: Array.from(
    document.querySelectorAll('.player-life-count')
  ).map((node) => node.getAttribute('aria-valuenow')),
  killedPlayers: Array.from(
    document.querySelectorAll('.player-card')
  ).filter((card) => card.querySelector('.killed')).length,
})
''');

  for (var attempt = 0; attempt < 2 && decoded is String; attempt += 1) {
    decoded = jsonDecode(decoded);
  }
  expect(decoded, isA<Map>());
  return Map<String, dynamic>.from(decoded as Map);
}

Future<LifeCounterSession?> _pumpUntilCommanderDamageApplied(
  WidgetTester tester,
  LifeCounterSessionStore store,
) async {
  LifeCounterSession? session = await store.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.resolvedCommanderDamageDetails[0][1].totalDamage != 1);
    attempt += 1
  ) {
    await tester.pump(const Duration(seconds: 1));
    session = await store.load();
  }
  return session;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('opens the original Lotus commander surface and applies damage', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();

    await snapshotStore.clear();
    await LifeCounterSettingsStore().clear();
    await LifeCounterSessionStore().save(
      const LifeCounterSession(
        playerCount: 4,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 32, 25, 11],
        poison: [0, 0, 0, 0],
        energy: [0, 0, 0, 0],
        experience: [0, 0, 0, 0],
        commanderCasts: [0, 0, 0, 0],
        partnerCommanders: [false, true, false, false],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
        ],
        lastPlayerRolls: [null, null, null, null],
        lastHighRolls: [null, null, null, null],
        commanderDamage: [
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: null,
        turnTrackerActive: false,
        turnTrackerOngoingGame: false,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: null,
        currentTurnNumber: 1,
        turnTimerActive: false,
        turnTimerSeconds: 0,
        lastTableEvent: null,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
    await state.debugRunJavaScript('''
(() => {
  document.querySelector('.menu-button')?.click();
})()
''');
    await tester.pump(const Duration(milliseconds: 500));
    await state.debugRunJavaScript('''
(() => {
  document.querySelector('.manaloom-commander-damage-btn')?.click();
})()
''');
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Dano de comandante'), findsNothing);
    final openedSurface = await _readLotusCommanderSurface(state);
    expect(openedSurface['infoCards'], 1);
    expect(openedSurface['commanderCards'], 3);
    expect(openedSurface['damageValues'], ['0', '0', '0', '0']);
    expect(openedSurface['returnToGameLabel'], 'Voltar ao jogo');
    expect(openedSurface['lifeValues'], ['40', '32', '25', '11']);
    expect(openedSurface['killedPlayers'], 0);
    await captureVisualProof(
      binding,
      tester,
      'life_counter_commander_damage_sheet',
    );

    await state.debugRunJavaScript('''
(() => {
  const sourceCard = document.querySelectorAll('.player-card')[1];
  const button = sourceCard?.querySelector(
    '.commander-damage-card .increase-button.commander-damage'
  );
  const bounds = button?.getBoundingClientRect();
  if (button && bounds) {
    const eventInit = {
      bubbles: true,
      cancelable: true,
      pointerId: 41,
      pointerType: 'touch',
      isPrimary: true,
      button: 0,
      buttons: 1,
      clientX: bounds.left + bounds.width / 2,
      clientY: bounds.top + bounds.height / 2,
    };
    button.dispatchEvent(new PointerEvent('pointerdown', eventInit));
    button.dispatchEvent(new PointerEvent('pointerup', {
      ...eventInit,
      buttons: 0,
    }));
  }
})()
''');
    await tester.pump(const Duration(seconds: 2));

    final session = await _pumpUntilCommanderDamageApplied(
      tester,
      LifeCounterSessionStore(),
    );
    expect(session, isNotNull);
    expect(
      session!.resolvedCommanderDamageDetails[0][1],
      const LifeCounterCommanderDamageDetail(
        commanderOneDamage: 1,
        commanderTwoDamage: 0,
      ),
    );
    expect(session.lives[0], 39);

    final appliedSurface = await _readLotusCommanderSurface(state);
    expect(appliedSurface['damageValues'], ['1', '0', '0', '0']);
    expect(appliedSurface['lifeValues'], ['39', '32', '25', '11']);
    expect(appliedSurface['killedPlayers'], 0);

    await state.debugRunJavaScript(
      "document.querySelector('.return-to-game-button')?.click()",
    );
    await tester.pump(const Duration(milliseconds: 700));
    final closedSurface = await _readLotusCommanderSurface(state);
    expect(closedSurface['infoCards'], 0);
    expect(closedSurface['commanderCards'], 0);
  });
}
