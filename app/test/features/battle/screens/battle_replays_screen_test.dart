import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeBattleReplayGateway implements BattleReplayGateway {
  int listCalls = 0;
  int fetchCalls = 0;

  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async {
    listCalls += 1;
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
  }) {
    throw UnimplementedError();
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
}
