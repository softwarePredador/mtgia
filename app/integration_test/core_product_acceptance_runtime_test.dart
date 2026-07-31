import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_list_screen.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_dialogs.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

import 'visual_capture_helpers.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
  defaultValue: true,
);
const _sourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _proofProfile = String.fromEnvironment(
  'MANALOOM_UI_PROOF_PROFILE',
  defaultValue: 'android_core_product',
);
const _proofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
  defaultValue: 'physical_android',
);
const _proofRuntimeTarget = String.fromEnvironment(
  'MANALOOM_UI_PROOF_TARGET',
  defaultValue: 'android_physical',
);
const _proofCheckpoints = <String>[
  'core_01_collection_editor',
  'core_02_collection_inline_validation',
  'core_03_collection_persistence_failure',
  'core_04_collection_retry_success',
  'core_05_deck_inline_validation',
  'core_06_deck_commander_filtered',
  'core_07_deck_persistence_failure',
  'core_08_deck_retry_success',
  'core_09_optimization_safe_mana_preview',
  'core_10_optimization_partial_selection',
  'core_11_optimization_applied',
  'core_12_optimization_undo',
];

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (!_captureRuntimeProof) return;
  // The Samsung keyboard can momentarily place its own settings surface above
  // the test app while PixelCopy is taking a screenshot. Close the IME before
  // every checkpoint so the capture always targets a backed Flutter surface.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await captureVisualProof(binding, tester, name);
}

class _NoopApiClient extends ApiClient {}

class _FlakyCreateDeckProvider extends DeckProvider {
  _FlakyCreateDeckProvider() : super(apiClient: _NoopApiClient());

  int createCalls = 0;
  String? createdName;
  String? createdFormat;
  String? createdDescription;
  List<Map<String, dynamic>>? createdCards;
  bool? createdIsPublic;
  String? _errorMessage;
  final List<Deck> _createdDecks = <Deck>[];

  @override
  List<Deck> get decks => List<Deck>.unmodifiable(_createdDecks);

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> fetchDecks({bool silent = false}) async {}

  @override
  Future<bool> createDeck({
    required String name,
    required String format,
    String? description,
    String? archetype,
    int? bracket,
    List<Map<String, dynamic>>? cards,
    bool isPublic = false,
  }) async {
    createCalls += 1;
    createdName = name;
    createdFormat = format;
    createdDescription = description;
    createdCards = cards;
    createdIsPublic = isPublic;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (createCalls == 1) {
      _errorMessage =
          'Não foi possível criar este deck agora. Seus dados foram preservados.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    _createdDecks
      ..clear()
      ..add(
        Deck(
          id: 'runtime-lorehold-deck',
          name: name,
          format: format,
          description: description,
          isPublic: isPublic,
          createdAt: DateTime.now(),
          cardCount:
              cards?.fold<int>(
                0,
                (total, card) =>
                    total + ((card['quantity'] as num?)?.toInt() ?? 0),
              ) ??
              0,
          colorIdentity: const <String>['R', 'W'],
          colorIdentityKnown: true,
          validationState: Deck.validationStateDraft,
          reviewReasons: const <String>['deck_incomplete'],
        ),
      );
    notifyListeners();
    return true;
  }
}

class _CommanderCardProvider extends CardProvider {
  _CommanderCardProvider(this._cards) : super(apiClient: _NoopApiClient());

  final List<DeckCardItem> _cards;
  List<DeckCardItem> _results = const <DeckCardItem>[];
  bool _loading = false;
  String? lastFormat;

  @override
  List<DeckCardItem> get searchResults => List.unmodifiable(_results);

  @override
  bool get isLoading => _loading;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => false;

  @override
  Future<void> searchCommanderCandidates(
    String query, {
    required String format,
  }) async {
    _loading = true;
    lastFormat = format;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final normalized = query.trim().toLowerCase();
    _results = _cards
        .where((card) => card.name.toLowerCase().contains(normalized))
        .toList();
    _loading = false;
    notifyListeners();
  }

  @override
  void clearSearch() {
    _results = const <DeckCardItem>[];
    _loading = false;
    notifyListeners();
  }
}

class _CollectionCardProvider extends CardProvider {
  _CollectionCardProvider() : super(apiClient: _NoopApiClient());

  @override
  Future<List<Map<String, dynamic>>> fetchPrintingsByName(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'runtime-sol-ring-2xm',
        'set_code': '2xm',
        'set_name': 'Double Masters',
        'set_release_date': '2020-08-07',
        'collector_number': '282',
        'rarity': 'uncommon',
        'foil': true,
        'price': 1.25,
        'image_url': null,
      },
      <String, dynamic>{
        'id': 'runtime-sol-ring-sld',
        'set_code': 'sld',
        'set_name': 'Secret Lair Drop',
        'set_release_date': '2024-02-23',
        'collector_number': '1499',
        'rarity': 'rare',
        'foil': false,
        'price': 12.50,
        'image_url': null,
      },
    ];
  }
}

class _RuntimeCardItem extends DeckCardItem {
  _RuntimeCardItem({
    required super.id,
    required super.name,
    required super.manaCost,
    required super.typeLine,
    required super.oracleText,
    required super.colors,
    required super.colorIdentity,
    required super.setCode,
    super.setName,
    super.setReleaseDate,
    super.collectorNumber,
    super.foil,
    required super.rarity,
    required super.quantity,
    required super.isCommander,
  });

  @override
  String? get effectiveImageUrl => null;

  @override
  String? get fallbackImageUrl => null;
}

final _lorehold = _RuntimeCardItem(
  id: 'runtime-lorehold',
  name: 'Lorehold, the Historian',
  manaCost: '{3}{R}{W}',
  typeLine: 'Legendary Creature — Elder Dragon',
  oracleText: 'Flying, haste. Can be your commander.',
  colors: const <String>['R', 'W'],
  colorIdentity: const <String>['R', 'W'],
  setCode: 'psos',
  setName: 'Secrets of Strixhaven Promos',
  setReleaseDate: '2026-04-24',
  collectorNumber: '201p',
  foil: false,
  rarity: 'mythic',
  quantity: 1,
  isCommander: false,
);

final _solRing = _RuntimeCardItem(
  id: 'runtime-sol-ring',
  name: 'Sol Ring',
  manaCost: '{1}',
  typeLine: 'Artifact',
  oracleText: '{T}: Add {C}{C}.',
  colors: const <String>[],
  colorIdentity: const <String>[],
  setCode: 'cmm',
  rarity: 'uncommon',
  quantity: 1,
  isCommander: false,
);

class _BinderRuntimeHarness extends StatefulWidget {
  const _BinderRuntimeHarness();

  @override
  State<_BinderRuntimeHarness> createState() => _BinderRuntimeHarnessState();
}

class _BinderRuntimeHarnessState extends State<_BinderRuntimeHarness> {
  int persistenceCalls = 0;
  Map<String, dynamic>? savedPayload;

  Future<void> _openEditor() {
    return BinderItemEditor.show(
      context,
      cardId: 'runtime-sol-ring-sld',
      cardName: 'Sol Ring',
      initialListType: 'have',
      onSave: (payload) async {
        persistenceCalls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (persistenceCalls == 1) return false;
        if (mounted) {
          setState(() => savedPayload = Map<String, dynamic>.from(payload));
        }
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawPrice = savedPayload?['price'];
    final formattedPrice = rawPrice is num
        ? rawPrice.toStringAsFixed(2).replaceAll('.', ',')
        : rawPrice?.toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Coleção · jornada de cadastro')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              savedPayload == null
                  ? 'Nenhuma alteração persistida'
                  : 'Carta salva · R\$ $formattedPrice',
              key: const Key('binder-runtime-status'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('binder-runtime-open'),
              onPressed: _openEditor,
              child: const Text('Adicionar Sol Ring'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptimizationRuntimeHarness extends StatefulWidget {
  const _OptimizationRuntimeHarness();

  @override
  State<_OptimizationRuntimeHarness> createState() =>
      _OptimizationRuntimeHarnessState();
}

class _OptimizationRuntimeHarnessState
    extends State<_OptimizationRuntimeHarness> {
  String status = 'Nenhuma otimização aplicada';

  Future<void> _openPreview() async {
    final selection = await showOptimizationPreviewDialog(
      context,
      mode: 'optimize',
      archetype: 'midrange',
      keepTheme: true,
      preservedTheme: 'Miracle Big Spells',
      reasoning:
          'Reforça a base de mana antes de sugerir aceleração e interação.',
      intensity: OptimizeIntensity.focused,
      optimizeIntensity: const <String, dynamic>{
        'target_swaps': {'min': 6, 'max': 10},
      },
      qualityWarning: null,
      deckAnalysis: const <String, dynamic>{
        'total_cards': 72,
        'land_count': 9,
        'average_cmc': 5.0,
      },
      postAnalysis: const <String, dynamic>{
        'total_cards': 100,
        'land_count': 36,
        'average_cmc': 2.11,
      },
      warnings: const <String, dynamic>{
        'mana_foundation': 'Base de mana corrigida para o piso seguro.',
      },
      metaReferenceContext: const <String, dynamic>{},
      optimizationContract: const <String, dynamic>{
        'deckbuilder_validation': {
          'label': 'Preview seguro',
          'message': 'As mudanças passaram pelas regras do formato.',
        },
        'mana_foundation': {
          'policy': 'automatic_apply_floor',
          'minimum_land_count': 33,
          'land_count': 36,
          'satisfied': true,
        },
      },
      battleValidation: const <String, dynamic>{
        'label': 'Próximo passo',
        'message': 'Valide a consistência em testes antes da próxima partida.',
      },
      displayRemovals: const <Map<String, dynamic>>[
        {'name': 'Cancel', 'quantity': 1},
        {'name': 'Worn Powerstone', 'quantity': 1},
      ],
      displayAdditions: const <Map<String, dynamic>>[
        {'name': 'Plains', 'quantity': 27},
        {'name': 'Arcane Signet', 'quantity': 1},
      ],
    );
    if (!mounted || selection == null) return;
    setState(() {
      status = '${selection.selectedCount} mudanças aplicadas';
    });
    showOptimizeSuccessSnackBar(
      context,
      onUndo: () {
        if (mounted) setState(() => status = 'Otimização desfeita');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Otimização · revisão segura')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status, key: const Key('optimization-runtime-status')),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('optimization-runtime-open'),
              onPressed: _openPreview,
              child: const Text('Revisar otimização'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    if (!_captureRuntimeProof) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(
      _sourceDigest,
      matches(RegExp(r'^[0-9a-f]{64}$')),
      reason:
          'A prova visual deve ser vinculada ao digest atual por '
          '--dart-define=MANALOOM_UI_SOURCE_DIGEST=<sha256>.',
    );
    // Consumido por tool/ui_runtime_evidence.dart. Não contém credenciais,
    // endpoints, dados pessoais nem payloads reais do usuário.
    // ignore: avoid_print
    print(
      'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'core_product_runtime_ui_acceptance', 'source_digest': _sourceDigest, 'profile': _proofProfile, 'runtime': 'flutter_integration_test', 'target': _proofRuntimeTarget, 'device_contract': _proofDeviceContract, 'required_checkpoints': _proofCheckpoints})}',
    );
  });

  tearDownAll(() async {
    if (!_captureRuntimeProof) return;
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  });

  setUp(() {
    if (!_captureRuntimeProof) return;
    resetVisualCaptureSurface();
    // IntegrationTest normally forwards text input to the physical IME. This
    // proof validates the Flutter journey, while the real-keyboard matrix is a
    // separate release check, so keep input deterministic and in-process.
    if (!binding.testTextInput.isRegistered) {
      binding.testTextInput.register();
    }
  });

  tearDown(() async {
    if (!_captureRuntimeProof) return;
    await restoreVisualCaptureSurface();
    if (binding.testTextInput.isRegistered) {
      binding.testTextInput.unregister();
    }
  });

  testWidgets(
    'card collection: selects printing, validates and retries registration',
    (tester) async {
      binding.deviceEventDispatcher = null;
      await tester.pumpWidget(
        ChangeNotifierProvider<CardProvider>(
          create: (_) => _CollectionCardProvider(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const _BinderRuntimeHarness(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('binder-runtime-open')));
      await tester.pumpAndSettle();
      await _capture(binding, tester, 'core_01_collection_editor');

      final sale = find.byKey(const Key('binder-editor-for-sale-switch'));
      await tester.ensureVisible(sale);
      await tester.tap(sale);
      await tester.pumpAndSettle();

      final save = find.byKey(const Key('binder-editor-save-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text('Informe um preço válido maior que zero.'),
        findsOneWidget,
      );
      await _capture(binding, tester, 'core_02_collection_inline_validation');

      await tester.enterText(
        find.byKey(const Key('binder-editor-price-field')),
        '12,50',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text(
          'Não foi possível salvar esta carta. Revise os dados e tente novamente.',
        ),
        findsOneWidget,
      );
      expect(find.text('12,50'), findsOneWidget);
      await _capture(binding, tester, 'core_03_collection_persistence_failure');

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      for (var attempt = 0; attempt < 30; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(BinderItemEditor).evaluate().isEmpty) break;
      }
      expect(find.byType(BinderItemEditor), findsNothing);
      expect(find.text('Carta salva · R\$ 12,50'), findsOneWidget);
      final harness = tester.state<_BinderRuntimeHarnessState>(
        find.byType(_BinderRuntimeHarness),
      );
      expect(harness.savedPayload?['card_id'], 'runtime-sol-ring-sld');
      await _capture(binding, tester, 'core_04_collection_retry_success');
    },
  );

  testWidgets(
    'deck creation: validates name, filters commander and retries atomically',
    (tester) async {
      binding.deviceEventDispatcher = null;
      final decks = _FlakyCreateDeckProvider();
      final cards = _CommanderCardProvider(<DeckCardItem>[_solRing, _lorehold]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeckProvider>.value(value: decks),
            ChangeNotifierProvider<CardProvider>.value(value: cards),
            ChangeNotifierProvider<MessageProvider>(
              create: (_) => MessageProvider(apiClient: _NoopApiClient()),
            ),
            ChangeNotifierProvider<NotificationProvider>(
              create: (_) => NotificationProvider(apiClient: _NoopApiClient()),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const DeckListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deck-list-empty-create-button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('deck-create-submit-button')),
      );
      await tester.tap(find.byKey(const Key('deck-create-submit-button')));
      await tester.pump();
      expect(find.byKey(const Key('deck-create-name-error')), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await _capture(binding, tester, 'core_05_deck_inline_validation');

      await tester.enterText(
        find.byKey(const Key('deck-create-name-field')),
        'Lorehold Lessons',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final commanderSelect = find.byKey(
        const Key('deck-create-commander-select'),
      );
      await tester.ensureVisible(commanderSelect);
      await tester.pumpAndSettle();
      await tester.tap(commanderSelect);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('deck-create-commander-search-field')),
        'Lor',
      );
      await tester.pump(const Duration(milliseconds: 400));
      final loreholdResult = find.byKey(
        const Key('deck-create-commander-result-runtime-lorehold'),
      );
      // On a physical device the provider's delayed result can complete after
      // pumpAndSettle observes a quiet frame. Poll the visible outcome instead
      // of assigning product credit to a timing assumption.
      for (var attempt = 0; attempt < 30; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (loreholdResult.evaluate().isNotEmpty) break;
      }
      expect(cards.lastFormat, 'commander');
      expect(loreholdResult, findsOneWidget);
      expect(
        find.byKey(const Key('deck-create-commander-result-runtime-sol-ring')),
        findsNothing,
      );
      await _capture(binding, tester, 'core_06_deck_commander_filtered');

      await tester.tap(loreholdResult);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('deck-create-description-field')),
        'Recursão de artefatos e valor incremental.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final publicSwitch = find.byKey(const Key('deck-create-public-switch'));
      await tester.ensureVisible(publicSwitch);
      await tester.tap(publicSwitch);
      await tester.pump();

      final submit = find.byKey(const Key('deck-create-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deck-create-dialog')), findsOneWidget);
      expect(
        find.text(
          'Não foi possível criar este deck agora. Seus dados foram preservados.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lorehold Lessons'), findsOneWidget);
      expect(find.text('Lorehold, the Historian'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await _capture(binding, tester, 'core_07_deck_persistence_failure');

      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deck-create-dialog')), findsNothing);
      expect(decks.createCalls, 2);
      expect(decks.createdName, 'Lorehold Lessons');
      expect(decks.createdFormat, 'commander');
      expect(
        decks.createdDescription,
        'Recursão de artefatos e valor incremental.',
      );
      expect(decks.createdIsPublic, isTrue);
      expect(decks.createdCards, <Map<String, dynamic>>[
        <String, dynamic>{
          'card_id': 'runtime-lorehold',
          'quantity': 1,
          'is_commander': true,
        },
      ]);
      expect(decks.decks.single.name, 'Lorehold Lessons');
      expect(find.text('Lorehold Lessons'), findsOneWidget);
      expect(find.text('Você ainda não tem decks'), findsNothing);
      expect(find.textContaining('criado'), findsWidgets);
      await _capture(binding, tester, 'core_08_deck_retry_success');
    },
  );

  testWidgets(
    'optimization: restores mana floor, supports partial apply and undo',
    (tester) async {
      binding.deviceEventDispatcher = null;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _OptimizationRuntimeHarness(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('optimization-runtime-open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('optimize-preview-dialog')), findsOneWidget);
      final landLabel = find.text('Terrenos');
      final landFloor = find.text('≥ 33 terrenos');
      final landTransition = find.text('9 → 36');
      expect(landLabel, findsOneWidget);
      expect(landFloor, findsOneWidget);
      expect(landTransition, findsOneWidget);
      await tester.ensureVisible(landLabel);
      await tester.pumpAndSettle();
      await _capture(binding, tester, 'core_09_optimization_safe_mana_preview');

      final previewScroll = find.descendant(
        of: find.byKey(const Key('optimize-preview-dialog')),
        matching: find.byType(SingleChildScrollView),
      );
      expect(previewScroll, findsOneWidget);
      for (
        var attempt = 0;
        attempt < 10 && find.textContaining('Plains').evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(previewScroll, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Plains'), findsOneWidget);
      expect(find.textContaining('27'), findsWidgets);
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(4));
      final firstAddition = find.byKey(const Key('optimize-suggestion-add-0'));
      await tester.ensureVisible(firstAddition);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: firstAddition, matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('optimize-preview-partial-recompute-message')),
        findsOneWidget,
      );
      await _capture(binding, tester, 'core_10_optimization_partial_selection');

      final apply = find.byKey(const Key('optimize-preview-apply-button'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(find.text('2 mudanças aplicadas'), findsOneWidget);
      expect(find.text('Otimização aplicada com sucesso!'), findsOneWidget);
      await _capture(binding, tester, 'core_11_optimization_applied');

      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(find.text('Otimização desfeita'), findsOneWidget);
      await _capture(binding, tester, 'core_12_optimization_undo');
    },
  );
}
