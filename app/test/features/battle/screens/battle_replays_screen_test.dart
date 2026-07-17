import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeBattleReplayGateway implements BattleReplayGateway {
  _FakeBattleReplayGateway({
    this.battleError,
    this.replayListErrorAfterFirstCall,
  });

  final Object? battleError;
  final Object? replayListErrorAfterFirstCall;
  int listCalls = 0;
  int fetchCalls = 0;
  int opponentListCalls = 0;
  int runBattleCalls = 0;
  String? lastOpponentDeckId;

  @override
  Future<List<BattleOpponentDeck>> listOpponentDecks({
    required String currentDeckId,
  }) async {
    opponentListCalls += 1;
    return const [
      BattleOpponentDeck(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Meu Korvold',
        format: 'commander',
        source: BattleOpponentDeckSource.own,
        commanderName: 'Korvold, Fae-Cursed King',
        cardCount: 100,
      ),
      BattleOpponentDeck(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Atraxa da comunidade',
        format: 'commander',
        source: BattleOpponentDeckSource.community,
        commanderName: "Atraxa, Praetors' Voice",
        ownerUsername: 'planeswalker',
        cardCount: 100,
      ),
    ];
  }

  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async {
    listCalls += 1;
    final refreshError = replayListErrorAfterFirstCall;
    if (listCalls > 1 && refreshError != null) throw refreshError;
    return [
      BattleReplaySummary.fromJson(const {
        'id': 'sim-1',
        'deck_id': 'deck-1',
        'type': 'battle',
        'opponent_name': 'Atraxa Superfriends',
        'winner_name': 'Player A',
        'turns_played': 5,
        'event_count': 2,
      }, fallbackDeckId: deckId),
    ];
  }

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) async {
    fetchCalls += 1;
    return BattleReplayDetail.fromJson(
      {
        'replay': {
          'id': replayId,
          'deck_id': deckId,
          'type': 'battle',
          'opponent_name': 'Atraxa Superfriends',
          'winner_name': 'Player A',
          'turns': 5,
          'events': const [
            {
              'turn': 1,
              'player': 'Player A',
              'phase': 'main',
              'action': 'casts',
              'card': 'Arcane Signet',
            },
          ],
          'decision_trace': const [
            {
              'turn': 1,
              'choice': 'Cast Arcane Signet',
              'reason': 'Fixes mana before commander turn.',
            },
          ],
          'visual_snapshots': const [
            {
              'turn': 1,
              'phase': 'main',
              'action': 'casts',
              'active_player': 'Player A',
              'event': {
                'turn': 1,
                'player': 'Player A',
                'phase': 'main',
                'action': 'casts',
                'card': 'Arcane Signet',
              },
              'players': [
                {
                  'name': 'Player A',
                  'life': 40,
                  'mana': 1,
                  'hand': [
                    {
                      'id': 'arcane-signet',
                      'name': 'Arcane Signet',
                      'image_url':
                          'https://cards.scryfall.io/normal/front/a/b/arcane-signet.jpg',
                      'type_line': 'Artifact',
                    },
                  ],
                  'battlefield': [
                    {
                      'id': 'island',
                      'name': 'Island',
                      'image_url': 'https://cards.example/island.jpg',
                      'type_line': 'Basic Land - Island',
                    },
                  ],
                  'graveyard': [],
                  'library_size': 91,
                },
                {
                  'name': 'Player B',
                  'life': 37,
                  'mana': 0,
                  'hand': [],
                  'battlefield': [],
                  'graveyard': [],
                  'library_size': 94,
                },
              ],
            },
          ],
        },
      },
      fallbackDeckId: deckId,
      fallbackId: replayId,
    );
  }

  @override
  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  }) async {
    runBattleCalls += 1;
    lastOpponentDeckId = opponentDeckId;
    final error = battleError;
    if (error != null) throw error;
    return BattleReplayDetail.fromJson(
      {
        'replay_id': 'sim-new',
        'type': 'battle',
        'deck_a_id': deckId,
        'deck_b_id': opponentDeckId,
        'opponent_name': 'Meu Korvold',
        'winner_name': 'Player A',
        'turns': 6,
        'events': const [
          {'turn': 1, 'player': 'Player A', 'action': 'draws'},
        ],
      },
      fallbackDeckId: deckId,
      fallbackId: 'sim-new',
      source: 'battle_simulations',
    );
  }

  @override
  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('renders replay list and opens structured replay detail', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-replays-screen')), findsOneWidget);
    expect(find.text('Battle contra Atraxa Superfriends'), findsOneWidget);
    expect(find.text('Vencedor: Player A'), findsOneWidget);
    expect(find.text('2 eventos'), findsOneWidget);
    expect(gateway.listCalls, 1);

    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(gateway.fetchCalls, 1);
    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
    expect(
      find.byKey(const Key('battle-replay-visual-viewer')),
      findsOneWidget,
    );
    expect(find.text('Player A casts Arcane Signet'), findsOneWidget);
    expect(
      find.byKey(const Key('battle-visual-zone-hand-Player A')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('battle-visual-card-carousel')), findsWidgets);
    expect(
      find.byKey(const Key('battle-visual-card-Arcane Signet')),
      findsOneWidget,
    );

    final arcaneSignetCard = find.byKey(
      const Key('battle-visual-card-Arcane Signet'),
    );
    await tester.ensureVisible(arcaneSignetCard);
    await tester.pumpAndSettle();
    await tester.tap(arcaneSignetCard);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Artifact'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    final decisionsTab = find.text('Decisoes');
    final detailPane = find.byKey(const Key('battle-replay-detail-pane'));
    for (var i = 0; i < 4 && decisionsTab.evaluate().isEmpty; i += 1) {
      await tester.drag(detailPane, const Offset(0, 300));
      await tester.pumpAndSettle();
    }
    expect(decisionsTab, findsOneWidget);
    await tester.tap(decisionsTab);
    await tester.pumpAndSettle();

    expect(find.text('Cast Arcane Signet'), findsOneWidget);
    expect(find.text('Fixes mana before commander turn.'), findsOneWidget);
  });

  testWidgets('keeps a single-pane replay flow at 390px without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _FakeBattleReplayGateway();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    final workspace = find.byKey(const Key('battle-replays-workspace'));
    expect(tester.getSize(workspace).width, lessThanOrEqualTo(390));
    expect(find.byKey(const Key('battle-replays-master-detail')), findsNothing);
    expect(
      find.byKey(const Key('battle-replays-history-list')),
      findsOneWidget,
    );

    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('battle-replays-history-pane')), findsNothing);
    expect(find.byKey(const Key('battle-visual-player-grid')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'uses a bounded 1280px master-detail workspace and fixed card spacing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final gateway = _FakeBattleReplayGateway();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
        ),
      );
      await tester.pumpAndSettle();

      final workspace = find.byKey(const Key('battle-replays-workspace'));
      final historyPane = find.byKey(const Key('battle-replays-history-pane'));
      expect(tester.getSize(workspace).width, lessThanOrEqualTo(1280));
      expect(
        find.byKey(const Key('battle-replays-master-detail')),
        findsOneWidget,
      );
      expect(tester.getSize(historyPane).width, closeTo(344, 0.1));
      expect(
        find.byKey(const Key('battle-replays-selection-empty')),
        findsOneWidget,
      );

      await tester.tap(find.text('Battle contra Atraxa Superfriends'));
      await tester.pumpAndSettle();

      final detailPane = find.byKey(const Key('battle-replay-detail-pane'));
      expect(historyPane, findsOneWidget);
      expect(
        find.byKey(const Key('battle-replays-history-list')),
        findsOneWidget,
      );
      expect(detailPane, findsOneWidget);
      expect(
        tester.getTopLeft(detailPane).dx,
        greaterThan(tester.getTopRight(historyPane).dx),
      );

      final playerA = find.byKey(const Key('battle-visual-player-Player A'));
      final playerB = find.byKey(const Key('battle-visual-player-Player B'));
      expect(
        find.byKey(const Key('battle-visual-player-grid')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(playerA).dy,
        closeTo(tester.getTopLeft(playerB).dy, 0.1),
      );

      final carousel =
          find.byKey(const Key('battle-visual-card-carousel')).first;
      final pageView = tester.widget<PageView>(carousel);
      final renderedItemExtent =
          tester.getSize(carousel).width *
          pageView.controller!.viewportFraction;
      expect(renderedItemExtent, lessThanOrEqualTo(92.1));

      final cardImage = tester.widget<CachedCardImage>(
        find.byKey(const Key('battle-visual-card-image-Arcane Signet')),
      );
      expect(cardImage.imageUrl, contains('/small/'));

      await tester.binding.setSurfaceSize(const Size(1600, 900));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(workspace).width,
        closeTo(AppTheme.contentMaxWidth, 0.1),
      );
      expect(tester.getTopLeft(workspace).dx, closeTo(160, 0.1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'runs Battle from opponent selection through saved replay success',
    (tester) async {
      final gateway = _FakeBattleReplayGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('battle-run-battle-button')));
      await tester.pumpAndSettle();

      expect(gateway.opponentListCalls, 1);
      expect(
        find.byKey(const Key('battle-opponent-picker-dialog')),
        findsOneWidget,
      );
      expect(find.text('Meu Korvold'), findsOneWidget);
      expect(find.text('Atraxa da comunidade'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const Key(
            'battle-opponent-deck-11111111-1111-4111-8111-111111111111',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
      await tester.pumpAndSettle();

      expect(gateway.runBattleCalls, 1);
      expect(
        gateway.lastOpponentDeckId,
        '11111111-1111-4111-8111-111111111111',
      );
      expect(
        find.byKey(const Key('battle-replay-detail-pane')),
        findsOneWidget,
      );
      expect(find.text('Battle contra Meu Korvold'), findsOneWidget);
      expect(find.textContaining('Historico salvo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps saved replay visible when the immediate history refresh fails',
    (tester) async {
      final gateway = _FakeBattleReplayGateway(
        replayListErrorAfterFirstCall: const BattleReplayException(
          'Falha ao atualizar o historico.',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('battle-run-battle-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key(
            'battle-opponent-deck-11111111-1111-4111-8111-111111111111',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
      await tester.pumpAndSettle();

      expect(gateway.runBattleCalls, 1);
      expect(gateway.listCalls, 2);
      expect(
        find.byKey(const Key('battle-replay-detail-pane')),
        findsOneWidget,
      );
      expect(find.text('Battle contra Meu Korvold'), findsOneWidget);
      expect(find.byKey(const Key('battle-replays-error-state')), findsNothing);
      expect(
        find.text(
          'Replay salvo, mas o historico nao foi atualizado. '
          'Tente atualizar novamente.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('surfaces Battle execution error after opponent selection', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      battleError: const BattleReplayException(
        'O motor de Battle esta temporariamente indisponivel.',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('battle-run-battle-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('battle-opponent-deck-22222222-2222-4222-8222-222222222222'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
    await tester.pumpAndSettle();

    expect(gateway.runBattleCalls, 1);
    expect(
      find.text('O motor de Battle esta temporariamente indisponivel.'),
      findsWidgets,
    );
    expect(find.byKey(const Key('battle-replays-error-state')), findsOneWidget);
  });

  testWidgets('keeps validated UUID entry behind technical mode', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('battle-run-battle-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('battle-opponent-technical-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('battle-opponent-deck-id-field')),
      'id-invalido',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
    await tester.pump();
    expect(find.text('Informe um UUID de deck valido.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('battle-opponent-deck-id-field')),
      '33333333-3333-4333-8333-333333333333',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
    await tester.pumpAndSettle();

    expect(gateway.lastOpponentDeckId, '33333333-3333-4333-8333-333333333333');
  });

  testWidgets('keeps opponent selection usable at 390px without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _FakeBattleReplayGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('battle-run-battle-button')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('battle-opponent-picker-dialog'));
    expect(dialog, findsOneWidget);
    expect(find.byKey(const Key('battle-opponent-deck-list')), findsOneWidget);
    expect(tester.getSize(dialog).width, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });
}
