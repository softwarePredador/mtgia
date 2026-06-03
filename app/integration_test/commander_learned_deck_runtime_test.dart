import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/main.dart' as app;

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const commanderName = 'Lorehold, the Historian';
  const blockedPremiumCards = <String>['Chrome Mox', 'Mox Diamond', 'Mox Opal'];

  Future<void> cleanupDeck(ApiClient api, String? deckId) async {
    if (deckId == null || deckId.isEmpty) return;
    try {
      await api.delete('/decks/$deckId');
    } catch (_) {
      // Best-effort cleanup. The runtime assertions above are the proof gate.
    }
  }

  int quantityOf(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 1;
  }

  Iterable<Map<String, dynamic>> flattenMainBoard(Map<String, dynamic> detail) {
    final mainBoard = (detail['main_board'] as Map?) ?? const {};
    return mainBoard.values
        .whereType<List>()
        .expand((cards) => cards)
        .whereType<Map>()
        .map((card) => card.cast<String, dynamic>());
  }

  testWidgets(
    'localized iPhone runtime: Lorehold learned deck button, preview and saved deck',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final api = ApiClient();
      String? createdDeckId;
      addTearDown(() => cleanupDeck(api, createdDeckId));

      await clearRuntimeAuth();
      await seedAuthenticatedSession(
        api,
        usernamePrefix: 'learned_lorehold_runtime',
      );

      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text('Decks'),
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );

      await tester.tap(find.text('Decks').first);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text('Meus Decks'),
        attempts: 90,
        step: const Duration(milliseconds: 500),
      );

      final generateCta = find.text('Gerar com IA');
      await pumpUntilFound(
        tester,
        generateCta,
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );
      await tester.ensureVisible(generateCta.first);
      await tester.tap(generateCta.first);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text('Gerar Deck'),
        attempts: 90,
        step: const Duration(milliseconds: 500),
      );

      expect(
        find.byKey(const Key('deck-generate-learned-deck-button')),
        findsNothing,
      );
      final generateSubmitButton = find.byKey(
        const Key('deck-generate-submit-button'),
      );
      await tester.scrollUntilVisible(
        generateSubmitButton,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await captureVisualProof(
        binding,
        tester,
        '01_no_commander_no_learned_button',
      );

      await tester.ensureVisible(
        find.byKey(const Key('deck-generate-commander-field')),
      );
      await tester.enterText(
        find.byKey(const Key('deck-generate-commander-field')),
        commanderName,
      );
      await tester.pump();

      final learnedDeckButton = find.byKey(
        const Key('deck-generate-learned-deck-button'),
      );
      await pumpUntilFound(
        tester,
        learnedDeckButton,
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );
      expect(find.text('Usar deck aprendido do comandante'), findsOneWidget);
      expect(find.textContaining('Hermes learned_deck:82'), findsOneWidget);
      expect(find.textContaining('commander_legal'), findsOneWidget);
      await tester.ensureVisible(learnedDeckButton);
      await captureVisualProof(
        binding,
        tester,
        '02_commander_learned_button_visible',
      );

      await tester.tap(learnedDeckButton);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text('Preview antes de salvar'),
        attempts: 180,
        step: const Duration(seconds: 1),
      );

      expect(find.text('Deck aprendido Hermes'), findsOneWidget);
      expect(
        find.textContaining('Origem: HERMES learned_deck:82'),
        findsOneWidget,
      );
      expect(find.textContaining('Score:'), findsOneWidget);
      expect(find.text('Legalidade: commander_legal'), findsOneWidget);
      expect(find.text('Confiança: high'), findsOneWidget);
      expect(find.text('1x $commanderName'), findsOneWidget);
      expect(find.text('Total: 100 cartas'), findsOneWidget);
      expect(find.textContaining('Deck principal (99 cartas'), findsOneWidget);
      for (final cardName in blockedPremiumCards) {
        expect(find.textContaining(cardName), findsNothing);
      }
      await captureVisualProof(binding, tester, '03_hermes_preview');

      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      final deckName = 'Runtime Lorehold Learned $unique';
      await tester.enterText(
        find.byKey(const Key('deck-generate-name-field')),
        deckName,
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('deck-generate-save-button')),
        220,
        scrollable: scrollable,
      );
      await tester.tap(find.byKey(const Key('deck-generate-save-button')));
      await tester.pump();

      await pumpUntilAnyFound(
        tester,
        [find.text('Meus Decks'), find.text('Decks')],
        attempts: 180,
        step: const Duration(seconds: 1),
      );

      final deckListResponse = await api.get('/decks');
      expect(deckListResponse.statusCode, 200);
      final deckRows = (deckListResponse.data as List).cast<Map>();
      final createdDeck = deckRows.firstWhere(
        (deck) => deck['name']?.toString() == deckName,
      );
      createdDeckId = createdDeck['id']?.toString();
      expect(createdDeckId, isNotNull);

      final navContext = tester.element(find.text('Meus Decks').first);
      GoRouter.of(navContext).go('/decks/$createdDeckId');
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Detalhes do Deck'),
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );
      await captureVisualProof(binding, tester, '04_saved_deck_details');

      final detailResponse = await api.get('/decks/$createdDeckId');
      expect(detailResponse.statusCode, 200);
      final detail = (detailResponse.data as Map).cast<String, dynamic>();
      final commanders =
          ((detail['commander'] as List?) ?? const [])
              .whereType<Map>()
              .map((card) => card.cast<String, dynamic>())
              .toList();
      final mainCards = flattenMainBoard(detail).toList();
      final mainQuantity = mainCards.fold<int>(
        0,
        (sum, card) => sum + quantityOf(card['quantity']),
      );
      final commanderQuantity = commanders.fold<int>(
        0,
        (sum, card) => sum + quantityOf(card['quantity']),
      );
      final allPersistedNames = <String>[
        ...commanders.map((card) => card['name']?.toString() ?? ''),
        ...mainCards.map((card) => card['name']?.toString() ?? ''),
      ];

      expect(detail['format']?.toString().toLowerCase(), 'commander');
      expect(commanders, hasLength(1));
      expect(commanders.single['name']?.toString(), commanderName);
      expect(commanders.single['is_commander'], isTrue);
      expect(commanderQuantity, 1);
      expect(mainQuantity, 99);
      expect(mainQuantity + commanderQuantity, 100);
      for (final cardName in blockedPremiumCards) {
        expect(allPersistedNames.contains(cardName), isFalse);
      }

      // ignore: avoid_print
      print(
        'COMMANDER_LEARNED_RUNTIME_SUMMARY '
        '{"deck_id":"$createdDeckId","commander":"$commanderName",'
        '"format":"${detail['format']}","total":${mainQuantity + commanderQuantity},'
        '"main_quantity":$mainQuantity,"commander_count":${commanders.length},'
        '"blocked_premium_cards_present":false}',
      );
    },
  );
}
