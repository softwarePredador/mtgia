import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';
import 'package:manaloom/features/battle/screens/battle_coach_screen.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';
import 'package:manaloom/core/widgets/manaloom_theme_motif.dart';

class _FakeInteractiveGateway implements InteractiveBattleGateway {
  _FakeInteractiveGateway({InteractiveBattleSession? session})
    : session = session ?? _waitingSession();

  final InteractiveBattleSession session;
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
    return session;
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

class _FakeOpponentGateway extends BattleReplayService {
  @override
  Future<List<BattleOpponentDeck>> listOpponentDecks({
    required String currentDeckId,
  }) async => const [
    BattleOpponentDeck(
      id: '11111111-1111-4111-8111-111111111111',
      name: 'Atraxa de teste',
      format: 'commander',
      source: BattleOpponentDeckSource.own,
      commanderName: "Atraxa, Praetors' Voice",
      cardCount: 100,
    ),
  ];

  @override
  Future<BattlePreflight> loadBattlePreflight({
    required String deckId,
    required String opponentDeckId,
    bool interactive = false,
  }) async => const BattlePreflight(
    status: 'ready',
    cardCount: 100,
    commanderCount: 1,
    validationState: 'validated',
    availableOpponentCount: 1,
    engineCoverage: {'xmage': 'ready'},
    blockers: [],
    mode: 'interactive',
    selectedEngine: 'xmage',
  );
}

class _FallbackOpponentGateway extends _FakeOpponentGateway {
  int automaticRuns = 0;

  @override
  Future<BattlePreflight> loadBattlePreflight({
    required String deckId,
    required String opponentDeckId,
    bool interactive = false,
  }) async {
    if (interactive) {
      return const BattlePreflight(
        status: 'blocked',
        cardCount: 100,
        commanderCount: 1,
        validationState: 'validated',
        availableOpponentCount: 1,
        engineCoverage: {'xmage': 'unsupported'},
        blockers: ['engine_coverage_incomplete'],
        unsupportedCardNames: ['Lorehold, the Historian'],
        mode: 'interactive',
      );
    }
    return const BattlePreflight(
      status: 'ready',
      cardCount: 100,
      commanderCount: 1,
      validationState: 'validated',
      availableOpponentCount: 1,
      engineCoverage: {'forge': 'ready'},
      blockers: [],
      selectedEngine: 'forge',
    );
  }

  @override
  Future<BattleReplayDetail> runBattleTest({
    required String deckId,
    required BattleTestSetup setup,
    int maxTurns = 30,
  }) async {
    automaticRuns += 1;
    return BattleReplayDetail.fromJson(
      {
        'replay_id': 'fallback-replay',
        'type': 'battle',
        'deck_a_id': deckId,
        'deck_b_id': setup.opponentDeckId,
        'turns': 7,
        'events': const <dynamic>[],
      },
      fallbackDeckId: deckId,
      fallbackId: 'fallback-replay',
      source: 'battle_simulations',
    );
  }
}

void main() {
  testWidgets('shows a clear opt-in welcome before creating a session', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(_FakeInteractiveGateway()));
    await tester.pump();

    expect(find.byKey(const Key('battle-coach-welcome-state')), findsOneWidget);
    expect(find.text('Jogue as decisões que importam'), findsOneWidget);
    expect(find.text('MÃO · PILHA · CAMPO · PRIORIDADE'), findsOneWidget);
    expect(
      tester
          .widget<ManaLoomThemeMotif>(find.byType(ManaLoomThemeMotif))
          .variant,
      ManaLoomMotifVariant.battlefield,
    );
    expect(
      find.byKey(const Key('battle-coach-choose-opponent-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('battle-coach-alpha-banner')), findsOneWidget);
    expect(find.text('ALPHA'), findsOneWidget);
    expect(
      find.text('Experimental · decisões assistidas e suporte limitado'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('uses interactive copy and CTA in the Coach opponent picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(
        _FakeInteractiveGateway(),
        opponentGateway: _FakeOpponentGateway(),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('battle-coach-choose-opponent-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('battle-opponent-coach-description')),
      findsOneWidget,
    );
    expect(find.text('Iniciar Battle Coach'), findsOneWidget);
    expect(find.text('Simular Battle'), findsNothing);
    expect(find.byKey(const Key('battle-test-objective-field')), findsNothing);
    expect(find.byKey(const Key('battle-focus-cards-field')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows a strong keyboard focus halo on the Coach start action', (
    tester,
  ) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });

    await tester.pumpWidget(
      _subject(
        _FakeInteractiveGateway(),
        opponentGateway: _FakeOpponentGateway(),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('battle-coach-choose-opponent-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('battle-opponent-deck-11111111-1111-4111-8111-111111111111'),
      ),
    );
    await tester.pumpAndSettle();

    const submitKey = Key('battle-opponent-submit-button');
    const haloKey = Key('battle-opponent-submit-focus-halo');
    final submit = tester.widget<FilledButton>(find.byKey(submitKey));
    expect(submit.onPressed, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    submit.focusNode!.requestFocus();
    await tester.pump();

    expect(submit.focusNode!.hasFocus, isTrue);
    final decoration =
        tester.widget<Container>(find.byKey(haloKey)).decoration!
            as BoxDecoration;
    expect(
      decoration.boxShadow,
      contains(
        isA<BoxShadow>()
            .having((shadow) => shadow.color, 'color', AppTheme.frost400)
            .having((shadow) => shadow.spreadRadius, 'spreadRadius', 4),
      ),
    );
    final border = decoration.border! as Border;
    expect(border.top.color, AppTheme.frost400);
    expect(border.top.width, 2);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'shows a strong focus halo for keyboard navigation without touch residue',
    (tester) async {
      final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = previousHighlightStrategy;
      });
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme.copyWith(
            splashFactory: InkRipple.splashFactory,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const Key('open-battle-coach'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BattleCoachScreen(
                        deckId: '00000000-0000-4000-8000-000000000001',
                        gateway: _FakeInteractiveGateway(),
                        opponentGateway: _FakeOpponentGateway(),
                        pollInterval: const Duration(hours: 1),
                      ),
                    ),
                  ),
                  child: const Text('Abrir Coach'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-battle-coach')));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      BoxDecoration haloDecoration(Key key) =>
          tester.widget<Container>(find.byKey(key)).decoration!
              as BoxDecoration;

      const backHaloKey = Key('battle-coach-back-focus-halo');
      const backButtonKey = Key('battle-coach-back-button');
      const historyHaloKey = Key('battle-coach-history-focus-halo');
      const historyButtonKey = Key('battle-coach-history-button');
      const chooseHaloKey = Key('battle-coach-choose-opponent-focus-halo');
      const chooseButtonKey = Key('battle-coach-choose-opponent-button');

      expect(haloDecoration(backHaloKey).boxShadow, isEmpty);
      expect(haloDecoration(historyHaloKey).boxShadow, isEmpty);
      expect(haloDecoration(chooseHaloKey).boxShadow, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final backButton = tester.widget<IconButton>(find.byKey(backButtonKey));
      expect(backButton.focusNode?.hasFocus, isTrue);
      expect(
        haloDecoration(backHaloKey).boxShadow,
        contains(
          isA<BoxShadow>()
              .having((shadow) => shadow.color, 'color', AppTheme.frost400)
              .having((shadow) => shadow.spreadRadius, 'spreadRadius', 4),
        ),
      );
      expect(haloDecoration(backHaloKey).border, isA<Border>());
      expect(
        tester
            .getSemantics(find.byKey(backButtonKey))
            .flagsCollection
            .isFocused,
        Tristate.isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final historyButton = tester.widget<IconButton>(
        find.byKey(historyButtonKey),
      );
      expect(historyButton.focusNode?.hasFocus, isTrue);
      expect(
        haloDecoration(historyHaloKey).boxShadow,
        contains(
          isA<BoxShadow>()
              .having((shadow) => shadow.color, 'color', AppTheme.frost400)
              .having((shadow) => shadow.spreadRadius, 'spreadRadius', 4),
        ),
      );
      final historyBorder = haloDecoration(historyHaloKey).border! as Border;
      expect(historyBorder.top.color, AppTheme.frost400);
      expect(historyBorder.top.width, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final chooseButton = tester.widget<FilledButton>(
        find.byKey(chooseButtonKey),
      );
      expect(chooseButton.focusNode?.hasFocus, isTrue);
      expect(
        haloDecoration(chooseHaloKey).boxShadow,
        contains(
          isA<BoxShadow>()
              .having((shadow) => shadow.color, 'color', AppTheme.frost400)
              .having((shadow) => shadow.spreadRadius, 'spreadRadius', 4),
        ),
      );
      final chooseSemantics = tester.getSemantics(find.byKey(chooseButtonKey));
      expect(chooseSemantics.flagsCollection.isButton, isTrue);
      expect(chooseSemantics.flagsCollection.isFocused, Tristate.isTrue);

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      await tester.pump();

      expect(chooseButton.focusNode?.hasFocus, isTrue);
      expect(haloDecoration(chooseHaloKey).boxShadow, isEmpty);
      expect(haloDecoration(chooseHaloKey).border, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    },
  );

  testWidgets(
    'runs an explicitly selected automatic fallback and opens its replay',
    (tester) async {
      const deckId = '00000000-0000-4000-8000-000000000001';
      final interactiveGateway = _FakeInteractiveGateway();
      final opponentGateway = _FallbackOpponentGateway();
      final router = GoRouter(
        initialLocation: '/decks/$deckId/battle-coach',
        routes: [
          GoRoute(
            path: '/decks/:id/battle-coach',
            builder: (context, state) => BattleCoachScreen(
              deckId: state.pathParameters['id']!,
              gateway: interactiveGateway,
              opponentGateway: opponentGateway,
              pollInterval: const Duration(hours: 1),
            ),
          ),
          GoRoute(
            path: '/decks/:id/battle-replays',
            builder: (context, state) => Scaffold(
              body: Text(
                'Replay aberto: ${state.uri.queryParameters['replay']}',
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme.copyWith(
            splashFactory: InkRipple.splashFactory,
          ),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('battle-coach-choose-opponent-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key(
            'battle-opponent-deck-11111111-1111-4111-8111-111111111111',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('battle-opponent-automatic-fallback-button')),
      );
      await tester.pumpAndSettle();

      expect(opponentGateway.automaticRuns, 1);
      expect(find.text('Replay aberto: fallback-replay'), findsOneWidget);
      expect(find.textContaining('XMage'), findsNothing);
    },
  );

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
    expect(find.text('Turno 1 · Início · Manutenção'), findsOneWidget);
    expect(find.text('Mão adversária privada'), findsNothing);
    expect(find.textContaining('Opponent'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    final option = find.byKey(
      const Key('battle-coach-option-o_abcdefghijklmnop'),
    );
    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(gateway.responses, hasLength(1));
    expect(
      find.byKey(const Key('battle-coach-terminal-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-coach-open-replay-button')),
      findsOneWidget,
    );
    expect(find.text('Prioridade'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keyboard focus visibly selects and activates a prompt option', (
    tester,
  ) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });
    final gateway = _FakeInteractiveGateway();
    await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
    await tester.pump();
    await tester.pump();

    const optionKey = Key('battle-coach-option-o_abcdefghijklmnop');
    const haloKey = Key('battle-coach-option-o_abcdefghijklmnop-focus-halo');
    final option = tester.widget<InkWell>(find.byKey(optionKey));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    option.focusNode!.requestFocus();
    await tester.pump();

    expect(option.focusNode!.hasFocus, isTrue);
    final halo = tester.widget<Container>(find.byKey(haloKey));
    final decoration = halo.decoration! as BoxDecoration;
    expect(decoration.border, isA<Border>());
    expect(
      decoration.boxShadow,
      contains(
        isA<BoxShadow>()
            .having((shadow) => shadow.color, 'color', AppTheme.frost400)
            .having((shadow) => shadow.spreadRadius, 'spreadRadius', 4),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(gateway.responses, hasLength(1));
    expect(
      find.byKey(const Key('battle-coach-terminal-panel')),
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

    for (final size in const [
      Size(390, 844),
      Size(844, 390),
      Size(1440, 900),
    ]) {
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
      if (size == const Size(844, 390)) {
        expect(
          find.byKey(const Key('battle-coach-compact-scroll')),
          findsOneWidget,
        );
        final delegate = find.byKey(const Key('battle-coach-delegate-button'));
        expect(delegate, findsOneWidget);
        await tester.ensureVisible(delegate);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final group in const <String, Map<String, Object>>{
    'completed': {
      'tone': 'success',
      'label': 'Partida concluída',
      'message': 'Partida concluída.',
      'color': AppTheme.success,
    },
    'censored': {
      'tone': 'warning',
      'label': 'Partida encerrada pelo limite',
      'message': 'Não há vencedor confirmado.',
      'color': AppTheme.warning,
    },
    'conceded': {
      'tone': 'warning',
      'label': 'Você concedeu',
      'message': 'terminou por concessão',
      'color': AppTheme.warning,
    },
    'expired': {
      'tone': 'warning',
      'label': 'Sessão expirada',
      'message': 'expirou antes da conclusão',
      'color': AppTheme.warning,
    },
    'timeout': {
      'tone': 'warning',
      'label': 'Tempo da decisão esgotado',
      'message': 'prazo da decisão terminou',
      'color': AppTheme.warning,
    },
    'abandoned': {
      'tone': 'warning',
      'label': 'Sessão abandonada',
      'message': 'encerrada por abandono',
      'color': AppTheme.warning,
    },
    'engine_error': {
      'tone': 'error',
      'label': 'Motor indisponível',
      'message': 'Nenhum resultado foi fabricado.',
      'color': AppTheme.error,
    },
    'process_lost': {
      'tone': 'error',
      'label': 'Processo da partida perdido',
      'message': 'não pode ser retomada',
      'color': AppTheme.error,
    },
    'persistence_error': {
      'tone': 'error',
      'label': 'Falha ao salvar a partida',
      'message': 'não pôde ser salvo com segurança',
      'color': AppTheme.error,
    },
  }.entries) {
    testWidgets('renders ${group.key} with its terminal semantics', (
      tester,
    ) async {
      final session = _terminalSession(
        status: group.key,
        replayId: group.key == 'completed' ? 'replay-1' : null,
      );
      await tester.pumpWidget(
        _subject(
          _FakeInteractiveGateway(session: session),
          sessionId: 'session-1',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(group.value['label']! as String), findsWidgets);
      expect(
        find.textContaining(group.value['message']! as String),
        findsOneWidget,
      );
      final icon = tester.widget<Icon>(
        find.byKey(
          Key('battle-coach-terminal-${group.value['tone']! as String}-icon'),
        ),
      );
      expect(icon.color, group.value['color']);
      if (group.key != 'completed') {
        expect(
          find.byKey(const Key('battle-coach-terminal-success-icon')),
          findsNothing,
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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
  BattleReplayGateway? opponentGateway,
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
    opponentGateway: opponentGateway,
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

InteractiveBattleSession _terminalSession({
  String status = 'completed',
  String? replayId = 'replay-1',
}) => InteractiveBattleSession.fromJson({
  'schema_version': 'interactive_battle_session_v1',
  'id': 'session-1',
  'status': status,
  'state_version': 8,
  'deck_id': '00000000-0000-4000-8000-000000000001',
  'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
  'expires_at': '2099-07-27T15:30:00Z',
  'updated_at': '2026-07-27T15:02:00Z',
  if (replayId != null) 'replay_id': replayId,
  if (status.endsWith('error')) 'error_code': status,
  'private_state': {
    'turn': 1,
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
    ],
    'stack': const <dynamic>[],
    'combat': const <dynamic>[],
    'own_hand': const <dynamic>[],
  },
});
