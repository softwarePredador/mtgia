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

const _commanderName = 'Lorehold, the Historian';

String _editionTitle(Map<String, dynamic> printing) {
  final setCode = (printing['set_code'] ?? '').toString().toUpperCase();
  final collector = (printing['collector_number'] ?? '').toString();
  if (setCode.isEmpty) return collector;
  if (collector.isEmpty) return setCode;
  return '$setCode #$collector';
}

List<Map<String, dynamic>> _uniquePrintings(List<dynamic> rows) {
  final uniqueById = <String, Map<String, dynamic>>{};
  for (final row in rows.whereType<Map>()) {
    final cast = row.cast<String, dynamic>();
    final id = cast['id']?.toString();
    if (id == null || id.isEmpty) continue;
    uniqueById.putIfAbsent(id, () => cast);
  }
  return uniqueById.values.toList();
}

Iterable<Map> _flattenMainBoard(Map<String, dynamic> deck) {
  final mainBoard = (deck['main_board'] as Map?) ?? const {};
  return mainBoard.values
      .whereType<List>()
      .expand((items) => items)
      .whereType<Map>();
}

Future<List<Map<String, dynamic>>> _fetchLoreholdPickerPrintings(
  ApiClient api,
) async {
  final response = await api.get(
    '/cards/printings?name=${Uri.encodeQueryComponent(_commanderName)}&limit=50&sync=true',
  );
  expect(response.statusCode, 200);
  final rows =
      ((response.data as Map<String, dynamic>)['data'] as List?) ?? const [];
  final printings = _uniquePrintings(rows);
  expect(printings, hasLength(greaterThanOrEqualTo(2)));
  for (final printing in printings) {
    expect(printing['name'], _commanderName);
    expect((printing['set_code'] ?? '').toString().trim(), isNotEmpty);
    expect((printing['collector_number'] ?? '').toString().trim(), isNotEmpty);
    expect(printing.containsKey('foil'), isTrue);
    expect((printing['rarity'] ?? '').toString().trim(), isNotEmpty);
  }
  return printings;
}

Future<void> _openCommanderCardDialog({
  required WidgetTester tester,
  required String cardId,
}) async {
  await tester.tap(find.text('Cartas'));
  await tester.pumpAndSettle();
  final commanderTile = find.byKey(ValueKey('deck-card-$cardId'));
  await pumpUntilFound(tester, commanderTile, attempts: 60);
  await tester.ensureVisible(commanderTile);
  await tester.tap(commanderTile);
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(ValueKey('deck-card-details-dialog-$cardId')),
    attempts: 60,
  );
}

Future<void> _changeCommanderEdition({
  required IntegrationTestWidgetsFlutterBinding binding,
  required WidgetTester tester,
  required String currentCardId,
  required Map<String, dynamic> targetPrinting,
  required String captureName,
}) async {
  final targetId = targetPrinting['id'].toString();
  final changeEditionButton = find.byKey(
    ValueKey('deck-card-change-edition-$currentCardId'),
  );
  await pumpUntilFound(tester, changeEditionButton, attempts: 60);
  await tester.tap(changeEditionButton);
  await tester.pump();

  await pumpUntilFound(
    tester,
    find.byKey(ValueKey('deck-edition-picker-sheet-$currentCardId')),
    attempts: 60,
  );
  await pumpUntilFound(
    tester,
    find.byKey(const Key('deck-edition-picker-title')),
    attempts: 30,
  );

  final targetEditionRow = find.byKey(
    ValueKey('deck-edition-option-$targetId'),
  );
  await pumpUntilFound(tester, targetEditionRow, attempts: 60);
  await pumpUntilFound(
    tester,
    find.textContaining(_editionTitle(targetPrinting)),
    attempts: 30,
  );
  await captureVisualProof(binding, tester, captureName);

  await tester.ensureVisible(targetEditionRow);
  await tester.tap(targetEditionRow);
  await tester.pump();

  await pumpUntilFound(
    tester,
    find.text('Edição atualizada.'),
    attempts: 120,
    step: const Duration(milliseconds: 500),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'SM A135M runtime: Lorehold edition picker options preserve commander slot',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiClient.setToken(null);

      final api = ApiClient();
      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      final email = 'sm_a135m_lorehold_$unique@example.com';
      const password = 'Qa123456!';
      final username = 'sm_a135m_lorehold_$unique';

      final registerResponse = await api.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });
      expect(registerResponse.statusCode, anyOf(200, 201));
      final registerData = registerResponse.data as Map<String, dynamic>;
      final token = registerData['token'] as String;
      final user = registerData['user'] as Map<String, dynamic>;
      ApiClient.setToken(token);
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(user));

      final printings = await _fetchLoreholdPickerPrintings(api);
      final firstPrinting = printings.first;
      final firstId = firstPrinting['id'].toString();

      final deckResponse = await api.post('/decks', {
        'name': 'SM A135M Lorehold Edition $unique',
        'format': 'commander',
        'description': 'Android runtime proof for Lorehold edition picker.',
      });
      expect(deckResponse.statusCode, anyOf(200, 201));
      final deckId =
          (deckResponse.data as Map<String, dynamic>)['id'].toString();

      final addCommanderResponse = await api.post('/decks/$deckId/cards', {
        'card_id': firstId,
        'quantity': 1,
        'is_commander': true,
      });
      expect(addCommanderResponse.statusCode, 200);

      // ignore: avoid_print
      print('LOREHOLD_ANDROID_DECK_ID $deckId');
      // ignore: avoid_print
      print('LOREHOLD_ANDROID_OPTIONS ${printings.length}');

      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();
      await pumpUntilFound(tester, find.text('Decks'), attempts: 120);

      final navContext = tester.element(find.text('Decks').first);
      GoRouter.of(navContext).go('/decks/$deckId/search?mode=commander');
      await tester.pump();
      await pumpUntilFound(tester, find.text('Cartas'), attempts: 60);

      await tester.enterText(
        find.byKey(const Key('card-search-field')),
        _commanderName,
      );
      await tester.pump();
      await pumpUntilFound(tester, find.text(_commanderName), attempts: 120);
      await pumpUntilFound(
        tester,
        find.textContaining(firstPrinting['set_code'].toString().toUpperCase()),
        attempts: 60,
      );
      await captureVisualProof(
        binding,
        tester,
        'lorehold_01_search_edition_visible',
      );

      GoRouter.of(navContext).go('/decks/$deckId');
      await tester.pump();
      await pumpUntilFound(tester, find.text('Detalhes do Deck'), attempts: 80);
      await pumpUntilFound(tester, find.text(_commanderName), attempts: 80);
      await captureVisualProof(
        binding,
        tester,
        'lorehold_02_deck_details_before_change',
      );

      var currentId = firstId;
      final targets = printings
          .where((p) => p['id'].toString() != currentId)
          .toList(growable: false);
      for (final target in targets) {
        final targetId = target['id'].toString();
        await _openCommanderCardDialog(tester: tester, cardId: currentId);
        await pumpUntilFound(
          tester,
          find.textContaining(
            _editionTitle(
              printings.firstWhere((p) => p['id'].toString() == currentId),
            ),
          ),
          attempts: 60,
        );
        await _changeCommanderEdition(
          binding: binding,
          tester: tester,
          currentCardId: currentId,
          targetPrinting: target,
          captureName:
              'lorehold_03_picker_${target['set_code']}_${target['collector_number']}',
        );

        final deckAfterResponse = await api.get('/decks/$deckId');
        expect(deckAfterResponse.statusCode, 200);
        final deckAfter = deckAfterResponse.data as Map<String, dynamic>;
        final commanders =
            ((deckAfter['commander'] as List?) ?? const [])
                .cast<Map<String, dynamic>>();
        expect(commanders, hasLength(1));
        expect(commanders.single['id'], targetId);
        expect(commanders.single['name'], _commanderName);
        expect(
          commanders.single['collector_number']?.toString(),
          target['collector_number']?.toString(),
        );

        final mainCards = _flattenMainBoard(deckAfter);
        expect(
          mainCards.any((card) => card['name'] == _commanderName),
          isFalse,
        );
        for (final printing in printings) {
          expect(
            mainCards.any((card) => card['id'] == printing['id']),
            isFalse,
          );
        }

        currentId = targetId;
      }

      await captureVisualProof(
        binding,
        tester,
        'lorehold_04_deck_details_after_all_changes',
      );
      expectNoRawTechnicalErrorText(tester);

      // ignore: avoid_print
      print('LOREHOLD_ANDROID_RUNTIME_RESULT PASS');
    },
  );
}
