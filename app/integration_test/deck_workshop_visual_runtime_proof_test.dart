import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/models/deck_optimization_event.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/decks/screens/deck_import_screen.dart';
import 'package:manaloom/features/decks/services/deck_entry_draft_store.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
import 'package:manaloom/features/decks/widgets/deck_workshop_tab.dart';
import 'package:manaloom/features/decks/widgets/sample_hand_widget.dart';
import 'package:provider/provider.dart';

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

const _requiredCheckpoints = <String>[
  'deck_workshop_00_commander',
  'deck_workshop_01_import_preflight',
  'deck_workshop_02_sources',
  'deck_workshop_03_paired_swaps',
  'deck_workshop_04_partial_selection',
  'deck_workshop_05_card_reader',
  'deck_workshop_06_history_undo',
  'deck_workshop_07_conflict',
  'deck_workshop_08_sample_hand_continuity',
];

String get _artificerImageUrl => _artifactImageUrl.isEmpty
    ? ''
    : Uri.parse(
        _artifactImageUrl,
      ).resolve('visual_fixture_arcane_artificer.webp').toString();

String get _emberImageUrl => _artifactImageUrl.isEmpty
    ? ''
    : Uri.parse(
        _artifactImageUrl,
      ).resolve('visual_fixture_ember_raiders.webp').toString();

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

class _RuntimeDeckWorkshopApi extends ApiClient {
  Map<String, dynamic> get _commander => <String, dynamic>{
    'id': '10000000-0000-4000-8000-000000000003',
    'oracle_id': '20000000-0000-4000-8000-000000000003',
    'name': 'Lorehold, the Historian',
    'mana_cost': '{3}{R}{W}',
    'type_line': 'Legendary Creature — Elder Dragon',
    'oracle_text': 'Artefatos e mágicas históricas alimentam o plano.',
    'colors': const ['R', 'W'],
    'color_identity': const ['R', 'W'],
    'set_code': 'STX',
    'set_name': 'Strixhaven: School of Mages',
    'collector_number': '238',
    'rarity': 'mythic',
    if (_commanderImageUrl.isNotEmpty) 'image_url': _commanderImageUrl,
  };

  Map<String, dynamic> get _solRing => <String, dynamic>{
    'card_id': '30000000-0000-4000-8000-000000000001',
    'name': 'Sol Ring',
    'type_line': 'Artifact',
    'quantity': 1,
    'is_commander': false,
    if (_artifactImageUrl.isNotEmpty) 'image_url': _artifactImageUrl,
  };

  @override
  Future<ApiResponse> get(String endpoint, {Duration? timeout}) async {
    if (endpoint == '/ai/commander-learning') {
      return ApiResponse(200, {'commanders': const <dynamic>[]});
    }
    if (endpoint == '/ai/generate/jobs/latest?active=true') {
      return ApiResponse(404, const {'error': 'not_found'});
    }
    if (endpoint.startsWith('/cards?')) {
      return ApiResponse(200, {
        'data': [_commander],
      });
    }
    throw StateError('Unexpected runtime GET $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/import/validate') {
      return ApiResponse(200, {
        'found_cards': [
          _commander,
          _solRing,
          <String, dynamic>{
            'card_id': '30000000-0000-4000-8000-000000000002',
            'name': 'Arcane Signet',
            'type_line': 'Artifact',
            'quantity': 1,
            'is_commander': false,
            if (_artifactImageUrl.isNotEmpty) 'image_url': _artifactImageUrl,
          },
          <String, dynamic>{
            'card_id': '30000000-0000-4000-8000-000000000003',
            'name': 'Command Tower',
            'type_line': 'Land',
            'quantity': 1,
            'is_commander': false,
            if (_commanderImageUrl.isNotEmpty) 'image_url': _commanderImageUrl,
          },
        ],
        'not_found_lines': const ['1 Carta Escrita Errado'],
        'localized_matches_count': 1,
        'warnings': const [
          'A linha não identificada ficará pendente em um rascunho.',
        ],
        'total_cards': 4,
        'total_unique': 4,
        'commander_detected': true,
        'missing_commander': false,
      });
    }
    throw StateError('Unexpected runtime POST $endpoint');
  }
}

class _MemoryDeckEntryDraftStore extends DeckEntryDraftStore {
  @override
  Future<Map<String, String>?> loadGenerate(String ownerId) async => null;

  @override
  Future<void> saveGenerate(
    String ownerId, {
    required String format,
    required String commander,
    required String prompt,
    required String deckName,
    int? bracket,
    String? activeJobId,
    String? requestKey,
    bool preferCollection = false,
    bool collectionOnly = false,
    String budgetLimitBrl = '',
  }) async {}

  @override
  Future<void> clearGenerate(String ownerId) async {}

  @override
  Future<Map<String, String>?> loadImport(String ownerId) async => null;

  @override
  Future<void> saveImport(
    String ownerId, {
    required String format,
    required String name,
    required String description,
    required String commander,
    required String cardList,
  }) async {}

  @override
  Future<void> clearImport(String ownerId) async {}
}

Map<String, dynamic> _change({
  required String cardId,
  required String name,
  required String role,
  required String reason,
  required double confidence,
  required String imageUrl,
}) {
  return <String, dynamic>{
    'card_id': cardId,
    'name': name,
    'quantity': 1,
    'image_url': imageUrl,
    'set_code': 'CMM',
    'collector_number': '396',
    'player_facing': <String, dynamic>{
      'summary': reason,
      'primary_role_label': role,
      'priority_label': 'Prioridade alta',
      'risk_label': 'Risco baixo',
    },
    'confidence': <String, dynamic>{'level': 'high', 'score': confidence},
    'estimated_price_brl': 18.5,
    'collection_status': 'owned',
  };
}

DeckCardItem _cardForChange(Map<String, dynamic> item) {
  return DeckCardItem(
    id: item['card_id'] as String,
    name: item['name'] as String,
    manaCost: '{2}',
    typeLine: item['name'] == 'Mind Stone' ? 'Artifact' : 'Legendary Artifact',
    oracleText: '{T}: Add one mana. Esta carta ajuda a executar o plano.',
    colors: const <String>[],
    colorIdentity: const <String>[],
    imageUrl: item['image_url']?.toString(),
    setCode: 'CMM',
    setName: 'Commander Masters',
    setReleaseDate: '2023-08-04',
    rarity: 'uncommon',
    quantity: 1,
    isCommander: false,
    collectorNumber: item['collector_number']?.toString(),
  );
}

DeckDetails _workshopDeck() {
  return DeckDetails(
    id: 'deck-runtime-1',
    name: 'Lorehold Archive Workshop',
    format: 'commander',
    description: 'Mágicas históricas, artefatos e valor incremental.',
    archetype: 'Historic big spells',
    bracket: 3,
    validationState: 'validated',
    colorIdentity: const ['R', 'W'],
    isPublic: false,
    createdAt: DateTime.utc(2026, 8, 5),
    cardCount: 100,
    stats: const {'total_cards': 100},
    commander: [
      DeckCardItem.fromJson({
        'id': '10000000-0000-4000-8000-000000000003',
        'name': 'Lorehold, the Historian',
        'type_line': 'Legendary Creature — Elder Dragon',
        'colors': const ['R', 'W'],
        'color_identity': const ['R', 'W'],
        'set_code': 'STX',
        'rarity': 'mythic',
        'quantity': 1,
        'is_commander': true,
        if (_commanderImageUrl.isNotEmpty) 'image_url': _commanderImageUrl,
      }),
    ],
    mainBoard: <String, List<DeckCardItem>>{
      'Amostra determinística': <DeckCardItem>[
        DeckCardItem(
          id: 'sample-sol-ring',
          name: 'Sol Ring',
          manaCost: '{1}',
          typeLine: 'Artifact',
          imageUrl: _artifactImageUrl,
          setCode: 'FIX',
          collectorNumber: '1',
          rarity: 'uncommon',
          quantity: 25,
          isCommander: false,
        ),
        DeckCardItem(
          id: 'sample-counterspell',
          name: 'Counterspell',
          manaCost: '{U}{U}',
          typeLine: 'Instant',
          imageUrl: _commanderImageUrl,
          setCode: 'FIX',
          collectorNumber: '2',
          rarity: 'uncommon',
          quantity: 25,
          isCommander: false,
        ),
        DeckCardItem(
          id: 'sample-academy-manufactor',
          name: 'Academy Manufactor',
          manaCost: '{3}',
          typeLine: 'Artifact Creature — Assembly-Worker',
          imageUrl: _artificerImageUrl,
          setCode: 'FIX',
          collectorNumber: '3',
          rarity: 'rare',
          quantity: 25,
          isCommander: false,
        ),
        DeckCardItem(
          id: 'sample-deflecting-swat',
          name: 'Deflecting Swat',
          manaCost: '{2}{R}',
          typeLine: 'Instant',
          imageUrl: _emberImageUrl,
          setCode: 'FIX',
          collectorNumber: '4',
          rarity: 'rare',
          quantity: 24,
          isCommander: false,
        ),
      ],
    },
  );
}

DeckOptimizationEvent _historyEvent({required bool canRollback}) {
  return DeckOptimizationEvent.fromJson({
    'id': 'event-runtime-1',
    'event_type': 'optimize_apply',
    'mode': 'optimize',
    'intensity': 'focused',
    'archetype': 'Historic big spells',
    'bracket': 3,
    'selected_change_count': 4,
    'validation_status': 'validated',
    'battle_status': 'pending_after_apply',
    'battle_message': 'Battle e replay pendentes após a aplicação.',
    'created_at': '2026-08-05T17:40:00.000Z',
    'can_rollback': canRollback,
    'rollback_reason': canRollback ? '' : 'deck_changed_after_apply',
    'removals': [
      _change(
        cardId: 'remove-runtime-1',
        name: 'Mind Stone',
        role: 'Ramp lento',
        reason: 'Sai para reduzir redundância na curva três.',
        confidence: 0.88,
        imageUrl: _artifactImageUrl,
      ),
      _change(
        cardId: 'remove-runtime-2',
        name: 'Cancel',
        role: 'Interação',
        reason: 'Sai por exigir mana demais para proteger o turno.',
        confidence: 0.82,
        imageUrl: _commanderImageUrl,
      ),
    ],
    'additions': [
      _change(
        cardId: 'add-runtime-1',
        name: 'Arcane Signet',
        role: 'Ramp eficiente',
        reason: 'Entra para acelerar o comandante sem mudar o bracket.',
        confidence: 0.93,
        imageUrl: _artifactImageUrl,
      ),
      _change(
        cardId: 'add-runtime-2',
        name: 'Deflecting Swat',
        role: 'Proteção',
        reason: 'Entra para proteger a linha principal com o comandante.',
        confidence: 0.86,
        imageUrl: _commanderImageUrl,
      ),
    ],
    'source_summary': const {
      'post_analysis_source': 'server_recomputed_from_persisted_selection',
      'has_meta_reference': true,
      'reference_count': 2,
    },
  });
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint,
) async {
  if (!_captureRuntimeProof) return;
  await captureVisualProof(binding, tester, checkpoint);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 280));
}

Widget _workshopApp({required bool canRollback, String? errorMessage}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: DeckWorkshopTab(
        deck: _workshopDeck(),
        events: [_historyEvent(canRollback: canRollback)],
        isLoading: false,
        errorMessage: errorMessage,
        onRefresh: () async {},
        onOptimize: () {},
        onValidate: () {},
        onRollback: (_) async {},
        onOpenSampleHand: () {},
        onOpenBattle: () {},
      ),
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real Web surfaces prove commander, import preflight, paired evidence, reader and persistent undo',
    (tester) async {
      if (!_captureRuntimeProof) {
        CachedNetworkImageProvider.defaultCacheManager =
            _FlutterTesterCacheManager();
      }
      if (_captureRuntimeProof) {
        expect(_uiSourceDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(_uiProofProfile, isNotEmpty);
        expect(_uiProofTarget, 'web_real_build');
        expect(_uiProofDeviceContract.toLowerCase(), contains('chrome'));
        expect(_commanderImageUrl, startsWith('http://127.0.0.1:'));
        expect(_artifactImageUrl, startsWith('http://127.0.0.1:'));
        // ignore: avoid_print
        print(
          'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'deck_workshop', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _requiredCheckpoints})}',
        );
      }

      await binding.setSurfaceSize(
        Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));

      final api = _RuntimeDeckWorkshopApi();
      final draftStore = _MemoryDeckEntryDraftStore();
      final generateDeckProvider = DeckProvider(apiClient: api);
      final commanderCardProvider = CardProvider(apiClient: api);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeckProvider>(
              create: (_) => generateDeckProvider,
            ),
            ChangeNotifierProvider<CardProvider>(
              create: (_) => commanderCardProvider,
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: DeckGenerateScreen(
              draftOwnerId: 'ux-pack-03-runtime-generate',
              draftStore: draftStore,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final commanderSelect = find.byKey(
        const Key('deck-create-commander-select'),
      );
      await _reveal(tester, commanderSelect);
      await tester.tap(commanderSelect);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-create-commander-search-field')),
      );
      final commanderSearch = tester.widget<TextField>(
        find.byKey(const Key('deck-create-commander-search-field')),
      );
      commanderSearch.controller!.text = 'Lorehold';
      commanderSearch.onChanged!.call('Lorehold');
      await tester.pump();
      await commanderCardProvider.searchCommanderCandidates(
        'Lorehold',
        format: 'commander',
      );
      await tester.pump(const Duration(milliseconds: 350));
      final commanderResult = find.byKey(
        const Key(
          'deck-create-commander-result-10000000-0000-4000-8000-000000000003',
        ),
      );
      await pumpUntilFound(tester, commanderResult);
      await _reveal(tester, commanderResult);
      await tester.tap(commanderResult);
      final selectedCommander = find.byKey(
        const Key('deck-create-commander-selected'),
      );
      await pumpUntilFound(tester, selectedCommander);
      await _reveal(tester, selectedCommander);
      expect(
        find.descendant(
          of: selectedCommander,
          matching: find.text('Lorehold, the Historian'),
        ),
        findsOneWidget,
      );
      final parentSubmit = find.byKey(
        const Key('deck-generate-submit-cta-frame'),
      );
      await _reveal(tester, parentSubmit);
      expect(parentSubmit, findsOneWidget);
      expect(selectedCommander, findsOneWidget);
      await _capture(binding, tester, 'deck_workshop_00_commander');

      await tester.pumpWidget(
        ChangeNotifierProvider<DeckProvider>(
          create: (_) => DeckProvider(apiClient: api),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: DeckImportScreen(
              draftOwnerId: 'ux-pack-03-runtime-import',
              draftStore: draftStore,
            ),
          ),
        ),
      );
      final importName = find.byKey(const Key('deck-import-screen-name-field'));
      await pumpUntilFound(tester, importName);
      tester.widget<TextField>(importName).controller!.text =
          'Lorehold Archive';
      tester
              .widget<TextField>(
                find.byKey(const Key('deck-import-screen-commander-field')),
              )
              .controller!
              .text =
          'Lorehold, the Historian';
      tester
              .widget<TextField>(
                find.byKey(const Key('deck-import-screen-list-field')),
              )
              .controller!
              .text =
          '1 Sol Ring\n1 Arcane Signet\n1 Command Tower\n1 Carta Escrita Errado';
      await tester.pump(const Duration(milliseconds: 200));
      final submit = find.byKey(const Key('deck-import-screen-submit-button'));
      await _reveal(tester, submit);
      tester.widget<ElevatedButton>(submit).onPressed!();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-import-preflight')),
      );
      await _reveal(tester, find.byKey(const Key('deck-import-preflight')));
      expect(find.text('Criar como rascunho'), findsOneWidget);
      await _capture(binding, tester, 'deck_workshop_01_import_preflight');

      final removals = <Map<String, dynamic>>[
        _change(
          cardId: 'remove-runtime-1',
          name: 'Mind Stone',
          role: 'Ramp lento',
          reason: 'Sai para reduzir redundância na curva três.',
          confidence: 0.88,
          imageUrl: _artifactImageUrl,
        ),
        _change(
          cardId: 'remove-runtime-2',
          name: 'Cancel',
          role: 'Interação',
          reason: 'Sai por exigir mana demais para proteger o turno.',
          confidence: 0.82,
          imageUrl: _commanderImageUrl,
        ),
      ];
      final additions = <Map<String, dynamic>>[
        _change(
          cardId: 'add-runtime-1',
          name: 'Arcane Signet',
          role: 'Ramp eficiente',
          reason: 'Entra para acelerar o comandante sem mudar o bracket.',
          confidence: 0.93,
          imageUrl: _artifactImageUrl,
        ),
        _change(
          cardId: 'add-runtime-2',
          name: 'Deflecting Swat',
          role: 'Proteção',
          reason: 'Entra para proteger a linha principal com o comandante.',
          confidence: 0.86,
          imageUrl: _commanderImageUrl,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showOptimizationPreviewDialog(
                    context,
                    mode: 'optimize',
                    archetype: 'Historic big spells',
                    keepTheme: true,
                    preservedTheme: 'Históricas e artefatos',
                    reasoning:
                        'A proposta reduz peças lentas e preserva identidade, quantidade e bracket.',
                    intensity: OptimizeIntensity.focused,
                    optimizeIntensity: const {
                      'target_swaps': {'min': 2, 'max': 6},
                    },
                    qualityWarning: null,
                    deckAnalysis: const {
                      'average_cmc': 3.8,
                      'mana_curve_assessment': 'pesada no turno três',
                    },
                    postAnalysis: const {
                      'average_cmc': 3.4,
                      'mana_curve_assessment': 'mais fluida',
                      'improvements': [
                        'Ramp antecipado',
                        'Proteção mais eficiente',
                      ],
                    },
                    warnings: const <String, dynamic>{},
                    metaReferenceContext: const {
                      'meta_scope': {'label': 'Commander Bracket 3'},
                      'priority_source': 'edhrec',
                      'selection_reason': 'commander_and_archetype_match',
                      'references': [
                        {
                          'shell_label': 'Lorehold historic shell',
                          'source': 'EDHREC',
                          'meta_scope': 'Commander',
                          'strategy_archetype': 'Historic big spells',
                          'selection_rank': 1,
                        },
                        {
                          'shell_label': 'Boros artifact value',
                          'source': 'Decks públicos agregados',
                          'meta_scope': 'Bracket 3',
                          'selection_rank': 2,
                        },
                      ],
                      'suggested_cards_influenced': [
                        {'name': 'Arcane Signet', 'reference_count': 2},
                      ],
                    },
                    optimizationContract: const {
                      'user_decision': {'paired_selection_required': true},
                      'deckbuilder_validation': {'status': 'passed'},
                    },
                    battleValidation: const {
                      'status': 'pending_after_apply',
                      'message':
                          'Rode Battle ou replay depois de aplicar para validar desempenho real.',
                    },
                    bracketPolicy: const {
                      'bracket': 3,
                      'label': 'Upgraded',
                      'hard_compliant': true,
                      'game_changer_count': 1,
                      'game_changer_cap': 3,
                    },
                    displayRemovals: removals,
                    displayAdditions: additions,
                    loadCard: (cardId) async {
                      final item = [...removals, ...additions].firstWhere(
                        (candidate) => candidate['card_id'] == cardId,
                      );
                      return _cardForChange(item);
                    },
                  ),
                  child: const Text('Abrir proposta'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir proposta'));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('optimize-preview-dialog')),
      );

      final sourceEvidence = find.text('Referências meta usadas');
      await _reveal(tester, sourceEvidence);
      await _capture(binding, tester, 'deck_workshop_02_sources');

      final firstPair = find.byKey(const Key('optimize-paired-swap-0'));
      await _reveal(tester, firstPair);
      expect(find.textContaining('HIGH 93%'), findsOneWidget);
      await _capture(binding, tester, 'deck_workshop_03_paired_swaps');

      final firstPairCheckbox = find.byKey(
        const Key('optimize-paired-swap-checkbox-0'),
      );
      await tester.tap(firstPairCheckbox);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('optimize-preview-partial-recompute-message')),
      );
      await _reveal(
        tester,
        find.byKey(const Key('optimize-preview-partial-recompute-message')),
      );
      await _capture(binding, tester, 'deck_workshop_04_partial_selection');

      final cardReaderButton = find.byKey(
        const Key('optimize-suggestion-add-0-preview-button'),
      );
      await _reveal(tester, cardReaderButton);
      await tester.tap(cardReaderButton);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('optimize-suggestion-add-0-card-preview-panel')),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await _capture(binding, tester, 'deck_workshop_05_card_reader');
      final cardReaderBarrier = find.byKey(
        const Key('optimize-suggestion-add-0-card-preview-barrier'),
      );
      tester.widget<GestureDetector>(cardReaderBarrier).onTap!();
      await tester.pump(const Duration(milliseconds: 250));
      final optimizePreview = find.byKey(const Key('optimize-preview-dialog'));
      final cancelOptimization = find.descendant(
        of: optimizePreview,
        matching: find.widgetWithText(TextButton, 'Cancelar'),
      );
      tester.widget<TextButton>(cancelOptimization).onPressed!();
      await pumpUntilAbsent(tester, optimizePreview);

      await tester.pumpWidget(_workshopApp(canRollback: true));
      await tester.pump(const Duration(milliseconds: 400));
      final undo = find.byKey(const Key('deck-workshop-undo-event-runtime-1'));
      await _reveal(tester, undo);
      expect(find.text('Mind Stone'), findsWidgets);
      expect(find.text('Arcane Signet'), findsWidgets);
      await _capture(binding, tester, 'deck_workshop_06_history_undo');

      await tester.pumpWidget(
        _workshopApp(
          canRollback: false,
          errorMessage:
              'A restauração foi recusada com segurança porque o deck recebeu edições mais novas.',
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      final rollbackReason = find.byKey(
        const Key('deck-workshop-rollback-reason-event-runtime-1'),
      );
      await tester.scrollUntilVisible(
        rollbackReason,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.textContaining('protege as edições mais novas'),
        findsOneWidget,
      );
      await _capture(binding, tester, 'deck_workshop_07_conflict');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: AppTheme.backgroundAbyss,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: SampleHandWidget(
                deck: _workshopDeck(),
                compact: _visualWidth < 600,
                randomSeed: 19,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.tap(find.byKey(const Key('sample-hand-draw')));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('sample-hand-carousel-hint')),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.textContaining('de 7 · deslize'), findsOneWidget);
      await _capture(
        binding,
        tester,
        'deck_workshop_08_sample_hand_continuity',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
