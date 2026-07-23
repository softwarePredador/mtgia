import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

String _editionTitle(Map<String, dynamic> printing) {
  final setCode = (printing['set_code'] ?? '').toString().toUpperCase();
  final collector = (printing['collector_number'] ?? '').toString();
  if (setCode.isEmpty) return collector;
  if (collector.isEmpty) return setCode;
  return '$setCode #$collector';
}

Future<({String name, List<Map<String, dynamic>> printings})>
_findCommanderWithMultiplePrintings(ApiClient api) async {
  const candidateNames = [
    'Lorehold, the Historian',
    'Talrand, Sky Summoner',
    'Krenko, Mob Boss',
    'Lathril, Blade of the Elves',
    'Niv-Mizzet, Parun',
    "Atraxa, Praetors' Voice",
    "Yuriko, the Tiger's Shadow",
    'Kinnan, Bonder Prodigy',
  ];

  for (final name in candidateNames) {
    final response = await api.get(
      '/cards/printings?name=${Uri.encodeQueryComponent(name)}&limit=50&dedupe=false',
    );
    if (response.statusCode != 200) continue;
    final rows =
        ((response.data as Map<String, dynamic>)['data'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
    final uniqueById = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;
      uniqueById.putIfAbsent(id, () => row);
    }
    if (uniqueById.length >= 2) {
      return (name: name, printings: uniqueById.values.toList());
    }
  }

  fail('No commander with at least two unique local printings was found.');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'iPhone 15 runtime: commander edition is visible and stays outside the 99',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiClient.setToken(null);

      final api = ApiClient();
      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      final email = 'iphone15_commander_edition_$unique@example.com';
      const password = 'BetaQa!2026-Deck';
      final username = 'iphone15_commander_edition_$unique';

      final registerResponse = await api.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });
      expect(registerResponse.statusCode, anyOf(201, 200));
      final registerData = registerResponse.data as Map<String, dynamic>;
      final token = registerData['token'] as String;
      final user = registerData['user'] as Map<String, dynamic>;
      ApiClient.setToken(token);
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(user));
      await markRuntimeOnboardingSettled(user['id']?.toString() ?? '');

      final commanderFixture = await _findCommanderWithMultiplePrintings(api);
      final commanderName = commanderFixture.name;
      final printings = commanderFixture.printings;

      final firstPrinting = printings.first;
      final pickerResponse = await api.get(
        '/cards/printings?name=${Uri.encodeQueryComponent(commanderName)}&limit=50&sync=true',
      );
      expect(pickerResponse.statusCode, 200);
      final pickerRows =
          ((pickerResponse.data as Map<String, dynamic>)['data'] as List? ??
                  const [])
              .cast<Map<String, dynamic>>();
      final pickerUniqueById = <String, Map<String, dynamic>>{};
      for (final row in pickerRows) {
        final id = row['id']?.toString();
        if (id == null || id.isEmpty) continue;
        pickerUniqueById.putIfAbsent(id, () => row);
      }
      final pickerPrintings = pickerUniqueById.values.toList();
      expect(pickerPrintings, hasLength(greaterThanOrEqualTo(2)));
      final secondPrinting = pickerPrintings.firstWhere(
        (printing) => printing['id'].toString() != firstPrinting['id'],
      );
      final firstId = firstPrinting['id'].toString();
      final secondId = secondPrinting['id'].toString();
      final firstEditionTitle = _editionTitle(firstPrinting);
      final secondEditionTitle = _editionTitle(secondPrinting);
      expect(firstId, isNot(secondId));

      final deckResponse = await api.post('/decks', {
        'name': 'QA Commander Edition $unique',
        'format': 'commander',
        'description': 'Runtime proof for commander edition metadata.',
      });
      expect(deckResponse.statusCode, anyOf(200, 201));
      final deckId = (deckResponse.data as Map<String, dynamic>)['id']
          .toString();

      final addCommander = await api.post('/decks/$deckId/cards', {
        'card_id': firstId,
        'quantity': 1,
        'is_commander': true,
      });
      expect(addCommander.statusCode, 200);

      // ignore: avoid_print
      print('COMMANDER_EDITION_RUNTIME_COMMANDER $commanderName');
      // ignore: avoid_print
      print('COMMANDER_EDITION_RUNTIME_DECK_ID $deckId');
      // ignore: avoid_print
      print('COMMANDER_EDITION_INITIAL $firstEditionTitle');
      // ignore: avoid_print
      print('COMMANDER_EDITION_TARGET $secondEditionTitle');

      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();
      await pumpUntilFound(tester, find.text('Decks'), attempts: 120);

      final navContext = tester.element(find.text('Decks').first);
      GoRouter.of(navContext).go('/decks/$deckId/search?mode=commander');
      await tester.pump();
      await pumpUntilFound(tester, find.text('Cartas'), attempts: 60);

      await tester.enterText(
        find.byKey(const Key('card-search-field')),
        commanderName,
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text(commanderName), attempts: 80);
      await pumpUntilFound(
        tester,
        find.textContaining(firstPrinting['set_code'].toString().toUpperCase()),
        attempts: 40,
      );
      await captureVisualProof(
        binding,
        tester,
        '01_commander_search_edition_visible',
      );

      GoRouter.of(navContext).go('/decks/$deckId');
      await tester.pump();
      await pumpUntilFound(tester, find.text('Detalhes do Deck'), attempts: 80);
      await pumpUntilFound(tester, find.text(commanderName));
      await captureVisualProof(
        binding,
        tester,
        '02_commander_detail_before_edition_change',
      );

      await tester.tap(find.text('Cartas'));
      await tester.pumpAndSettle();
      final commanderTile = find.byKey(ValueKey('deck-card-$firstId'));
      await pumpUntilFound(tester, commanderTile, attempts: 40);
      await tester.ensureVisible(commanderTile);
      await tester.tap(commanderTile);
      await tester.pump();
      final changeEditionButton = find.byKey(
        ValueKey('deck-card-change-edition-$firstId'),
      );
      await pumpUntilFound(tester, changeEditionButton, attempts: 40);
      await pumpUntilFound(tester, find.textContaining(firstEditionTitle));
      await captureVisualProof(
        binding,
        tester,
        '03_commander_card_dialog_current_edition',
      );

      await tester.tap(changeEditionButton);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(ValueKey('deck-edition-picker-sheet-$firstId')),
        attempts: 40,
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-edition-picker-title')),
      );
      await pumpUntil(
        tester,
        () => find
            .byKey(ValueKey('deck-edition-option-$secondId'))
            .evaluate()
            .isNotEmpty,
        description: 'at least two edition rows',
        attempts: 40,
      );
      await captureVisualProof(
        binding,
        tester,
        '04_commander_edition_picker_target_visible',
      );
      final targetEditionRow = find.byKey(
        ValueKey('deck-edition-option-$secondId'),
      );
      await tester.ensureVisible(targetEditionRow);
      await tester.tap(targetEditionRow);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text('Edição atualizada.'),
        attempts: 80,
        step: const Duration(milliseconds: 500),
      );
      await captureVisualProof(
        binding,
        tester,
        '04_commander_detail_after_edition_change',
      );

      final deckAfterResponse = await api.get('/decks/$deckId');
      expect(deckAfterResponse.statusCode, 200);
      final deckAfter = deckAfterResponse.data as Map<String, dynamic>;
      final commanders = ((deckAfter['commander'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      expect(commanders, hasLength(1));
      expect(commanders.single['id'], secondId);

      final mainBoard = (deckAfter['main_board'] as Map?) ?? const {};
      final mainCards = mainBoard.values
          .whereType<List>()
          .expand((items) => items)
          .whereType<Map>();
      expect(mainCards.any((card) => card['id'] == secondId), isFalse);
      expect(mainCards.any((card) => card['name'] == commanderName), isFalse);

      // ignore: avoid_print
      print('COMMANDER_EDITION_RUNTIME_RESULT PASS');
    },
  );
}
