import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';
import 'package:manaloom/features/battle/screens/battle_coach_screen.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';

class _FakeInteractiveGateway implements InteractiveBattleGateway {
  int getCount = 0;
  final List<InteractiveBattleResponse> responses = [];

  @override
  Future<InteractiveBattleSession> create({
    required String deckId,
    required String opponentDeckId,
    int ttlSeconds = 1800,
    int promptTimeoutSeconds = 90,
  }) async => _waitingSession();

  @override
  Future<InteractiveBattleSession> get(String sessionId) async {
    getCount += 1;
    return _waitingSession();
  }

  @override
  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  }) async {
    responses.add(response);
    return _terminalSession();
  }

  @override
  Future<InteractiveBattleSession> concede(String sessionId) async =>
      _terminalSession(status: 'conceded');
}

void main() {
  testWidgets('shows a clear opt-in welcome before creating a session', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(_FakeInteractiveGateway()));
    await tester.pump();

    expect(find.byKey(const Key('battle-coach-welcome-state')), findsOneWidget);
    expect(find.text('Jogue as decisões que importam'), findsOneWidget);
    expect(
      find.byKey(const Key('battle-coach-choose-opponent-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resumes, renders private state, and submits a prompt choice', (
    tester,
  ) async {
    final gateway = _FakeInteractiveGateway();
    await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
    await tester.pump();
    await tester.pump();

    expect(gateway.getCount, 1);
    expect(find.byKey(const Key('battle-coach-board')), findsOneWidget);
    expect(find.byKey(const Key('battle-coach-own-hand')), findsOneWidget);
    expect(find.text('Sua prioridade'), findsWidgets);
    expect(find.text('Mão adversária privada'), findsNothing);
    expect(find.textContaining('Opponent'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('battle-coach-option-o_abcdefghijklmnop')),
    );
    await tester.pump();
    await tester.pump();

    expect(gateway.responses, hasLength(1));
    expect(
      find.byKey(const Key('battle-coach-terminal-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-coach-open-replay-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keeps the interactive table overflow-free across web widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _subject(_FakeInteractiveGateway(), sessionId: 'session-1'),
      );
      await tester.pump();
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Battle Coach must fit ${size.width} px.',
      );
      expect(find.byKey(const Key('battle-coach-board')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('disables decorative motion when accessibility requests it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(
        _FakeInteractiveGateway(),
        sessionId: 'session-1',
        disableAnimations: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
    expect(
      tester
          .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
    expect(
      tester
          .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _subject(
  InteractiveBattleGateway gateway, {
  String? sessionId,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: AppTheme.darkTheme.copyWith(splashFactory: InkRipple.splashFactory),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: BattleCoachScreen(
    deckId: '00000000-0000-4000-8000-000000000001',
    sessionId: sessionId,
    gateway: gateway,
    pollInterval: const Duration(hours: 1),
  ),
);

InteractiveBattleSession _waitingSession() =>
    InteractiveBattleSession.fromJson({
      'schema_version': 'interactive_battle_session_v1',
      'id': 'session-1',
      'status': 'waiting_for_action',
      'state_version': 7,
      'deck_id': '00000000-0000-4000-8000-000000000001',
      'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
      'expires_at': '2099-07-27T15:30:00Z',
      'updated_at': '2026-07-27T15:00:00Z',
      'private_state': {
        'turn': 1,
        'phase': 'BEGINNING',
        'step': 'UPKEEP',
        'priority_player': 'ManaLoom',
        'own_player': 'ManaLoom',
        'players': [
          {
            'name': 'ManaLoom',
            'life': 40,
            'library_count': 92,
            'hand_count': 7,
            'battlefield': const <dynamic>[],
            'graveyard': const <dynamic>[],
            'exile': const <dynamic>[],
            'command': const <dynamic>[],
          },
          {
            'name': 'Opponent',
            'life': 40,
            'library_count': 91,
            'hand_count': 8,
            'battlefield': const <dynamic>[],
            'graveyard': const <dynamic>[],
            'exile': const <dynamic>[],
            'command': const <dynamic>[],
          },
        ],
        'stack': const <dynamic>[],
        'combat': const <dynamic>[],
        'own_hand': const <dynamic>[],
      },
      'prompt': {
        'schema_version': 'interactive_battle_prompt_v1',
        'id': 'p_abcdefghijklmnop',
        'state_version': 7,
        'kind': 'mulligan',
        'input_mode': 'options',
        'title': 'Sua prioridade',
        'message': 'Manter esta mão?',
        'deadline_at': '2099-07-27T15:01:00Z',
        'options': [
          {
            'id': 'o_abcdefghijklmnop',
            'label': 'Manter esta mão',
            'role': 'keep',
          },
        ],
      },
    });

InteractiveBattleSession _terminalSession({String status = 'completed'}) =>
    InteractiveBattleSession.fromJson({
      'schema_version': 'interactive_battle_session_v1',
      'id': 'session-1',
      'status': status,
      'state_version': 8,
      'deck_id': '00000000-0000-4000-8000-000000000001',
      'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
      'expires_at': '2099-07-27T15:30:00Z',
      'updated_at': '2026-07-27T15:02:00Z',
      'replay_id': 'replay-1',
      'private_state': {
        'turn': 1,
        'players': const <dynamic>[],
        'stack': const <dynamic>[],
        'combat': const <dynamic>[],
        'own_hand': const <dynamic>[],
      },
    });
