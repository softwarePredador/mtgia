import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_live_cursor.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_live_spectator_screen.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
import 'package:manaloom/features/home/home_screen.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/market/providers/market_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/retention/screens/post_game_notes_screen.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
  defaultValue: true,
);
const _uiSourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _uiProofProfile = String.fromEnvironment('MANALOOM_UI_PROOF_PROFILE');
const _uiProofTarget = String.fromEnvironment('MANALOOM_UI_PROOF_TARGET');
const _uiProofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
);
const _commanderImageUrl = String.fromEnvironment(
  'MANALOOM_VISUAL_COMMANDER_IMAGE_URL',
);
const _artifactImageUrl = String.fromEnvironment(
  'MANALOOM_VISUAL_ARTIFACT_IMAGE_URL',
);
const _visualWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _visualHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);

String get _commanderFixtureUrl => _captureRuntimeProof
    ? Uri.base
          .resolve(
            'assets/assets/branding/visual_fixture_arcane_artificer.webp',
          )
          .toString()
    : _commanderImageUrl;

String get _artifactFixtureUrl => _captureRuntimeProof
    ? Uri.base
          .resolve('assets/assets/branding/visual_fixture_arcane_ring.webp')
          .toString()
    : _artifactImageUrl;

String get _secondaryArtifactFixtureUrl => _captureRuntimeProof
    ? Uri.base
          .resolve('assets/assets/branding/visual_fixture_blue_spell.webp')
          .toString()
    : _artifactImageUrl;

const _deckId = 'deck-battle-learning-proof';
const _deckHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _solRingId = '91fdb56b-54d5-4272-8319-505ff987fe9b';
const _thoughtVesselId = 'ad077996-6b5e-4eb8-bb6e-93d43c5efa8f';
const _alelaId = 'abc9e41e-fd03-4b6f-8f44-17ba94fa44f5';

const _requiredCheckpoints = <String>[
  'battle_learning_00_play_entry',
  'battle_learning_01_active_session',
  'battle_learning_02_live_table',
  'battle_learning_03_reconnect',
  'battle_learning_04_timeout',
  'battle_learning_05_completed',
  'battle_learning_06_replay_evidence',
  'battle_learning_07_postgame_signals',
  'battle_learning_08_postgame_receipt',
  'battle_learning_09_optimize_evidence',
];

class _FlutterTesterCacheManager implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.error(
    StateError('Network card artwork is disabled in flutter-tester.'),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopApiClient extends ApiClient {}

class _RuntimeDeckProvider extends DeckProvider {
  _RuntimeDeckProvider(this.details) : super(apiClient: _NoopApiClient());

  final DeckDetails details;

  @override
  List<Deck> get decks => <Deck>[details];

  @override
  DeckDetails? get selectedDeck => details;

  @override
  Future<void> fetchDecks({bool silent = false}) async {}

  @override
  Future<void> fetchDeckDetails(
    String deckId, {
    bool forceRefresh = false,
  }) async {}
}

class _IdleMarketProvider extends MarketProvider {
  _IdleMarketProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<void> fetchMovers({
    double minPrice = 1.0,
    int limit = 20,
    bool force = false,
  }) async {}
}

DeckDetails _proofDeck() {
  return DeckDetails(
    id: _deckId,
    name: 'Alela · Arquivo da Mesa',
    format: 'commander',
    description: 'Artefatos, encantamentos e valor incremental.',
    archetype: 'Artifacts',
    bracket: 3,
    commanderName: 'Alela, Artful Provocateur',
    commanderImageUrl: _commanderFixtureUrl,
    colorIdentity: const <String>['W', 'U', 'B'],
    validationState: Deck.validationStateValidated,
    reviewReasons: const <String>[],
    isPublic: false,
    createdAt: DateTime.utc(2026, 8, 1, 12),
    cardCount: 100,
    stats: const <String, dynamic>{'total_cards': 100},
    deckSnapshotHash: _deckHash,
    deckVersionAt: DateTime.utc(2026, 8, 5, 11, 30),
    commander: <DeckCardItem>[
      DeckCardItem(
        id: _alelaId,
        name: 'Alela, Artful Provocateur',
        manaCost: '{1}{W}{U}{B}',
        typeLine: 'Legendary Creature — Faerie Warlock',
        colors: const <String>['W', 'U', 'B'],
        colorIdentity: const <String>['W', 'U', 'B'],
        imageUrl: _commanderFixtureUrl,
        setCode: 'NCC',
        collectorNumber: '325',
        rarity: 'mythic',
        quantity: 1,
        isCommander: true,
      ),
    ],
    mainBoard: <String, List<DeckCardItem>>{
      'Artifact': <DeckCardItem>[
        DeckCardItem(
          id: _solRingId,
          name: 'Sol Ring',
          manaCost: '{1}',
          typeLine: 'Artifact',
          colors: const <String>[],
          colorIdentity: const <String>[],
          imageUrl: _artifactFixtureUrl,
          setCode: 'MSC',
          collectorNumber: '211',
          rarity: 'uncommon',
          quantity: 1,
          isCommander: false,
        ),
        DeckCardItem(
          id: _thoughtVesselId,
          name: 'Thought Vessel',
          manaCost: '{2}',
          typeLine: 'Artifact',
          colors: const <String>[],
          colorIdentity: const <String>[],
          imageUrl: _secondaryArtifactFixtureUrl,
          setCode: 'MBC',
          collectorNumber: '78',
          rarity: 'uncommon',
          quantity: 1,
          isCommander: false,
        ),
      ],
    },
  );
}

Widget _homeApp(DeckDetails deck, {Key? key}) {
  return MultiProvider(
    key: key,
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(apiClient: _NoopApiClient()),
      ),
      ChangeNotifierProvider<DeckProvider>(
        create: (_) => _RuntimeDeckProvider(deck),
      ),
      ChangeNotifierProvider<MarketProvider>(
        create: (_) => _IdleMarketProvider(),
      ),
      ChangeNotifierProvider<MessageProvider>(
        create: (_) => MessageProvider(apiClient: _NoopApiClient()),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(apiClient: _NoopApiClient()),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: const HomeScreen(lifeCounterAvailable: true),
    ),
  );
}

class _RuntimeReplayGateway extends BattleReplayGateway {
  _RuntimeReplayGateway({required this.detail});

  final BattleReplayDetail detail;

  BattleReplaySummary get summary => detail.summary;

  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async =>
      <BattleReplaySummary>[summary];

  @override
  Future<BattleReplayPageResult> listReplayPage(
    String deckId, {
    String? cursor,
    int limit = 30,
  }) async => BattleReplayPageResult(
    items: cursor == null ? <BattleReplaySummary>[summary] : const [],
    hasMore: false,
    nextCursor: null,
  );

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) async => detail;

  @override
  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  }) async => detail;

  @override
  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  }) async => detail;
}

BattleReplayDetail _proofReplay() {
  return BattleReplayDetail.fromJson(
    <String, dynamic>{
      'replay': <String, dynamic>{
        'id': 'replay-proof-1',
        'deck_id': _deckId,
        'deck_name': 'Alela · Arquivo da Mesa',
        'type': 'battle',
        'status': 'completed',
        'source': 'battle_simulations',
        'engine': 'manaloom_native_reviewed',
        'opponent_name': 'Atraxa Superfriends',
        'opponent_deck_id': 'deck-opponent-proof',
        'winner_deck_id': _deckId,
        'winner_name': 'Alela · Arquivo da Mesa',
        'created_at': '2026-08-05T11:30:00.000Z',
        'turns': 8,
        'deck_revision': const <String, dynamic>{
          'subject_deck_hash': _deckHash,
          'compatibility': 'exact',
        },
        'learning_contract': const <String, dynamic>{
          'schema_version': 'native_battle_learning_v1',
          'decision_trace_available': true,
        },
        'events': const <Map<String, dynamic>>[
          <String, dynamic>{
            'turn': 2,
            'player': 'Alela · Arquivo da Mesa',
            'phase': 'main',
            'action': 'casts',
            'card': 'Sol Ring',
          },
          <String, dynamic>{
            'turn': 6,
            'player': 'Alela · Arquivo da Mesa',
            'phase': 'combat',
            'action': 'attacks',
            'card': 'Alela, Artful Provocateur',
          },
        ],
        'decision_trace': const <Map<String, dynamic>>[
          <String, dynamic>{
            'turn': 2,
            'choice': 'Cast Sol Ring',
            'reason': 'Acelera o comandante sem expor a mão adversária.',
          },
        ],
        'visual_snapshots': <Map<String, dynamic>>[
          <String, dynamic>{
            'turn': 2,
            'phase': 'main',
            'action': 'casts',
            'active_player': 'Alela · Arquivo da Mesa',
            'event': const <String, dynamic>{
              'turn': 2,
              'player': 'Alela · Arquivo da Mesa',
              'phase': 'main',
              'action': 'casts',
              'card': 'Sol Ring',
            },
            'players': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'Alela · Arquivo da Mesa',
                'life': 40,
                'mana': 1,
                'hand_size': 6,
                'battlefield': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': _solRingId,
                    'card_id': _solRingId,
                    'name': 'Sol Ring',
                    'image_url': _artifactFixtureUrl,
                    'type_line': 'Artifact',
                  },
                  const <String, dynamic>{
                    'name': 'Token de Tesouro',
                    'type_line': 'Token Artifact — Treasure',
                  },
                ],
                'graveyard': const <Map<String, dynamic>>[],
                'command': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': _alelaId,
                    'card_id': _alelaId,
                    'name': 'Alela, Artful Provocateur',
                    'image_url': _commanderFixtureUrl,
                    'type_line': 'Legendary Creature — Faerie Warlock',
                  },
                ],
                'library_size': 91,
              },
              const <String, dynamic>{
                'name': 'Atraxa Superfriends',
                'life': 37,
                'mana': 0,
                'hand_size': 7,
                'battlefield': <Map<String, dynamic>>[],
                'graveyard': <Map<String, dynamic>>[],
                'library_size': 93,
              },
            ],
          },
        ],
      },
    },
    fallbackDeckId: _deckId,
    fallbackId: 'replay-proof-1',
  );
}

Map<String, dynamic> get _optimizeEvidence => <String, dynamic>{
  'schema_version': 'post_game_optimize_evidence_v1',
  'note_id': 'note-proof-1',
  'note_revision': 3,
  'selected_card_count': 2,
  'issues': <String>['speed', 'mana'],
  'performed_well': <Map<String, dynamic>>[
    <String, dynamic>{
      'card_id': _solRingId,
      'name': 'Sol Ring',
      'quantity': 1,
      'image_url': _artifactFixtureUrl,
    },
  ],
  'underperformed': <Map<String, dynamic>>[
    <String, dynamic>{
      'card_id': _thoughtVesselId,
      'name': 'Thought Vessel',
      'quantity': 1,
      'image_url': _secondaryArtifactFixtureUrl,
    },
  ],
  'deck_revision': <String, dynamic>{'matches_current': true},
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('real Web release proves the battle-to-learning UX closure', (
    tester,
  ) async {
    if (!_captureRuntimeProof) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      CachedNetworkImageProvider.defaultCacheManager =
          _FlutterTesterCacheManager();
    }
    _expectRuntimeContract();
    _emitRuntimeContext();

    await binding.setSurfaceSize(
      Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
    );
    addTearDown(() => binding.setSurfaceSize(null));
    await clearRuntimeAuth();

    final deck = _proofDeck();
    await tester.pumpWidget(
      _homeApp(deck, key: const ValueKey<String>('home-fresh')),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.byKey(const Key('home-primary-action')));
    await pumpUntilFound(tester, find.byKey(const Key('home-play-deck-list')));
    await _waitForArtwork(
      tester,
      find.byKey(const Key('home-play-deck-$_deckId')),
      description: 'the selected deck artwork in the play entry',
    );
    expect(find.text('Nova partida rápida · sem deck'), findsOneWidget);
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[0],
      focus: find.byKey(const Key('home-play-deck-list')),
    );

    Navigator.of(
      tester.element(find.byKey(const Key('home-play-deck-list'))),
    ).pop();
    await tester.pumpAndSettle();
    await LifeCounterSessionStore().save(
      LifeCounterSession.initial(
        playerCount: 4,
        playSessionId: 'play-proof-1',
        deckId: _deckId,
        deckName: deck.name,
        deckSnapshotHash: _deckHash,
        deckVersionAtEpochMs: deck.deckVersionAt!.millisecondsSinceEpoch,
        startedAtEpochMs: DateTime.utc(2026, 8, 5, 12).millisecondsSinceEpoch,
      ),
    );
    await tester.pumpWidget(
      _homeApp(deck, key: const ValueKey<String>('home-paused')),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.byKey(const Key('home-primary-action')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-play-active-session')),
    );
    await _waitForArtwork(
      tester,
      find.byKey(const Key('home-play-deck-$_deckId')),
      description: 'the selected deck artwork in the paused-session entry',
    );
    expect(find.text('Retomar'), findsOneWidget);
    expect(find.text('Encerrar e registrar'), findsOneWidget);
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[1],
      focus: find.byKey(const Key('home-play-active-session')),
    );

    final liveGateway = _BattleLearningLiveGateway.active();
    await _pumpLive(tester, liveGateway);
    final exactLiveArt = find.byKey(
      const Key('battle-live-card-art-$_solRingId'),
    );
    await pumpUntilFound(tester, exactLiveArt);
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[2],
      focus: exactLiveArt.first,
      settle: const Duration(milliseconds: 1400),
    );

    liveGateway.showRecoverableFailure();
    await tester.tap(find.byKey(const Key('battle-live-refresh-button')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-live-reconnect-banner')),
    );
    expect(
      find.byKey(const Key('battle-live-record-event-spell-1')),
      findsOneWidget,
    );
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[3],
      focus: find.byKey(const Key('battle-live-reconnect-banner')),
    );

    liveGateway.showTimeout();
    await tester.tap(find.byKey(const Key('battle-live-inline-retry-button')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-live-new-attempt-button')),
    );
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[4],
      focus: find.byKey(const Key('battle-live-new-attempt-button')),
    );

    final completedGateway = _BattleLearningLiveGateway.completed();
    await _pumpLive(
      tester,
      completedGateway,
      key: const ValueKey<String>('completed-live'),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-live-open-replay-button')),
    );
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[5],
      focus: find.byKey(const Key('battle-live-open-replay-button')),
    );

    final replay = _proofReplay();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        home: BattleReplaysScreen(
          deckId: _deckId,
          gateway: _RuntimeReplayGateway(detail: replay),
          initialReplayId: replay.summary.id,
          battleLiveEnabled: false,
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('battle-replay-detail-pane')),
    );
    final replaySolRing = find.byKey(const Key('battle-visual-card-Sol Ring'));
    await pumpUntilFound(tester, replaySolRing);
    await _waitForArtwork(
      tester,
      replaySolRing,
      description: 'the exact replay card artwork',
    );
    final detailPane = find.byKey(const Key('battle-replay-detail-pane'));
    final evidenceHandoff = find.byKey(
      const Key('battle-replay-evidence-handoff'),
    );
    for (
      var attempt = 0;
      attempt < 12 && evidenceHandoff.evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.drag(detailPane, const Offset(0, -280));
      await tester.pump(const Duration(milliseconds: 180));
    }
    await pumpUntilFound(tester, evidenceHandoff);
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[6],
      focus: evidenceHandoff,
    );

    final noteStore = PostGameNoteStore();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        home: PostGameNotesScreen(
          deckId: _deckId,
          store: noteStore,
          playSessionId: 'battle-replay:${replay.summary.id}',
          sessionStartedAt: DateTime.utc(2026, 8, 5, 12),
          sessionEndedAt: DateTime.utc(2026, 8, 5, 13, 12),
          deckSnapshotHash: _deckHash,
          deckVersionAt: deck.deckVersionAt,
          deckLoader: (_) async => deck,
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('post-game-card-evidence-picker')),
    );
    final commanderCard = find.byKey(const Key('post-game-card-$_alelaId'));
    final reviewCard = find.byKey(
      const Key('post-game-card-$_thoughtVesselId'),
    );
    await tester.ensureVisible(commanderCard);
    await tester.tap(commanderCard);
    final nextEvidenceCards = find.byKey(
      const Key('post-game-deck-card-rail-next'),
    );
    if (nextEvidenceCards.evaluate().isNotEmpty) {
      await tester.tap(nextEvidenceCards);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(reviewCard);
    await tester.tap(reviewCard);
    await tester.tap(reviewCard);
    final speedIssue = find.byKey(const Key('post-game-issue-speed'));
    await tester.ensureVisible(speedIssue);
    await tester.tap(speedIssue);
    await tester.pump(const Duration(milliseconds: 250));
    await _waitForArtwork(
      tester,
      find.byKey(const Key('post-game-card-evidence-picker')),
      description: 'the exact post-game deck artwork',
    );
    expect(find.text('1 preservar'), findsOneWidget);
    expect(find.text('1 revisar'), findsOneWidget);
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[7],
      focus: find.byKey(const Key('post-game-card-evidence-picker')),
    );

    await tester.enterText(
      find.byKey(const Key('post-game-result-field')),
      'Vitória após estabilizar no turno 6',
    );
    final saveButton = find.byKey(const Key('post-game-save-button'));
    await tester.ensureVisible(saveButton);
    final saveCallback = tester.widget<ElevatedButton>(saveButton).onPressed;
    expect(saveCallback, isNotNull, reason: 'Evidence save must be enabled.');
    saveCallback!();
    await pumpUntilFound(
      tester,
      find.byKey(const Key('post-game-evidence-receipt')),
    );
    expect((await noteStore.loadNotes(_deckId)).single.revision, 1);
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[8],
      focus: find.byKey(const Key('post-game-evidence-receipt')),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showOptimizationPreviewDialog(
                  context,
                  mode: 'optimize',
                  archetype: 'Artifacts',
                  keepTheme: true,
                  preservedTheme: 'Alela e artefatos',
                  reasoning:
                      'A proposta usa somente os sinais autenticados do pós-jogo.',
                  intensity: OptimizeIntensity.focused,
                  optimizeIntensity: const <String, dynamic>{},
                  qualityWarning: null,
                  deckAnalysis: const <String, dynamic>{},
                  postAnalysis: const <String, dynamic>{},
                  warnings: const <String, dynamic>{},
                  metaReferenceContext: const <String, dynamic>{},
                  postGameEvidence: _optimizeEvidence,
                  canApply: false,
                  displayRemovals: const <Map<String, dynamic>>[],
                  displayAdditions: const <Map<String, dynamic>>[],
                ),
                child: const Text('Abrir evidência no Optimize'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir evidência no Optimize'));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('optimize-preview-post-game-evidence')),
    );
    final optimizeEvidence = find.byKey(
      const Key('optimize-preview-post-game-evidence'),
    );
    await _waitForArtwork(
      tester,
      optimizeEvidence,
      description: 'the authenticated Optimize evidence artwork',
    );
    await _capture(
      binding,
      tester,
      _requiredCheckpoints[9],
      focus: optimizeEvidence,
    );
    expect(
      find.textContaining('não autoriza aplicação automática'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

void _expectRuntimeContract() {
  if (!_captureRuntimeProof) return;
  expect(_uiSourceDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
  expect(
    _uiProofProfile,
    isIn(const <String>{
      'web_battle_learning_mobile_390x844',
      'web_battle_learning_desktop_1440x900',
      'web_battle_learning_wide_1920x1080',
    }),
  );
  expect(_uiProofTarget, 'web_real_build');
  expect(_uiProofDeviceContract.toLowerCase(), contains('chrome'));
  expect(Uri.parse(_commanderFixtureUrl).origin, Uri.base.origin);
  expect(Uri.parse(_artifactFixtureUrl).origin, Uri.base.origin);
  expect(Uri.parse(_secondaryArtifactFixtureUrl).origin, Uri.base.origin);
  expect(
    Uri.parse(_commanderFixtureUrl).path,
    endsWith('/assets/assets/branding/visual_fixture_arcane_artificer.webp'),
  );
  expect(
    Uri.parse(_artifactFixtureUrl).path,
    endsWith('/assets/assets/branding/visual_fixture_arcane_ring.webp'),
  );
  expect(
    Uri.parse(_secondaryArtifactFixtureUrl).path,
    endsWith('/assets/assets/branding/visual_fixture_blue_spell.webp'),
  );
}

void _emitRuntimeContext() {
  if (!_captureRuntimeProof) return;
  // ignore: avoid_print
  print(
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'battle_learning', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _requiredCheckpoints})}',
  );
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint, {
  Finder? focus,
  Duration settle = const Duration(milliseconds: 450),
}) async {
  if (focus != null) {
    await tester.ensureVisible(focus);
  }
  await tester.pump(settle);
  expect(tester.takeException(), isNull, reason: 'Before $checkpoint');
  expectNoRawTechnicalErrorText(tester);
  if (_captureRuntimeProof) {
    await captureVisualProof(binding, tester, checkpoint);
  }
  expect(tester.takeException(), isNull, reason: 'After $checkpoint');
}

Future<void> _waitForArtwork(
  WidgetTester tester,
  Finder scope, {
  required String description,
}) async {
  if (!_captureRuntimeProof) return;
  final loading = find.descendant(
    of: scope,
    matching: find.byKey(const Key('cached-card-image-loading')),
  );
  final error = find.descendant(
    of: scope,
    matching: find.byKey(const Key('cached-card-image-error')),
  );
  final missing = find.descendant(
    of: scope,
    matching: find.byKey(const Key('cached-card-image-placeholder')),
  );
  await pumpUntil(
    tester,
    () => loading.evaluate().isEmpty,
    description: description,
    attempts: 60,
    step: const Duration(milliseconds: 100),
  );
  expect(error, findsNothing, reason: '$description must not be an error.');
  expect(
    missing,
    findsNothing,
    reason: '$description must have an exact image URL.',
  );
}

Future<void> _pumpLive(
  WidgetTester tester,
  BattleJobGateway gateway, {
  Key? key,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: BattleLiveSpectatorScreen(
        key: key,
        deckId: _deckId,
        jobId: 'job-proof-1',
        gateway: gateway,
        featureEnabled: true,
        pollInterval: const Duration(hours: 1),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

enum _LiveProofState { active, recoverableFailure, timeout, completed }

class _BattleLearningLiveGateway extends BattleJobGateway {
  _BattleLearningLiveGateway.active() : _state = _LiveProofState.active;

  _BattleLearningLiveGateway.completed() : _state = _LiveProofState.completed;

  _LiveProofState _state;

  void showRecoverableFailure() => _state = _LiveProofState.recoverableFailure;

  void showTimeout() => _state = _LiveProofState.timeout;

  @override
  Future<BattleJob> get(String jobId) async => switch (_state) {
    _LiveProofState.active || _LiveProofState.recoverableFailure => _liveJob(),
    _LiveProofState.timeout => _liveJob(
      status: 'timeout',
      stage: 'timeout',
      terminalReason: 'battle_job_timeout',
      errorCode: 'battle_job_timeout',
    ),
    _LiveProofState.completed => _liveJob(
      status: 'completed',
      stage: 'completed',
      replayId: 'replay-proof-1',
      terminalReason: 'completed',
    ),
  };

  @override
  Future<BattleLiveSession> pollLive({
    required String jobId,
    BattleLiveSession session = const BattleLiveSession.empty(),
    int limit = 50,
  }) async => switch (_state) {
    _LiveProofState.active => session.apply(
      _livePage(
        status: 'running',
        items: <Map<String, dynamic>>[
          _liveEventRecord(sequence: 1, recordId: 'event-spell-1'),
          _liveSnapshotRecord(sequence: 2, recordId: 'snapshot-main-2'),
        ],
        nextCursor: 'blc1.active.signature',
      ),
    ),
    _LiveProofState.recoverableFailure => throw const BattleJobGatewayException(
      code: 'battle_transport_unavailable',
      message: 'Não foi possível atualizar o Battle agora.',
    ),
    _LiveProofState.timeout => session.apply(
      _livePage(
        status: 'timeout',
        terminalReason: 'battle_job_timeout',
        nextCursor: 'blc1.timeout.signature',
      ),
    ),
    _LiveProofState.completed => session.apply(
      _livePage(
        status: 'completed',
        terminalReason: 'completed',
        items: <Map<String, dynamic>>[
          _liveEventRecord(sequence: 1, recordId: 'event-spell-1'),
          _liveSnapshotRecord(sequence: 2, recordId: 'snapshot-main-2'),
        ],
        nextCursor: 'blc1.completed.signature',
        replay: const <String, Object>{
          'replay_id': 'replay-proof-1',
          'available': true,
        },
      ),
    ),
  };
}

BattleJob _liveJob({
  String status = 'running',
  String stage = 'running',
  String? replayId,
  String? terminalReason,
  String? errorCode,
}) {
  final terminal = const <String>{
    'completed',
    'censored',
    'timeout',
    'coverage_error',
    'engine_error',
    'cancelled',
    'persistence_error',
  }.contains(status);
  final current = terminal ? 100 : 58;
  return BattleJob.fromJson(<String, dynamic>{
    'schema_version': battleJobSchemaVersion,
    'job_id': 'job-proof-1',
    'idempotency_key': 'proof-attempt-1',
    'status': status,
    'stage': stage,
    'progress': <String, Object>{
      'current': current,
      'total': 100,
      'ratio': current / 100,
    },
    'deck_a_id': _deckId,
    'deck_b_id': 'deck-opponent-proof',
    'deck_hashes': <String, Object>{
      'schema_version': externalBattleDeckHashSchemaVersion,
      'algorithm': 'sha256',
      'deck_a': _hash('a'),
      'deck_b': _hash('b'),
    },
    'request_schema_version': battleJobRequestSchemaVersion,
    'request_hash': _hash('c'),
    'requested_engine': 'auto',
    'engine': null,
    'timeout_ms': battleJobDefaultTimeoutMs,
    'attempt_count': 1,
    'attempt_id': 'proof-attempt-run-1',
    if (replayId != null) 'replay_id': replayId,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    if (errorCode != null) 'error_code': errorCode,
    'started_at': '2099-01-01T00:00:00Z',
    'heartbeat_at': '2099-01-01T00:00:04Z',
    'created_at': '2099-01-01T00:00:00Z',
    'updated_at': terminal ? '2099-01-01T00:01:10Z' : '2099-01-01T00:00:04Z',
    if (terminal) 'finished_at': '2099-01-01T00:01:10Z',
    'can_cancel': !terminal,
    'can_resume': !terminal,
    'poll_url': '/ai/battle/jobs/job-proof-1',
    'cancel_url': '/ai/battle/jobs/job-proof-1',
  });
}

BattleLivePage _livePage({
  required String status,
  String? terminalReason,
  List<Map<String, dynamic>> items = const <Map<String, dynamic>>[],
  required String nextCursor,
  Map<String, Object>? replay,
}) {
  final terminal = const <String>{
    'completed',
    'censored',
    'timeout',
    'coverage_error',
    'engine_error',
    'cancelled',
    'persistence_error',
    'interrupted',
  }.contains(status);
  return BattleLivePage.fromJson(<String, dynamic>{
    'schema_version': battleLiveCursorSchemaVersion,
    'transport': battleLivePollingTransport,
    'stream_id': 'job-proof-1',
    'status': status,
    'is_terminal': terminal,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    'items': items,
    'item_count': items.length,
    'next_cursor': nextCursor,
    'has_more': false,
    'truncated': false,
    'truncation': const <String, bool>{
      'source': false,
      'page_limit': false,
      'payload_limit': false,
      'field_limit': false,
    },
    'limits': const <String, int>{'page': 50, 'payload_bytes': 131072},
    'replay_pending': false,
    'replay_already_delivered': false,
    if (replay != null) 'replay': replay,
  });
}

Map<String, dynamic> _liveEventRecord({
  required int sequence,
  required String recordId,
}) => <String, dynamic>{
  'schema_version': battleLiveCursorSchemaVersion,
  'cursor': 'blc1.event$sequence.signature',
  'sequence': sequence,
  'record_id': recordId,
  'kind': 'event',
  'event': const <String, Object>{
    'event_type': 'spell_cast',
    'event_id': 'event-spell-1',
    'turn': 2,
    'actor_side': 'deck_a',
    'subject_deck_key': 'deck_a',
    'card_id': _solRingId,
    'card_name': 'Sol Ring',
    'message': 'Alela conjurou Sol Ring.',
  },
  'content_truncated': false,
};

Map<String, dynamic> _liveSnapshotRecord({
  required int sequence,
  required String recordId,
}) => <String, dynamic>{
  'schema_version': battleLiveCursorSchemaVersion,
  'cursor': 'blc1.snapshot$sequence.signature',
  'sequence': sequence,
  'record_id': recordId,
  'kind': 'snapshot',
  'snapshot': const <String, Object>{
    'snapshot_id': 'snapshot-main-2',
    'index': 2,
    'turn': 2,
    'phase': 'main',
    'step': 'precombat',
    'players': <Map<String, Object>>[
      <String, Object>{
        'deck_key': 'deck_a',
        'name': 'Alela · Arquivo da Mesa',
        'life': 40,
        'hand_size': 6,
        'library_size': 91,
        'battlefield_count': 1,
        'graveyard_size': 0,
        'command_size': 1,
        'mana_available': 1,
        'battlefield': <Map<String, Object>>[
          <String, Object>{
            'object_id': 'permanent-sol-ring-1',
            'card_id': _solRingId,
            'name': 'Sol Ring',
            'tapped': false,
          },
        ],
        'graveyard': <Map<String, Object>>[],
        'command': <Map<String, Object>>[
          <String, Object>{
            'object_id': 'commander-alela-1',
            'card_id': _alelaId,
            'name': 'Alela, Artful Provocateur',
            'tapped': false,
          },
        ],
      },
      <String, Object>{
        'deck_key': 'deck_b',
        'name': 'Atraxa Superfriends',
        'life': 38,
        'hand_size': 7,
        'library_size': 92,
        'battlefield_count': 0,
        'graveyard_size': 1,
        'mana_available': 0,
        'battlefield': <Map<String, Object>>[],
        'graveyard': <Map<String, Object>>[
          <String, Object>{
            'object_id': 'graveyard-unknown-1',
            'name': 'Pista criada por efeito',
          },
        ],
      },
    ],
    'stack': <Object>[],
    'combat': <Object>[],
  },
  'content_truncated': false,
};

String _hash(String character) => List<String>.filled(64, character).join();
