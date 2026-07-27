import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/widgets/manaloom_glyph.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/models/battle_replay_annotation.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeBattleReplayGateway implements BattleReplayGateway {
  _FakeBattleReplayGateway({
    this.battleError,
    this.replayListErrorOnFirstCall,
    this.replayListErrorAfterFirstCall,
    this.replays,
    this.moreReplays,
    this.replayDetail,
    List<BattleReplayAnnotation> annotations = const [],
    this.preflight = const BattlePreflight(
      status: 'ready',
      cardCount: 100,
      commanderCount: 1,
      validationState: 'validated',
      availableOpponentCount: 2,
      engineCoverage: {'xmage': 'ready'},
      blockers: [],
    ),
  }) : _annotations = List<BattleReplayAnnotation>.of(annotations);

  final Object? battleError;
  final Object? replayListErrorOnFirstCall;
  final Object? replayListErrorAfterFirstCall;
  final List<BattleReplaySummary>? replays;
  final List<BattleReplaySummary>? moreReplays;
  final BattleReplayDetail? replayDetail;
  final BattlePreflight preflight;
  final List<BattleReplayAnnotation> _annotations;
  int listCalls = 0;
  int fetchCalls = 0;
  int opponentListCalls = 0;
  int preflightCalls = 0;
  int runBattleCalls = 0;
  String? lastOpponentDeckId;
  BattleTestSetup? lastSetup;
  BattleReplayAnnotationDraft? lastAnnotationDraft;

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
    final initialError = replayListErrorOnFirstCall;
    if (listCalls == 1 && initialError != null) throw initialError;
    final refreshError = replayListErrorAfterFirstCall;
    if (listCalls > 1 && refreshError != null) throw refreshError;
    return replays ??
        [
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
  Future<BattleReplayPageResult> listReplayPage(
    String deckId, {
    String? cursor,
    int limit = 30,
  }) async {
    if (cursor == null) {
      final items = await listReplays(deckId);
      return BattleReplayPageResult(
        items: items,
        hasMore: moreReplays != null,
        nextCursor: moreReplays == null ? null : 'cursor_one',
      );
    }
    listCalls += 1;
    final refreshError = replayListErrorAfterFirstCall;
    if (refreshError != null) throw refreshError;
    if (cursor != 'cursor_one' || moreReplays == null) {
      throw const BattleReplayException('Cursor de teste inválido.');
    }
    return BattleReplayPageResult(
      items: moreReplays!,
      hasMore: false,
      nextCursor: null,
    );
  }

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) async {
    fetchCalls += 1;
    final providedDetail = replayDetail;
    if (providedDetail != null) return providedDetail;
    return BattleReplayDetail.fromJson(
      {
        'replay': {
          'id': replayId,
          'deck_id': deckId,
          'type': 'battle',
          'engine': 'manaloom_native_reviewed',
          'learning_contract': const {
            'schema_version': 'native_battle_learning_v1',
            'decision_trace_available': true,
          },
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
            {
              'turn': 2,
              'phase': 'combat',
              'step': 'declare_attackers',
              'action': 'attacks',
              'active_player': 'Player A',
              'priority_player': 'Player B',
              'event': {
                'turn': 2,
                'player': 'Player A',
                'phase': 'combat',
                'action': 'attacks',
                'card': 'Serra Angel',
              },
              'stack': [
                {'name': 'Combat Trick'},
              ],
              'combat': [
                {
                  'defender_name': 'Player B',
                  'attackers': [
                    {'name': 'Serra Angel'},
                  ],
                  'blockers': <Map<String, dynamic>>[],
                },
              ],
              'players': [
                {
                  'name': 'Player A',
                  'life': 40,
                  'mana': 0,
                  'hand_size': 5,
                  'battlefield': [
                    {'name': 'Serra Angel'},
                  ],
                  'graveyard': <Map<String, dynamic>>[],
                  'command': [
                    {'name': 'Giada, Font of Hope'},
                  ],
                  'exile': [
                    {'name': 'Swords to Plowshares'},
                  ],
                  'library_size': 90,
                },
                {
                  'name': 'Player B',
                  'life': 37,
                  'mana': 2,
                  'hand_size': 6,
                  'battlefield': <Map<String, dynamic>>[],
                  'graveyard': <Map<String, dynamic>>[],
                  'library_size': 93,
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
  Future<List<BattleReplayAnnotation>> listReplayAnnotations({
    required String deckId,
    required String replayId,
  }) async => List<BattleReplayAnnotation>.unmodifiable(_annotations);

  @override
  Future<BattleReplayAnnotation> createReplayAnnotation({
    required String deckId,
    required String replayId,
    required BattleReplayAnnotationDraft draft,
  }) async {
    lastAnnotationDraft = draft;
    final annotation = BattleReplayAnnotation.fromJson({
      'schema_version': 'battle_replay_annotation_v1',
      'id': 'annotation-${_annotations.length + 1}',
      'replay_id': replayId,
      'subject_deck_id': deckId,
      'subject_deck_revision': 'deck_snapshot_sha256_v1:test-hash',
      if (draft.eventRef != null) 'event_ref': draft.eventRef,
      if (draft.snapshotRef != null) 'snapshot_ref': draft.snapshotRef,
      'kind': draft.kind.wireValue,
      'payload': draft.payload,
      'created_at': '2026-07-26T12:00:00Z',
    });
    _annotations.insert(0, annotation);
    return annotation;
  }

  @override
  Future<bool> deleteReplayAnnotation({
    required String deckId,
    required String replayId,
    required String annotationId,
  }) async {
    final previousLength = _annotations.length;
    _annotations.removeWhere((annotation) => annotation.id == annotationId);
    return _annotations.length != previousLength;
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
  Future<BattlePreflight> loadBattlePreflight({
    required String deckId,
    required String opponentDeckId,
  }) async {
    preflightCalls += 1;
    return preflight;
  }

  @override
  Future<BattleReplayDetail> runBattleTest({
    required String deckId,
    required BattleTestSetup setup,
    int maxTurns = 30,
  }) {
    lastSetup = setup;
    return runBattleSimulation(
      deckId: deckId,
      opponentDeckId: setup.opponentDeckId,
      maxTurns: maxTurns,
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

class _EmptyBattleJobGateway extends BattleJobGateway {
  @override
  Future<List<BattleJob>> list({
    int limit = 20,
    BattleJobStatus? status,
    String? deckId,
  }) async => const <BattleJob>[];
}

void main() {
  test('battle replay location is canonical and URL-safe', () {
    expect(
      battleReplaysRouteLocation('deck id/with slash'),
      '/decks/deck%20id%2Fwith%20slash/battle-replays',
    );
  });

  testWidgets('opens a replay selected by the canonical query parameter', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(
          deckId: 'deck-1',
          gateway: gateway,
          initialReplayId: 'sim-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(gateway.fetchCalls, 1);
    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
  });

  testWidgets('deep-linked replay remains available when history fails', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      replayListErrorOnFirstCall: const BattleReplayException(
        'Histórico temporariamente indisponível.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(
          deckId: 'deck-1',
          gateway: gateway,
          initialReplayId: 'sim-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(gateway.listCalls, 1);
    expect(gateway.fetchCalls, 1);
    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('battle-replays-error-state')), findsNothing);
  });

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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ManaLoomGlyph &&
            widget.kind == ManaLoomGlyphKind.battleReplay,
      ),
      findsNWidgets(2),
    );
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
    await tester.ensureVisible(decisionsTab);
    await tester.pumpAndSettle();
    await tester.tap(decisionsTab);
    await tester.pumpAndSettle();

    expect(find.text('Cast Arcane Signet'), findsOneWidget);
    expect(find.text('Fixes mana before commander turn.'), findsOneWidget);
    expect(find.text('Dados'), findsNothing);

    final technicalDetails = find.byKey(
      const Key('battle-replay-technical-details-expansion'),
    );
    for (var i = 0; i < 8 && technicalDetails.evaluate().isEmpty; i += 1) {
      await tester.drag(detailPane, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(technicalDetails, findsOneWidget);
    await tester.ensureVisible(technicalDetails);
    await tester.pumpAndSettle();
    expect(find.text('Dados técnicos'), findsOneWidget);
    await tester.tap(technicalDetails);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('"engine": "manaloom_native_reviewed"'),
      findsOneWidget,
    );
  });

  testWidgets('keeps a replay as an explicit comparison baseline', (
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
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    final detailPane = find.byKey(const Key('battle-replay-detail-pane'));
    final useCurrent = find.byKey(const Key('battle-comparison-use-current'));
    for (var i = 0; i < 8 && useCurrent.evaluate().isEmpty; i += 1) {
      await tester.drag(detailPane, const Offset(0, -300));
      await tester.pumpAndSettle();
    }

    expect(useCurrent, findsOneWidget);
    await tester.ensureVisible(useCurrent);
    await tester.drag(detailPane, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(useCurrent);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('battle-comparison-baseline-selected')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Seed igual é somente um rótulo'),
      findsOneWidget,
    );
  });

  testWidgets('saves a private replay note through the account gateway', (
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
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    final detailPane = find.byKey(const Key('battle-replay-detail-pane'));
    final annotations = find.byKey(const Key('battle-annotations-expansion'));
    for (var i = 0; i < 8 && annotations.evaluate().isEmpty; i += 1) {
      await tester.drag(detailPane, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(annotations, findsOneWidget);
    await tester.ensureVisible(annotations);
    await tester.tap(annotations);
    await tester.pumpAndSettle();

    final addNote = find.byKey(const Key('battle-annotation-add-note'));
    await tester.ensureVisible(addNote);
    await tester.drag(detailPane, const Offset(0, 180));
    await tester.pumpAndSettle();
    await tester.tap(addNote);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('battle-note-title')),
      'Sequência de proteção',
    );
    await tester.enterText(
      find.byKey(const Key('battle-note-text')),
      'Eu seguraria a remoção para a pilha seguinte.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('battle-note-save')));
    await tester.pumpAndSettle();

    expect(gateway.lastAnnotationDraft?.kind, BattleReplayAnnotationKind.note);
    expect(
      gateway.lastAnnotationDraft?.payload['text'],
      'Eu seguraria a remoção para a pilha seguinte.',
    );
    expect(find.text('Sequência de proteção'), findsOneWidget);
    expect(find.textContaining('não usa shared_preferences'), findsOneWidget);
  });

  testWidgets('captures reflection before revealing the next event', (
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
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    final reflect = find.byKey(const Key('battle-visual-reflect-before-next'));
    expect(reflect, findsOneWidget);
    await tester.ensureVisible(reflect);
    await tester.tap(reflect);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-reflection-dialog')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('battle-reflection-reason')),
      'Eu manteria mana aberta.',
    );
    await tester.tap(find.byKey(const Key('battle-reflection-save')));
    await tester.pumpAndSettle();

    expect(
      gateway.lastAnnotationDraft?.kind,
      BattleReplayAnnotationKind.wouldDoDifferently,
    );
    expect(gateway.lastAnnotationDraft?.eventRef, 'event:0');
    expect(
      gateway.lastAnnotationDraft?.payload['reason'],
      'Eu manteria mana aberta.',
    );
  });

  testWidgets('records Keep before revealing detailed replay heuristics', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      replayDetail: BattleReplayDetail.fromJson(
        {
          'id': 'sim-1',
          'deck_id': 'deck-1',
          'deck_a_id': 'deck-1',
          'deck_b_id': 'deck-2',
          'type': 'battle',
          'opponent_name': 'Atraxa Superfriends',
          'winner_name': 'Player A',
          'turns': 2,
          'learning_contract': const {
            'schema_version': 'native_battle_learning_v1',
            'decision_trace_available': true,
          },
          'decision_trace': const [
            {
              'turn': 1,
              'choice': 'Cast Arcane Signet',
              'reason': 'Fixes mana before commander turn.',
            },
          ],
          'visual_snapshots': [
            {
              'turn': 0,
              'phase': 'opening_hand',
              'action': 'opening_hand',
              'event': const {
                'turn': 0,
                'phase': 'opening_hand',
                'action': 'opening_hand',
                'mulligan_number': 0,
              },
              'players': [
                {
                  'name': 'Player A',
                  'deck_key': 'deck_a',
                  'hand': [
                    for (var index = 0; index < 7; index += 1)
                      {
                        'id': 'opening-$index',
                        'name': index < 3 ? 'Island' : 'Spell $index',
                        'type_line': index < 3 ? 'Basic Land' : 'Instant',
                      },
                  ],
                  'battlefield': const <Map<String, dynamic>>[],
                  'graveyard': const <Map<String, dynamic>>[],
                },
                {
                  'name': 'Player B',
                  'deck_key': 'deck_b',
                  'hand_size': 7,
                  'battlefield': const <Map<String, dynamic>>[],
                  'graveyard': const <Map<String, dynamic>>[],
                },
              ],
            },
          ],
        },
        fallbackDeckId: 'deck-1',
        fallbackId: 'sim-1',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-opening-hand-gate')), findsOneWidget);
    expect(find.byKey(const Key('battle-replay-detail-pane')), findsNothing);
    expect(find.textContaining('Vencedor:'), findsNothing);
    expect(find.text('Cast Arcane Signet'), findsNothing);

    final keepButton = find.byKey(const Key('battle-opening-hand-keep'));
    await tester.ensureVisible(keepButton);
    await tester.pumpAndSettle();
    await tester.tap(keepButton);
    await tester.pumpAndSettle();

    expect(
      gateway.lastAnnotationDraft?.kind,
      BattleReplayAnnotationKind.mulliganDecision,
    );
    expect(gateway.lastAnnotationDraft?.snapshotRef, 'snapshot:0');
    expect(gateway.lastAnnotationDraft?.payload, {
      'choice': 'keep',
      'hand_size': 7,
      'mulligan_number': 0,
    });
    expect(find.byKey(const Key('battle-opening-hand-gate')), findsNothing);
    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
    expect(find.textContaining('Vencedor: Player A'), findsOneWidget);
  });

  testWidgets('filters saved history by outcome without deleting replays', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      replays: [
        BattleReplaySummary.fromJson(const {
          'id': 'completed-replay',
          'deck_id': 'deck-1',
          'type': 'battle',
          'status': 'completed',
          'engine': 'xmage',
          'opponent_deck_id': 'opponent-a',
          'opponent_name': 'Atraxa',
          'deck_revision': {
            'subject_deck_hash':
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          },
        }),
        BattleReplaySummary.fromJson(const {
          'id': 'censored-replay',
          'deck_id': 'deck-1',
          'type': 'battle',
          'status': 'censored',
          'engine': 'forge',
          'opponent_deck_id': 'opponent-b',
          'opponent_name': 'Korvold',
          'deck_revision': {
            'subject_deck_hash':
                'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          },
        }),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('battle-replay-summary-completed-replay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-replay-summary-censored-replay')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('battle-history-filters-expansion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('battle-history-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Censurado').last);
    await tester.pumpAndSettle();
    expect(find.text('1 de 2 replays'), findsOneWidget);

    final clearFilters = find.byKey(const Key('battle-history-clear-filters'));
    await tester.ensureVisible(clearFilters);
    await tester.pumpAndSettle();
    await tester.tap(clearFilters);
    await tester.pumpAndSettle();
    expect(find.text('2 de 2 replays'), findsOneWidget);
  });

  testWidgets('loads the next saved-history page with an opaque cursor', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      replays: [
        BattleReplaySummary.fromJson(const {
          'id': 'replay-first',
          'deck_id': 'deck-1',
          'type': 'battle',
          'status': 'completed',
          'opponent_name': 'Primeiro oponente',
        }),
      ],
      moreReplays: [
        BattleReplaySummary.fromJson(const {
          'id': 'replay-second',
          'deck_id': 'deck-1',
          'type': 'battle',
          'status': 'timeout',
          'opponent_name': 'Segundo oponente',
        }),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Battle contra Primeiro oponente'), findsOneWidget);
    expect(find.text('Battle contra Segundo oponente'), findsNothing);
    final loadMore = find.byKey(const Key('battle-history-load-more'));
    expect(loadMore, findsOneWidget);
    await tester.ensureVisible(loadMore);
    await tester.tap(loadMore);
    await tester.pumpAndSettle();

    expect(find.text('Battle contra Segundo oponente'), findsOneWidget);
    expect(find.byKey(const Key('battle-history-load-more')), findsNothing);
    expect(gateway.listCalls, 2);
  });

  testWidgets('bounds initial rendering for a 20 thousand event replay', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      replayDetail: BattleReplayDetail.fromJson(
        {
          'id': 'sim-1',
          'deck_id': 'deck-1',
          'type': 'battle',
          'events': [
            for (var index = 0; index < 20000; index++)
              {
                'event_id': 'event-$index',
                'turn': (index ~/ 20) + 1,
                'player': index.isEven ? 'Player A' : 'Player B',
                'action': index.isEven ? 'casts' : 'resolves',
                'message': 'Evento observado $index',
              },
          ],
        },
        fallbackDeckId: 'deck-1',
        fallbackId: 'sim-1',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    final renderedEventTiles = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('battle-replay-event-item-');
    });
    expect(renderedEventTiles, findsNWidgets(100));
    expect(
      find.text('Mostrando 100 de 20000 eventos observados'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-replay-events-show-more')),
      findsOneWidget,
    );
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

  testWidgets('plays snapshots and exposes observed stack and combat', (
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
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    final play = find.byKey(const Key('battle-visual-play-button'));
    await tester.ensureVisible(play);
    await tester.pumpAndSettle();
    await tester.tap(play);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Player A attacks Serra Angel'), findsOneWidget);
    expect(find.text('Prioridade: Player B'), findsOneWidget);
    expect(find.byKey(const Key('battle-visual-zone-stack')), findsOneWidget);
    expect(find.byKey(const Key('battle-visual-combat-panel')), findsOneWidget);
    expect(
      find.byKey(const Key('battle-replay-observed-changes')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Serra Angel entrou no campo observado'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Island saiu do campo observado'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-visual-zone-command-Player A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('battle-visual-zone-exile-Player A')),
      findsOneWidget,
    );
    expect(find.text('2/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports keyboard replay navigation and reduced motion', (
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
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Player A attacks Serra Angel'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    final play = tester.widget<IconButton>(
      find.byKey(const Key('battle-visual-play-button')),
    );
    expect(play.onPressed, isNull);
  });

  testWidgets('keeps replay usable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _FakeBattleReplayGateway();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
    expect(
      find.byKey(const Key('battle-replay-visual-viewer')),
      findsOneWidget,
    );
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

      final carousel = find
          .byKey(const Key('battle-visual-card-carousel'))
          .first;
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

  testWidgets('offers independent 1/3/5/10 samples for async Battle', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(
          deckId: 'deck-1',
          gateway: gateway,
          jobGateway: _EmptyBattleJobGateway(),
          battleLiveEnabled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('battle-run-live-button')));
    await tester.pumpAndSettle();

    final seriesField = find.byKey(const Key('battle-series-size-field'));
    expect(seriesField, findsOneWidget);
    await tester.ensureVisible(seriesField);
    await tester.tap(seriesField);
    await tester.pumpAndSettle();

    expect(find.text('1 tentativa').last, findsOneWidget);
    expect(find.text('Série de 3').last, findsOneWidget);
    expect(find.text('Série de 5').last, findsOneWidget);
    expect(find.text('Série de 10').last, findsOneWidget);
    expect(find.textContaining('não há RNG pareado'), findsOneWidget);
  });

  testWidgets('runs a focused objective only after a ready preflight', (
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
    await tester.tap(
      find.byKey(
        const Key('battle-opponent-deck-11111111-1111-4111-8111-111111111111'),
      ),
    );
    await tester.pumpAndSettle();

    expect(gateway.preflightCalls, 1);
    expect(find.byKey(const Key('battle-preflight-ready')), findsOneWidget);

    final objective = find.byKey(const Key('battle-test-objective-field'));
    await tester.ensureVisible(objective);
    await tester.tap(objective);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartas de foco').last);
    await tester.pumpAndSettle();

    final focus = find.byKey(const Key('battle-focus-cards-field'));
    await tester.ensureVisible(focus);
    await tester.enterText(
      focus,
      'Sol Ring, Arcane Signet, Rhystic Study, Cyclonic Rift',
    );
    await tester.tap(find.byKey(const Key('battle-opponent-submit-button')));
    await tester.pumpAndSettle();

    expect(gateway.runBattleCalls, 1);
    expect(gateway.lastSetup?.objective, BattleTestObjective.focusCards);
    expect(gateway.lastSetup?.focusCards, const [
      'Sol Ring',
      'Arcane Signet',
      'Rhystic Study',
    ]);
  });

  testWidgets('keeps Battle blocked when preflight has a hard blocker', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway(
      preflight: const BattlePreflight(
        status: 'blocked',
        cardCount: 99,
        commanderCount: 1,
        validationState: 'draft',
        availableOpponentCount: 2,
        engineCoverage: {'xmage': 'unknown'},
        blockers: ['deck_validation_required'],
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
        const Key('battle-opponent-deck-11111111-1111-4111-8111-111111111111'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-preflight-blocked')), findsOneWidget);
    expect(find.text('Valide novamente o deck'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('battle-opponent-submit-button')),
    );
    expect(button.onPressed, isNull);
    expect(gateway.runBattleCalls, 0);
  });

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
