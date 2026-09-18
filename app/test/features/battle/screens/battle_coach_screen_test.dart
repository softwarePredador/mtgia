import 'dart:ui' show PointerDeviceKind, Tristate;

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
  _FakeInteractiveGateway({
    InteractiveBattleSession? session,
    this.activeSessions = const [],
  }) : session = session ?? _waitingSession();

  final InteractiveBattleSession session;
  final List<InteractiveBattleSession> activeSessions;
  int getCount = 0;
  int listCount = 0;
  int createCount = 0;
  int concedeCalls = 0;
  final List<InteractiveBattleResponse> responses = [];

  @override
  Future<List<InteractiveBattleSession>> list({
    required String deckId,
    int limit = 20,
  }) async {
    listCount += 1;
    return activeSessions;
  }

  @override
  Future<InteractiveBattleSession> create({
    required String deckId,
    required String opponentDeckId,
    int ttlSeconds = 1800,
    int promptTimeoutSeconds = 90,
  }) async {
    createCount += 1;
    return _waitingSession();
  }

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
  Future<InteractiveBattleSession> concede(String sessionId) async {
    concedeCalls += 1;
    return _terminalSession(status: 'conceded');
  }
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

class _BlockedInteractiveOpponentGateway extends _FakeOpponentGateway {
  int interactivePreflightCalls = 0;
  int automaticPreflightCalls = 0;
  int automaticRuns = 0;

  @override
  Future<BattlePreflight> loadBattlePreflight({
    required String deckId,
    required String opponentDeckId,
    bool interactive = false,
  }) async {
    if (interactive) {
      interactivePreflightCalls += 1;
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
    automaticPreflightCalls += 1;
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
    throw StateError('Play vs AI must never start an automatic simulation.');
  }
}

void main() {
  test('uses the deck-scoped Play vs AI route as the public identity', () {
    expect(
      playVsAiRouteLocation('deck / one'),
      '/decks/deck%20%2F%20one/play-vs-ai',
    );
    expect(
      playVsAiSessionRouteLocation('deck-1', 'session / one'),
      '/decks/deck-1/play-vs-ai/session%20%2F%20one',
    );
  });

  testWidgets('shows a clear opt-in welcome before creating a session', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(_subject(_FakeInteractiveGateway()));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('battle-coach-welcome-state')), findsOneWidget);
    expect(find.text('Jogue seu deck contra a IA'), findsOneWidget);
    expect(find.text('MÃO · CAMPO · PILHA · AÇÕES LEGAIS'), findsOneWidget);
    expect(find.text('Você controla suas jogadas'), findsOneWidget);
    expect(find.text('Regras aplicadas e replay ao concluir'), findsOneWidget);
    expect(
      find.textContaining('mana, alvos, prioridade e combate'),
      findsOneWidget,
    );
    expect(find.textContaining('Coach'), findsNothing);
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
    expect(find.text('TESTE'), findsOneWidget);
    expect(
      find.text(
        'Experimental · você joga contra um adversário controlado pela IA',
      ),
      findsOneWidget,
    );
    final layoutException = tester.takeException();
    expect(layoutException, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('offers the active table before allowing a new one', (
    tester,
  ) async {
    const deckId = '00000000-0000-4000-8000-000000000001';
    final active = _waitingSession();
    final gateway = _FakeInteractiveGateway(activeSessions: [active]);
    final router = GoRouter(
      initialLocation: '/decks/$deckId/play-vs-ai',
      routes: [
        GoRoute(
          path: '/decks/:id/play-vs-ai',
          builder: (context, state) => BattleCoachScreen(
            deckId: state.pathParameters['id']!,
            gateway: gateway,
            opponentGateway: _FakeOpponentGateway(),
            pollInterval: const Duration(hours: 1),
          ),
          routes: [
            GoRoute(
              path: ':sessionId',
              builder: (context, state) => BattleCoachScreen(
                deckId: state.pathParameters['id']!,
                sessionId: state.pathParameters['sessionId'],
                gateway: gateway,
                opponentGateway: _FakeOpponentGateway(),
                pollInterval: const Duration(hours: 1),
              ),
            ),
          ],
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
    await tester.pump();
    await tester.pump();

    expect(gateway.listCount, 1);
    expect(
      find.byKey(const Key('battle-coach-active-session-card')),
      findsOneWidget,
    );
    expect(find.text('Retomar mesa ativa'), findsOneWidget);
    expect(
      find.byKey(const Key('battle-coach-choose-opponent-button')),
      findsNothing,
    );

    final resume = find.byKey(
      const Key('battle-coach-resume-active-session-button'),
    );
    await tester.ensureVisible(resume);
    await tester.pump();
    await tester.tap(resume);
    await tester.pumpAndSettle();

    expect(gateway.getCount, greaterThanOrEqualTo(1));
    expect(find.byKey(const Key('battle-coach-board')), findsOneWidget);
    expect(find.textContaining('XMage'), findsNothing);
  });

  testWidgets('uses player-vs-AI copy and CTA in the opponent picker', (
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
    expect(find.text('Jogar contra IA'), findsWidgets);
    expect(
      find.textContaining('mesa privada para você controlar seu lado'),
      findsOneWidget,
    );
    expect(find.text('Simular Battle'), findsNothing);
    expect(find.textContaining('Coach'), findsNothing);
    expect(find.byKey(const Key('battle-test-objective-field')), findsNothing);
    expect(find.byKey(const Key('battle-focus-cards-field')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows a strong keyboard focus halo on the Play vs AI action', (
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
                  key: const Key('open-play-vs-ai'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BattleCoachScreen(
                        deckId: '00000000-0000-4000-8000-000000000001',
                        gateway: _FakeInteractiveGateway(),
                        opponentGateway: _FakeOpponentGateway(),
                        replayHistoryEnabled: true,
                        pollInterval: const Duration(hours: 1),
                      ),
                    ),
                  ),
                  child: const Text('Jogar contra IA'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-play-vs-ai')));
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

  testWidgets('blocks Play vs AI instead of replacing it with a simulation', (
    tester,
  ) async {
    final interactiveGateway = _FakeInteractiveGateway();
    final opponentGateway = _BlockedInteractiveOpponentGateway();
    await tester.pumpWidget(
      _subject(interactiveGateway, opponentGateway: opponentGateway),
    );
    await tester.pumpAndSettle();

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

    expect(opponentGateway.interactivePreflightCalls, 1);
    expect(opponentGateway.automaticPreflightCalls, 0);
    expect(
      find.byKey(const Key('battle-opponent-automatic-fallback-button')),
      findsNothing,
    );
    expect(
      find.textContaining(
        'Cobertura de regras em preparação para Lorehold, the Historian',
      ),
      findsOneWidget,
    );
    final playVsAiButton = tester.widget<FilledButton>(
      find.byKey(const Key('battle-opponent-submit-button')),
    );
    expect(playVsAiButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
    await tester.pump();

    expect(interactiveGateway.createCount, 0);
    expect(opponentGateway.automaticRuns, 0);
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

  testWidgets(
    'keeps Play vs AI usable without exposing replay history when batch is off',
    (tester) async {
      final gateway = _FakeInteractiveGateway(session: _terminalSession());
      await tester.pumpWidget(
        _subject(gateway, sessionId: 'session-1', replayHistoryEnabled: false),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('battle-coach-terminal-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('play-vs-ai-rematch-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-coach-history-button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('battle-coach-open-replay-button')),
        findsNothing,
      );
    },
  );

  testWidgets('submits the exact typed option by tapping a legal hand card', (
    tester,
  ) async {
    final gateway = _FakeInteractiveGateway(
      session: _waitingSession(cardAction: _CardAction.hand),
    );
    await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
    await tester.pump();
    await tester.pump();

    const optionId = 'o_cast_swords_abcdefghijkl';
    final legalCard = find.byKey(const Key('play-vs-ai-legal-card-$optionId'));
    expect(legalCard, findsOneWidget);
    expect(
      find.byKey(const Key('play-vs-ai-legal-card-badge-$optionId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-coach-option-$optionId')),
      findsOneWidget,
      reason: 'the typed action tray remains the accessible fallback',
    );
    expect(
      find.byKey(const Key('play-vs-ai-card-action-hint')),
      findsOneWidget,
    );

    await tester.tap(legalCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(gateway.responses, hasLength(1));
    expect(gateway.responses.single.optionId, optionId);
    expect(
      find.byKey(const Key('battle-coach-terminal-panel')),
      findsOneWidget,
    );
  });

  testWidgets(
    'submits the exact typed option by tapping a legal board target',
    (tester) async {
      final gateway = _FakeInteractiveGateway(
        session: _waitingSession(cardAction: _CardAction.boardTarget),
      );
      await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
      await tester.pump();
      await tester.pump();

      const optionId = 'o_target_atraxa_abcdefghijkl';
      final legalTarget = find.byKey(
        const Key('play-vs-ai-legal-card-$optionId'),
      );
      expect(legalTarget, findsOneWidget);

      await tester.tap(legalTarget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(gateway.responses, hasLength(1));
      expect(gateway.responses.single.optionId, optionId);
    },
  );

  testWidgets(
    'fails closed when a visible card matches multiple prompt cards',
    (tester) async {
      final gateway = _FakeInteractiveGateway(
        session: _waitingSession(cardAction: _CardAction.ambiguousOptions),
      );
      await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('play-vs-ai-legal-card-o_choice_a_abcdefghijkl')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('play-vs-ai-legal-card-o_choice_b_abcdefghijkl')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('battle-coach-option-o_choice_a_abcdefghijkl')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-coach-option-o_choice_b_abcdefghijkl')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('play-vs-ai-card-action-hint')),
        findsNothing,
      );

      final card = find.byKey(
        const Key('battle-coach-card-preview-$_handObjectId'),
      );
      expect(card, findsWidgets);
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      expect(gateway.responses, isEmpty);
      expect(
        find.byKey(const Key('battle-coach-card-preview-dialog')),
        findsOneWidget,
        reason: 'ambiguous direct actions degrade to preview plus typed tray',
      );
    },
  );

  testWidgets(
    'fails closed when a prompt card descriptor has no opaque object id',
    (tester) async {
      final gateway = _FakeInteractiveGateway(
        session: _waitingSession(cardAction: _CardAction.ambiguousVisibleCards),
      );
      await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
      await tester.pump();
      await tester.pump();

      const optionId = 'o_duplicate_abcdefghijkl';
      expect(
        find.byKey(const Key('play-vs-ai-legal-card-$optionId')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('battle-coach-option-$optionId')),
        findsOneWidget,
        reason: 'the typed option remains available when card-first is unsafe',
      );
      expect(
        find.byKey(const Key('play-vs-ai-card-action-hint')),
        findsNothing,
      );

      for (final cardId in const [_handObjectId, _secondHandObjectId]) {
        final card = find.byKey(Key('battle-coach-card-preview-$cardId'));
        expect(card, findsOneWidget);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(gateway.responses, isEmpty);
        expect(
          find.byKey(const Key('battle-coach-card-preview-dialog')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('battle-coach-card-preview-close-button')),
        );
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'does not highlight homonymous hand or battlefield copies for a graveyard id',
    (tester) async {
      final gateway = _FakeInteractiveGateway(
        session: _waitingSession(cardAction: _CardAction.graveyardCopy),
      );
      await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
      await tester.pump();
      await tester.pump();

      const optionId = 'o_graveyard_abcdefghijkl';
      expect(
        find.byKey(const Key('battle-coach-option-$optionId')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('play-vs-ai-legal-card-$optionId')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('play-vs-ai-card-action-hint')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('battle-coach-card-preview-$_handObjectId')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('battle-coach-card-preview-$_battlefieldCopyObjectId'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('battle-coach-card-preview-$_handObjectId')),
      );
      await tester.pumpAndSettle();
      expect(gateway.responses, isEmpty);
      expect(
        find.byKey(const Key('battle-coach-card-preview-dialog')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'concede confirmation cancels safely and confirms a causal terminal state',
    (tester) async {
      final gateway = _FakeInteractiveGateway();
      await tester.pumpWidget(_subject(gateway, sessionId: 'session-1'));
      await tester.pump();
      await tester.pump();

      final concede = find.byKey(const Key('battle-coach-concede-button'));
      await tester.ensureVisible(concede);
      await tester.tap(concede);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('battle-coach-concede-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('battle-coach-cancel-concede-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('battle-coach-cancel-concede-button')),
      );
      await tester.pumpAndSettle();
      expect(gateway.concedeCalls, 0);
      expect(find.byKey(const Key('battle-coach-board')), findsOneWidget);

      await tester.tap(concede);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('battle-coach-confirm-concede-button')),
      );
      await tester.pumpAndSettle();
      expect(gateway.concedeCalls, 1);
      expect(
        find.byKey(const Key('battle-coach-terminal-panel')),
        findsOneWidget,
      );
      expect(find.text('Você concedeu'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('renders unavailable battle metrics without fabricated zeroes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _subject(
        _FakeInteractiveGateway(session: _unknownMetricsSession()),
        sessionId: 'session-unknown-state',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.bySemanticsLabel('Vida não disponível'), findsWidgets);
    expect(
      find.bySemanticsLabel('Quantidade de cartas na mão não disponível'),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel('Quantidade de cartas no grimório não disponível'),
      findsWidgets,
    );

    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('previews a card by hover, focus, tap, and long press', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _subject(
        _FakeInteractiveGateway(session: _waitingSession(withCard: true)),
        sessionId: 'session-1',
      ),
    );
    await tester.pump();
    await tester.pump();

    const previewKey = Key('battle-coach-card-preview-$_handObjectId');
    const focusKey = Key('battle-coach-card-preview-$_handObjectId-focus');
    final preview = find.byKey(previewKey);
    await tester.ensureVisible(preview);
    await tester.pump();
    expect(
      tester.getSemantics(preview).label,
      contains('Ver prévia de Swords to Plowshares'),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    final hoverTarget = find
        .descendant(of: preview, matching: find.byType(MouseRegion))
        .first;
    await mouse.moveTo(tester.getCenter(hoverTarget));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('battle-coach-card-hover-preview')),
      findsOneWidget,
    );
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(
      find.byKey(const Key('battle-coach-card-hover-preview')),
      findsNothing,
    );

    final focus = tester.widget<Focus>(find.byKey(focusKey));
    focus.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(focus.focusNode!.hasFocus, isTrue);
    expect(
      find.byKey(const Key('battle-coach-card-hover-preview')),
      findsOneWidget,
    );
    focus.focusNode!.unfocus();
    await tester.pump();

    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('battle-coach-card-preview-dialog')),
      findsOneWidget,
    );
    expect(
      find.text('Prévia da carta na mesa. Feche para continuar sua decisão.'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('battle-coach-card-preview-close-button')),
    );
    await tester.pumpAndSettle();

    await tester.longPress(preview);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('battle-coach-card-preview-dialog')),
      findsOneWidget,
    );

    await mouse.removePointer();
    semantics.dispose();
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

  testWidgets('keeps hand, board, and actions reachable across target widths', (
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
        _subject(
          _FakeInteractiveGateway(
            session: _waitingSession(cardAction: _CardAction.hand),
          ),
          sessionId: 'session-1',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Play vs AI must fit ${size.width}x${size.height}.',
      );
      expect(find.byKey(const Key('battle-coach-board')), findsOneWidget);
      expect(find.byKey(const Key('play-vs-ai-hand-dock')), findsOneWidget);
      expect(find.byKey(const Key('play-vs-ai-action-tray')), findsOneWidget);
      expect(
        find.byKey(
          const Key('play-vs-ai-legal-card-o_cast_swords_abcdefghijkl'),
        ),
        findsOneWidget,
      );
      final handDock = tester.getRect(
        find.byKey(const Key('play-vs-ai-hand-dock')),
      );
      expect(handDock.top, greaterThanOrEqualTo(0));
      expect(handDock.bottom, lessThanOrEqualTo(size.height));

      if (size.width < 760) {
        expect(
          find.byKey(const Key('play-vs-ai-stacked-workspace')),
          findsOneWidget,
        );
      } else {
        expect(
          find.byKey(const Key('play-vs-ai-side-by-side-workspace')),
          findsOneWidget,
        );
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

  testWidgets('Jogar novamente returns to the canonical Play vs AI entry', (
    tester,
  ) async {
    const deckId = '00000000-0000-4000-8000-000000000001';
    final gateway = _FakeInteractiveGateway(session: _terminalSession());
    final router = GoRouter(
      initialLocation: '/decks/$deckId/play-vs-ai/session-1',
      routes: [
        GoRoute(
          path: '/decks/:id/play-vs-ai',
          builder: (context, state) => BattleCoachScreen(
            deckId: state.pathParameters['id']!,
            gateway: gateway,
            opponentGateway: _FakeOpponentGateway(),
            pollInterval: const Duration(hours: 1),
          ),
          routes: [
            GoRoute(
              path: ':sessionId',
              builder: (context, state) => BattleCoachScreen(
                deckId: state.pathParameters['id']!,
                sessionId: state.pathParameters['sessionId']!,
                gateway: gateway,
                opponentGateway: _FakeOpponentGateway(),
                pollInterval: const Duration(hours: 1),
              ),
            ),
          ],
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

    expect(
      find.byKey(const Key('battle-coach-terminal-panel')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('play-vs-ai-rematch-button')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/decks/$deckId/play-vs-ai',
    );
    expect(find.byKey(const Key('battle-coach-welcome-state')), findsOneWidget);
    expect(find.text('Jogue seu deck contra a IA'), findsOneWidget);
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
  bool replayHistoryEnabled = true,
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
    replayHistoryEnabled: replayHistoryEnabled,
    pollInterval: const Duration(hours: 1),
  ),
);

enum _CardAction {
  none,
  hand,
  boardTarget,
  ambiguousOptions,
  ambiguousVisibleCards,
  graveyardCopy,
}

const _handObjectId = '11111111-1111-4111-8111-111111111111';
const _secondHandObjectId = '22222222-2222-4222-8222-222222222222';
const _boardTargetObjectId = '33333333-3333-4333-8333-333333333333';
const _graveyardObjectId = '44444444-4444-4444-8444-444444444444';
const _battlefieldCopyObjectId = '55555555-5555-4555-8555-555555555555';

InteractiveBattleSession _waitingSession({
  bool withCard = false,
  _CardAction cardAction = _CardAction.none,
}) {
  final showHandCard =
      withCard ||
      cardAction == _CardAction.hand ||
      cardAction == _CardAction.ambiguousOptions ||
      cardAction == _CardAction.ambiguousVisibleCards ||
      cardAction == _CardAction.graveyardCopy;
  const handCardId = _handObjectId;
  final promptOptions = switch (cardAction) {
    _CardAction.hand => [
      {
        'id': 'o_cast_swords_abcdefghijkl',
        'label': 'Conjurar Swords to Plowshares',
        'role': 'card',
        'card': {
          'id': _handObjectId,
          'name': 'Swords to Plowshares',
          'set_code': '2xm',
          'collector_number': '35',
        },
      },
    ],
    _CardAction.boardTarget => [
      {
        'id': 'o_target_atraxa_abcdefghijkl',
        'label': 'Escolher Atraxa como alvo',
        'role': 'target',
        'card': {
          'id': _boardTargetObjectId,
          'name': "Atraxa, Praetors' Voice",
          'set_code': '2x2',
          'collector_number': '188',
        },
      },
    ],
    _CardAction.ambiguousOptions => [
      {
        'id': 'o_choice_a_abcdefghijkl',
        'label': 'Escolha A',
        'role': 'card',
        'card': {
          'id': _handObjectId,
          'name': 'Swords to Plowshares',
          'set_code': '2xm',
          'collector_number': '35',
        },
      },
      {
        'id': 'o_choice_b_abcdefghijkl',
        'label': 'Escolha B',
        'role': 'card',
        'card': {
          'id': _handObjectId,
          'name': 'Swords to Plowshares',
          'set_code': '2xm',
          'collector_number': '35',
        },
      },
    ],
    _CardAction.ambiguousVisibleCards => [
      {
        'id': 'o_duplicate_abcdefghijkl',
        'label': 'Conjurar Swords to Plowshares',
        'role': 'card',
        'card': {
          'name': 'Swords to Plowshares',
          'set_code': '2xm',
          'collector_number': '35',
        },
      },
    ],
    _CardAction.graveyardCopy => [
      {
        'id': 'o_graveyard_abcdefghijkl',
        'label': 'Escolher Swords to Plowshares no cemitério',
        'role': 'target',
        'card': {
          'id': _graveyardObjectId,
          'name': 'Swords to Plowshares',
          'set_code': '2xm',
          'collector_number': '35',
        },
      },
    ],
    _CardAction.none => [
      {'id': 'o_abcdefghijklmnop', 'label': 'Manter esta mão', 'role': 'keep'},
    ],
  };

  return InteractiveBattleSession.fromJson({
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
          'battlefield': cardAction == _CardAction.graveyardCopy
              ? [
                  {
                    'id': _battlefieldCopyObjectId,
                    'name': 'Swords to Plowshares',
                    'set_code': '2xm',
                    'card_number': '35',
                  },
                ]
              : const <dynamic>[],
          'graveyard': cardAction == _CardAction.graveyardCopy
              ? [
                  {
                    'id': _graveyardObjectId,
                    'name': 'Swords to Plowshares',
                    'set_code': '2xm',
                    'card_number': '35',
                  },
                ]
              : const <dynamic>[],
          'exile': const <dynamic>[],
          'command': const <dynamic>[],
        },
        {
          'name': 'Opponent',
          'life': 40,
          'library_count': 91,
          'hand_count': 8,
          'battlefield': cardAction == _CardAction.boardTarget
              ? [
                  {
                    'id': _boardTargetObjectId,
                    'name': "Atraxa, Praetors' Voice",
                    'set_code': '2x2',
                    'card_number': '188',
                  },
                ]
              : const <dynamic>[],
          'graveyard': const <dynamic>[],
          'exile': const <dynamic>[],
          'command': const <dynamic>[],
        },
      ],
      'stack': const <dynamic>[],
      'combat': const <dynamic>[],
      'own_hand': showHandCard
          ? cardAction == _CardAction.ambiguousVisibleCards
                ? [
                    {
                      'id': _handObjectId,
                      'name': 'Swords to Plowshares',
                      'set_code': '2xm',
                      'card_number': '35',
                    },
                    {
                      'id': _secondHandObjectId,
                      'name': 'Swords to Plowshares',
                      'set_code': '2xm',
                      'card_number': '35',
                    },
                  ]
                : [
                    {
                      'id': handCardId,
                      'name': 'Swords to Plowshares',
                      'set_code': '2xm',
                      'card_number': '35',
                    },
                  ]
          : const <dynamic>[],
    },
    'prompt': {
      'schema_version': 'interactive_battle_prompt_v1',
      'id': 'p_abcdefghijklmnop',
      'state_version': 7,
      'kind': cardAction == _CardAction.none ? 'mulligan' : 'main_action',
      'input_mode': 'options',
      'title': 'Sua prioridade',
      'message': 'Manter esta mão?',
      'deadline_at': '2099-07-27T15:01:00Z',
      'options': promptOptions,
    },
  });
}

InteractiveBattleSession _unknownMetricsSession() =>
    InteractiveBattleSession.fromJson({
      'schema_version': 'interactive_battle_session_v1',
      'id': 'session-unknown-state',
      'status': 'running',
      'state_version': 1,
      'deck_id': '00000000-0000-4000-8000-000000000001',
      'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
      'expires_at': '2099-07-27T15:30:00Z',
      'updated_at': '2026-07-27T15:00:00Z',
      'private_state': {
        'own_player': 'ManaLoom',
        'players': [
          {
            'name': 'ManaLoom',
            'battlefield': const <dynamic>[],
            'graveyard': const <dynamic>[],
            'exile': const <dynamic>[],
            'command': const <dynamic>[],
          },
          {
            'name': 'Opponent',
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
