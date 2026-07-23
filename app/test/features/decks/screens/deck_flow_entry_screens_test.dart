import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/decks/screens/deck_import_screen.dart';
import 'package:manaloom/features/decks/services/deck_entry_draft_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ui/support/manaloom_ui_audit_harness.dart';

class _FakeApiClient extends ApiClient {
  final getCalls = <String>[];
  final postCalls = <String>[];
  final deleteCalls = <String>[];
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    if (endpoint == '/ai/commander-learning') {
      return ApiResponse(200, {
        'available': true,
        'count': 1,
        'commanders': const [
          {
            'commander': 'Lorehold, the Historian',
            'source_ref': 'learned_deck:82',
            'score': 136.5,
            'legal_status': 'commander_legal',
          },
        ],
      });
    }
    if (endpoint.startsWith('/ai/commander-learning?commander=')) {
      return ApiResponse(200, {
        'available': true,
        'source': 'pg_commander_learned_decks',
        'promoted_deck': const {
          'commander': 'Lorehold, the Historian',
          'source_system': 'pg_commander_learned_decks',
          'source_ref': 'learned_deck:82',
          'score': 136.5,
          'legal_status': 'commander_legal',
        },
        'recommended_deck': const {
          'source_system': 'pg_commander_learned_decks',
          'source_ref': 'learned_deck:82',
          'deck_name': 'Lorehold Learned',
          'archetype': 'spellslinger',
          'bracket': 3,
          'score': 136.5,
          'source_confidence': 'high',
          'commander': {'name': 'Lorehold, the Historian'},
          'cards': [
            {'name': 'Arcane Signet', 'quantity': 1},
          ],
          'validation': {'is_valid': true, 'errors': <String>[]},
          'legality': {
            'is_valid': true,
            'banned_cards': <String>[],
            'unknown_legality_cards': <String>[],
          },
        },
      });
    }
    if (endpoint == '/ai/generate/jobs/job-resume') {
      return ApiResponse(200, {
        'job_id': 'job-resume',
        'status': 'processing',
        'stage': 'generation',
        'stage_number': 2,
        'total_stages': 4,
      });
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    deleteCalls.add(endpoint);
    if (endpoint == '/ai/generate/jobs/job-resume') {
      return ApiResponse(200, {'job_id': 'job-resume', 'status': 'cancelled'});
    }
    throw UnimplementedError('No DELETE handler for $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(body);
    if (endpoint == '/cards/resolve/batch') {
      final names = (body['names'] as List?)?.cast<String>() ?? [];
      final data = names
          .map(
            (name) => {
              'input_name': name,
              'card_id': 'resolved-${name.hashCode}',
            },
          )
          .toList();
      return ApiResponse(200, {
        'data': data,
        'unresolved': <String>[],
        'ambiguous': <String>[],
      });
    }
    if (endpoint == '/decks') {
      return ApiResponse(201, {
        'id': 'deck-saved-1',
        'name': body['name'],
        'format': body['format'],
      });
    }
    if (endpoint == '/import') {
      return ApiResponse(200, {
        'deck': {'id': 'deck-imported-1'},
        'cards_imported': 2,
        'not_found_lines': <String>[],
        'warnings': <String>[],
      });
    }
    throw UnimplementedError('No POST handler for $endpoint');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('generated deck warnings panel ignores empty warning payloads', () {
    expect(
      hasMeaningfulGeneratedDeckWarnings(
        isMock: false,
        warnings: const {'invalid_cards': <String>[]},
      ),
      isFalse,
    );
    expect(
      hasMeaningfulGeneratedDeckWarnings(
        isMock: false,
        warnings: const {
          'messages': <String>['Carta substituída durante a validação.'],
        },
      ),
      isTrue,
    );
    expect(
      hasMeaningfulGeneratedDeckWarnings(
        isMock: true,
        warnings: const <String, dynamic>{},
      ),
      isTrue,
    );
  });

  test('generated deck validation errors sanitize technical payloads', () {
    final errors = sanitizeGeneratedDeckValidationErrors({
      'errors': [
        'Commander obrigatório.',
        'PostgreSqlException: relation secret_table at /srv/app.dart:42',
      ],
    });

    expect(errors.first, 'Commander obrigatório.');
    expect(
      errors.last,
      'A lista gerada não passou na validação. Revise as cartas e tente novamente.',
    );
    expect(errors.join(' '), isNot(contains('secret_table')));
    expect(errors.join(' '), isNot(contains('/srv/')));
  });

  Widget wrapSimple(
    Widget child, {
    DeckProvider? deckProvider,
    double textScale = 1,
  }) {
    final app = MaterialApp(
      theme: AppTheme.darkTheme.copyWith(
        splashFactory: InkRipple.splashFactory,
      ),
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: appChild!,
      ),
      home: child,
    );
    if (deckProvider == null) return app;
    return ChangeNotifierProvider<DeckProvider>.value(
      value: deckProvider,
      child: app,
    );
  }

  Widget wrapWithRouter(DeckProvider deckProvider) {
    return MaterialApp.router(
      theme: AppTheme.darkTheme.copyWith(
        splashFactory: InkRipple.splashFactory,
      ),
      routerConfig: GoRouter(
        initialLocation: '/generate',
        routes: [
          GoRoute(
            path: '/generate',
            builder: (_, __) => ChangeNotifierProvider<DeckProvider>.value(
              value: deckProvider,
              child: const DeckGenerateScreen(),
            ),
          ),
          GoRoute(path: '/decks', builder: (_, __) => const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget wrapImportWithRouter(DeckProvider deckProvider, String ownerId) {
    return MaterialApp.router(
      theme: AppTheme.darkTheme.copyWith(
        splashFactory: InkRipple.splashFactory,
      ),
      routerConfig: GoRouter(
        initialLocation: '/import',
        routes: [
          GoRoute(
            path: '/import',
            builder: (_, __) => ChangeNotifierProvider<DeckProvider>.value(
              value: deckProvider,
              child: DeckImportScreen(draftOwnerId: ownerId),
            ),
          ),
          GoRoute(
            path: '/decks/:id',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(path: '/decks', builder: (_, __) => const SizedBox.shrink()),
        ],
      ),
    );
  }

  testWidgets('DeckGenerateScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapSimple(const DeckGenerateScreen(initialFormat: 'modern')),
    );

    expect(find.text('Modern'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });

  testWidgets('DeckGenerateScreen mantém CTA e conteúdo fluidos em 390px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrapSimple(const DeckGenerateScreen()));
    await tester.pump();

    expect(find.byKey(const Key('deck-generate-desktop-panes')), findsNothing);
    expect(tester.takeException(), isNull);

    final frameSize = tester.getSize(
      find.byKey(const Key('deck-generate-content-frame')),
    );
    final ctaSize = tester.getSize(
      find.byKey(const Key('deck-generate-submit-cta-frame')),
    );
    expect(frameSize.width, closeTo(358, 0.1));
    expect(ctaSize.width, closeTo(frameSize.width, 0.1));
  });

  testWidgets('DeckGenerateScreen usa dois panes limitados em 1280px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrapSimple(const DeckGenerateScreen()));
    await tester.pump();

    expect(
      find.byKey(const Key('deck-generate-desktop-panes')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final frameSize = tester.getSize(
      find.byKey(const Key('deck-generate-content-frame')),
    );
    final formSize = tester.getSize(
      find.byKey(const Key('deck-generate-form-pane')),
    );
    final ctaSize = tester.getSize(
      find.byKey(const Key('deck-generate-submit-cta-frame')),
    );
    expect(frameSize.width, lessThanOrEqualTo(1120));
    expect(formSize.width, closeTo(460, 0.1));
    expect(ctaSize.width, lessThanOrEqualTo(320));
  });

  testWidgets(
    'DeckGenerateScreen keeps the primary action reachable with keyboard and 200% text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        wrapSimple(const DeckGenerateScreen(), textScale: 2),
      );
      final prompt = find.byKey(const Key('deck-generate-prompt-field'));
      await tester.ensureVisible(prompt);
      await tester.pumpAndSettle();
      await tester.tap(prompt);
      await tester.showKeyboard(prompt);
      expect(tester.testTextInput.isVisible, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();

      final submit = find.byKey(const Key('deck-generate-submit-button'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();

      final rect = tester.getRect(submit);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
      expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
      expect(rect.bottom, lessThanOrEqualTo(844 - 320));
      await expectManaLoomBaselineAccessibility(tester);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DeckGenerateScreen mostra atalho de deck aprendido em Commander',
    (tester) async {
      final apiClient = _FakeApiClient();
      await tester.pumpWidget(
        wrapSimple(
          const DeckGenerateScreen(),
          deckProvider: DeckProvider(apiClient: apiClient),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('deck-generate-learned-deck-button')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('deck-generate-commander-field')),
        'Lorehold, the Historian',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('deck-generate-learned-deck-button')),
        findsOneWidget,
      );
      expect(find.text('Usar deck aprendido do comandante'), findsOneWidget);
      expect(find.textContaining('curado pelo Hermes'), findsOneWidget);
      expect(find.textContaining('learned_deck:82'), findsNothing);

      final learnedDeckButton = find.byKey(
        const Key('deck-generate-learned-deck-button'),
      );
      await tester.ensureVisible(learnedDeckButton);
      await tester.tap(learnedDeckButton);
      await tester.pumpAndSettle();

      expect(
        apiClient.getCalls.any(
          (call) => call.startsWith('/ai/commander-learning?commander='),
        ),
        isTrue,
      );
      expect(find.text('Deck aprendido Hermes'), findsOneWidget);
      expect(
        find.textContaining('Origem: Deck aprendido Hermes'),
        findsOneWidget,
      );
      expect(find.textContaining('learned_deck:82'), findsNothing);
      expect(find.text('Score: 136.5'), findsOneWidget);
      expect(find.text('Legalidade: commander_legal'), findsOneWidget);
      expect(find.text('Confiança: high'), findsOneWidget);
    },
  );

  testWidgets('DeckImportScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapSimple(const DeckImportScreen(initialFormat: 'pauper')),
    );

    expect(find.text('Pauper'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });

  testWidgets('DeckGenerateScreen restores an owner-scoped unsaved form', (
    tester,
  ) async {
    const owner = 'draft-owner-generate';
    await tester.pumpWidget(
      wrapSimple(const DeckGenerateScreen(draftOwnerId: owner)),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('deck-generate-commander-field')),
      'Lorehold, the Historian',
    );
    await tester.enterText(
      find.byKey(const Key('deck-generate-prompt-field')),
      'Mágicas históricas, artefatos e ações cedo.',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      wrapSimple(const DeckGenerateScreen(draftOwnerId: owner)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final commander = tester.widget<TextField>(
      find.byKey(const Key('deck-generate-commander-field')),
    );
    final prompt = tester.widget<TextField>(
      find.byKey(const Key('deck-generate-prompt-field')),
    );
    expect(commander.controller?.text, 'Lorehold, the Historian');
    expect(
      prompt.controller?.text,
      'Mágicas históricas, artefatos e ações cedo.',
    );
  });

  testWidgets('DeckGenerateScreen restores the saved format selection', (
    tester,
  ) async {
    const owner = 'draft-owner-generate-format';
    await DeckEntryDraftStore().saveGenerate(
      owner,
      format: 'Modern',
      commander: '',
      prompt: 'Modern midrange',
      deckName: '',
    );

    await tester.pumpWidget(
      wrapSimple(const DeckGenerateScreen(draftOwnerId: owner)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('deck-generate-format-field')),
    );
    expect(dropdown.initialValue, 'Modern');
    expect(
      find.byKey(const Key('deck-generate-commander-field')),
      findsNothing,
    );
  });

  testWidgets('DeckGenerateScreen resumes and can cancel a persisted job', (
    tester,
  ) async {
    const owner = 'draft-owner-generate-job';
    await DeckEntryDraftStore().saveGenerate(
      owner,
      format: 'Commander',
      commander: 'Lorehold, the Historian',
      prompt: 'Mágicas históricas e artefatos',
      deckName: 'Lorehold em andamento',
      activeJobId: 'job-resume',
      requestKey: 'generate:request-resume',
    );
    final apiClient = _FakeApiClient();

    await tester.pumpWidget(
      wrapSimple(
        const DeckGenerateScreen(draftOwnerId: owner),
        deckProvider: DeckProvider(apiClient: apiClient),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Retomando geração em andamento...'), findsOneWidget);
    expect(find.text('Cancelar geração'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancelar geração'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancelar geração'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(apiClient.deleteCalls, ['/ai/generate/jobs/job-resume']);
    expect(find.text('Geração cancelada com segurança.'), findsOneWidget);
    final restored = await DeckEntryDraftStore().loadGenerate(owner);
    expect(restored?.containsKey('active_job_id'), isFalse);
    expect(restored?.containsKey('request_key'), isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'DeckImportScreen restores metadata and card list after rebuild',
    (tester) async {
      const owner = 'draft-owner-import';
      await tester.pumpWidget(
        wrapSimple(const DeckImportScreen(draftOwnerId: owner)),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('deck-import-screen-name-field')),
        'Lorehold Import Draft',
      );
      await tester.enterText(
        find.byKey(const Key('deck-import-screen-list-field')),
        '1 Sol Ring\n1 Arcane Signet',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(
        wrapSimple(const DeckImportScreen(draftOwnerId: owner)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final name = tester.widget<TextField>(
        find.byKey(const Key('deck-import-screen-name-field')),
      );
      final list = tester.widget<TextField>(
        find.byKey(const Key('deck-import-screen-list-field')),
      );
      expect(name.controller?.text, 'Lorehold Import Draft');
      expect(list.controller?.text, '1 Sol Ring\n1 Arcane Signet');
      expect(find.text('2 cartas detectadas'), findsOneWidget);
    },
  );

  testWidgets('DeckImportScreen clears its draft after a successful import', (
    tester,
  ) async {
    const owner = 'draft-owner-import-success';
    final store = DeckEntryDraftStore();
    await store.saveImport(
      owner,
      format: 'commander',
      name: 'Ready Import',
      description: '',
      commander: 'Lorehold, the Historian',
      cardList: '1 Sol Ring\n1 Arcane Signet',
    );
    final apiClient = _FakeApiClient();

    await tester.pumpWidget(
      wrapImportWithRouter(DeckProvider(apiClient: apiClient), owner),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final submit = find.byKey(const Key('deck-import-screen-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(apiClient.postCalls, contains('/import'));
    expect(await store.loadImport(owner), isNull);
  });

  testWidgets(
    'DeckGenerateScreen save learned deck POSTs 99 main + 1 commander',
    (tester) async {
      final apiClient = _FakeApiClient();
      await tester.pumpWidget(
        wrapWithRouter(DeckProvider(apiClient: apiClient)),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('deck-generate-commander-field')),
        'Lorehold, the Historian',
      );
      await tester.pump();

      final learnedDeckButton = find.byKey(
        const Key('deck-generate-learned-deck-button'),
      );
      await tester.ensureVisible(learnedDeckButton);
      await tester.tap(learnedDeckButton);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('deck-generate-save-button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final resolveCall = apiClient.postCalls.any(
        (call) => call == '/cards/resolve/batch',
      );
      expect(resolveCall, isTrue);

      final deckCall = apiClient.postCalls.any((call) => call == '/decks');
      expect(deckCall, isTrue);
      expect(await DeckEntryDraftStore().loadGenerate('local'), isNull);

      for (final body in apiClient.postBodies) {
        if (body.containsKey('cards')) {
          final cards = body['cards'] as List;
          final commanders = cards.where(
            (c) => c is Map && c['is_commander'] == true,
          );
          final main = cards.where(
            (c) => c is Map && c['is_commander'] != true,
          );
          expect(commanders.length, 1);
          expect(commanders.first['card_id'], isNotNull);
          expect(commanders.first['card_id'], isNotEmpty);
          expect(main.length, 1);
          expect(main.first['card_id'], isNotNull);
          expect(main.first['card_id'], isNotEmpty);
          expect(body['format'], 'commander');
          expect(body['archetype'], 'spellslinger');
          expect(body['bracket'], 3);
        }
      }
    },
  );
}
