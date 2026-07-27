import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';
import 'package:manaloom/features/battle/screens/battle_coach_screen.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart' show resetVisualCaptureSurface;

const _sourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _profile = String.fromEnvironment(
  'MANALOOM_UI_PROOF_PROFILE',
  defaultValue: 'android_phone',
);
const _deviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
  defaultValue: 'physical_android',
);

const _checkpoints = <String>[
  'battle_coach_00_welcome',
  'battle_coach_01_active_table',
  'battle_coach_02_decision_prompt',
  'battle_coach_03_recoverable_error',
  'battle_coach_04_concede_confirmation',
  'battle_coach_05_action_progress',
  'battle_coach_06_terminal_replay',
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'Battle Coach produces current real-runtime visual and interaction proof',
    (tester) async {
      expect(
        _sourceDigest,
        matches(RegExp(r'^[0-9a-f]{64}$')),
        reason:
            'The proof must be bound to the current UI source digest through '
            '--dart-define=MANALOOM_UI_SOURCE_DIGEST=<sha256>.',
      );
      expect(_profile, isNotEmpty);
      expect(_deviceContract, isNotEmpty);

      // Consumed by tool/ui_runtime_evidence.dart. This contains no credential,
      // API URL, user data or private gameplay payload.
      // ignore: avoid_print
      print(
        'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'battle_coach', 'source_digest': _sourceDigest, 'profile': _profile, 'runtime': 'flutter_integration_test', 'target': 'android_physical', 'device_contract': _deviceContract, 'required_checkpoints': _checkpoints})}',
      );

      final gateway = _BattleCoachProofGateway();
      await _pumpSubject(tester, gateway, sessionId: 'session-proof');
      await pumpUntilFound(tester, find.byKey(const Key('battle-coach-board')));
      expect(find.text('Mão adversária privada'), findsNothing);
      expectNoRawTechnicalErrorText(tester);
      expect(tester.takeException(), isNull);
      await _waitForRenderedCardArt(tester);
      await _capture(binding, tester, _checkpoints[1]);

      final choice = find.byKey(
        const Key('battle-coach-option-o_cast_counterspell'),
      );
      await tester.ensureVisible(choice);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Sua prioridade'), findsWidgets);
      expect(find.text('60s'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(binding, tester, _checkpoints[2]);

      gateway.failNextGet = true;
      await tester.tap(
        find.byKey(const Key('battle-coach-refresh-button')),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.byKey(const Key('battle-coach-error-banner')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Não foi possível atualizar esta mesa.'),
        findsOneWidget,
      );
      expectNoRawTechnicalErrorText(tester);
      expect(tester.takeException(), isNull);
      await _capture(binding, tester, _checkpoints[3]);

      await tester.tap(
        find.byKey(const Key('battle-coach-error-banner')),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('battle-coach-error-banner')), findsNothing);

      await tester.tap(
        find.byKey(const Key('battle-coach-concede-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Conceder esta partida?'), findsOneWidget);
      expect(
        find.byKey(const Key('battle-coach-confirm-concede-button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _capture(binding, tester, _checkpoints[4]);
      await tester.tap(find.text('Continuar jogando'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(choice);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(choice);
      await tester.pump();
      expect(
        find.byKey(const Key('battle-coach-action-progress')),
        findsOneWidget,
      );
      expect(gateway.responses, hasLength(1));
      expect(tester.takeException(), isNull);
      await _capture(binding, tester, _checkpoints[5]);

      gateway.completeAction();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('battle-coach-terminal-panel')),
      );
      expect(
        find.byKey(const Key('battle-coach-open-replay-button')),
        findsOneWidget,
      );
      expect(find.text('Partida concluída'), findsWidgets);
      expect(find.text('Turno 7 · Principal pós-combate'), findsOneWidget);
      expect(
        find.textContaining('Principal pós-combate · Principal'),
        findsNothing,
      );
      expectNoRawTechnicalErrorText(tester);
      expect(tester.takeException(), isNull);
      await _capture(binding, tester, _checkpoints[6]);
    },
  );

  testWidgets(
    'Battle Coach captures the explicit opt-in welcome independently',
    (tester) async {
      resetVisualCaptureSurface();
      await _pumpSubject(tester, _BattleCoachProofGateway());
      expect(
        find.byKey(const Key('battle-coach-welcome-state')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-coach-choose-opponent-button')),
        findsOneWidget,
      );
      await _capture(binding, tester, _checkpoints[0]);
    },
  );
}

Future<void> _pumpSubject(
  WidgetTester tester,
  InteractiveBattleGateway gateway, {
  String? sessionId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        splashFactory: InkRipple.splashFactory,
      ),
      home: BattleCoachScreen(
        deckId: '00000000-0000-4000-8000-000000000001',
        sessionId: sessionId,
        gateway: gateway,
        pollInterval: const Duration(hours: 1),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  expect(tester.takeException(), isNull, reason: 'Before checkpoint $name');
  await captureRuntimeCheckpoint(binding, tester, name);
  expect(tester.takeException(), isNull, reason: 'After checkpoint $name');
}

Future<void> _waitForRenderedCardArt(WidgetTester tester) async {
  final renderedCardArt = find.descendant(
    of: find.byKey(const Key('battle-coach-board')),
    matching: find.byType(RawImage),
  );
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 120));
    if (renderedCardArt.evaluate().length >= 3) {
      return;
    }
  }
  fail(
    'Battle Coach did not render at least three real card artworks within '
    'the live-proof window.',
  );
}

class _BattleCoachProofGateway implements InteractiveBattleGateway {
  final List<InteractiveBattleResponse> responses = [];
  bool failNextGet = false;
  Completer<InteractiveBattleSession>? _pendingAction;

  @override
  Future<InteractiveBattleSession> create({
    required String deckId,
    required String opponentDeckId,
    int ttlSeconds = 1800,
    int promptTimeoutSeconds = 90,
  }) async => _waitingSession();

  @override
  Future<InteractiveBattleSession> get(String sessionId) async {
    if (failNextGet) {
      failNextGet = false;
      throw Exception(
        'DioException: transport payload must never reach the player',
      );
    }
    return _waitingSession();
  }

  @override
  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  }) {
    responses.add(response);
    _pendingAction = Completer<InteractiveBattleSession>();
    return _pendingAction!.future;
  }

  @override
  Future<InteractiveBattleSession> concede(String sessionId) async =>
      _terminalSession(status: 'conceded');

  void completeAction() {
    final pending = _pendingAction;
    if (pending == null || pending.isCompleted) return;
    pending.complete(_terminalSession());
  }
}

InteractiveBattleSession
_waitingSession() => InteractiveBattleSession.fromJson({
  'schema_version': 'interactive_battle_session_v1',
  'id': 'session-proof',
  'status': 'waiting_for_action',
  'state_version': 12,
  'deck_id': '00000000-0000-4000-8000-000000000001',
  'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
  'expires_at': '2099-07-27T15:30:00Z',
  'updated_at': '2026-07-27T15:00:00Z',
  'private_state': {
    'turn': 6,
    'phase': 'COMBAT',
    'step': 'DECLARE_ATTACKERS',
    'active_player': 'ManaLoom',
    'priority_player': 'ManaLoom',
    'own_player': 'ManaLoom',
    'priority_time_seconds': 60,
    'players': [
      {
        'name': 'ManaLoom',
        'life': 31,
        'library_count': 78,
        'hand_count': 5,
        'battlefield': [
          _card(
            'c_urza',
            'Urza, Lord High Artificer',
            image:
                'https://cards.scryfall.io/normal/front/7/b/7b7a348a-51f7-4dc5-8fe7-1c70fea5e050.jpg?1761053659',
          ),
          _card('c_ring', 'Sol Ring', tapped: true),
          _card(
            'c_construct',
            'Construct',
            counters: const [
              {'name': '+1/+1', 'count': 2},
            ],
          ),
        ],
        'graveyard': [_card('c_countered', 'Arcane Denial')],
        'exile': const <dynamic>[],
        'command': [_card('c_commander', 'Urza, Lord High Artificer')],
      },
      {
        'name': 'Krenko Mob',
        'life': 26,
        'library_count': 72,
        'hand_count': 4,
        'battlefield': [
          _card('c_krenko', 'Krenko, Mob Boss', tapped: true, damage: 1),
          _card('c_goblin', 'Goblin Instigator'),
          _card('c_signet', 'Arcane Signet'),
        ],
        'graveyard': [_card('c_bolt', 'Lightning Bolt')],
        'exile': const <dynamic>[],
        'command': [_card('c_enemy_commander', 'Krenko, Mob Boss')],
      },
    ],
    'stack': [_card('c_stack', 'Counterspell')],
    'combat': [
      {
        'defender_name': 'Krenko Mob',
        'blocked': true,
        'attackers': [_card('c_attacker', 'Construct')],
        'blockers': [_card('c_blocker', 'Goblin Instigator')],
      },
    ],
    'own_hand': [
      _card('c_hand_1', 'Swan Song'),
      _card('c_hand_2', 'Cyclonic Rift'),
      _card('c_hand_3', 'Island'),
      _card('c_hand_4', 'Mystic Remora'),
      _card('c_hand_5', 'Thought Vessel'),
    ],
  },
  'prompt': {
    'schema_version': 'interactive_battle_prompt_v1',
    'id': 'p_priority_counterspell',
    'state_version': 12,
    'kind': 'priority',
    'input_mode': 'options',
    'title': 'Sua prioridade',
    'message':
        'Counterspell está na pilha. Escolha uma resposta legal ou passe '
        'a prioridade.',
    'deadline_at': '2099-07-27T15:01:00Z',
    'options': [
      {
        'id': 'o_cast_counterspell',
        'label': 'Conjurar Swan Song',
        'role': 'choice',
        'card': _card('c_option', 'Swan Song'),
      },
      {'id': 'o_pass_priority', 'label': 'Passar prioridade', 'role': 'done'},
    ],
  },
});

InteractiveBattleSession _terminalSession({String status = 'completed'}) =>
    InteractiveBattleSession.fromJson({
      'schema_version': 'interactive_battle_session_v1',
      'id': 'session-proof',
      'status': status,
      'state_version': 13,
      'deck_id': '00000000-0000-4000-8000-000000000001',
      'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
      'expires_at': '2099-07-27T15:30:00Z',
      'updated_at': '2026-07-27T15:02:00Z',
      'replay_id': 'replay-proof',
      'terminal_reason': status == 'completed' ? 'normal' : status,
      'private_state': {
        'turn': 7,
        'phase': 'POSTCOMBAT_MAIN',
        'step': 'MAIN',
        'priority_player': 'ManaLoom',
        'own_player': 'ManaLoom',
        'players': [
          {
            'name': 'ManaLoom',
            'life': 31,
            'library_count': 77,
            'hand_count': 4,
            'battlefield': [_card('c_urza', 'Urza, Lord High Artificer')],
            'graveyard': [_card('c_song', 'Swan Song')],
            'exile': const <dynamic>[],
            'command': [_card('c_commander', 'Urza, Lord High Artificer')],
          },
          {
            'name': 'Krenko Mob',
            'life': 22,
            'library_count': 71,
            'hand_count': 4,
            'battlefield': [_card('c_krenko', 'Krenko, Mob Boss')],
            'graveyard': [_card('c_countered', 'Counterspell')],
            'exile': const <dynamic>[],
            'command': [_card('c_enemy_commander', 'Krenko, Mob Boss')],
          },
        ],
        'stack': const <dynamic>[],
        'combat': const <dynamic>[],
        'own_hand': [
          _card('c_hand_2', 'Cyclonic Rift'),
          _card('c_hand_3', 'Island'),
          _card('c_hand_4', 'Mystic Remora'),
          _card('c_hand_5', 'Thought Vessel'),
        ],
      },
    });

Map<String, dynamic> _card(
  String id,
  String name, {
  String? image,
  bool tapped = false,
  int damage = 0,
  List<Map<String, dynamic>> counters = const [],
}) => {
  'id': id,
  'name': name,
  if (image != null) 'image_url': image,
  'tapped': tapped,
  'damage': damage,
  'counters': counters,
};
