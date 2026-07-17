import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

const _commanderName = 'Lorehold, the Historian';
const _prompt =
    'Commander Boros Lorehold miracle big spells with topdeck setup, '
    'artifact ramp, interaction, spell-copy payoffs and token finishers.';

const _referencePackageCards = {
  "sensei's divining top",
  'scroll rack',
  'library of leng',
  'brainstone',
  'temple bell',
  'mikokoro, center of the sea',
  'victory chimes',
  'approach of the second sun',
  'storm herd',
  'rise of the eldrazi',
  'soulfire eruption',
  'apex of power',
  'volcanic vision',
  'creative technique',
  'dance with calamity',
  'call forth the tempest',
  "brass's bounty",
  'hit the mother lode',
  "mizzix's mastery",
  'swords to plowshares',
  'path to exile',
  'blasphemous act',
  'austere command',
  'terminus',
  'bonfire of the damned',
  'storm-kiln artist',
  'monastery mentor',
  'young pyromancer',
  'primal amulet',
  'primal amulet // primal wellspring',
  "pyromancer's goggles",
  'double vision',
  "sunbird's invocation",
  'arcane bombardment',
  "chandra, hope's beacon",
};

Iterable<Map<String, dynamic>> _flattenMainBoard(Map<String, dynamic> deck) {
  final mainBoard = deck['main_board'];
  if (mainBoard is Map) {
    return mainBoard.values
        .whereType<List>()
        .expand((items) => items)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>());
  }

  final cards = deck['cards'];
  if (cards is List) {
    return cards
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .where(
          (item) =>
              item['is_commander'] != true &&
              item['name']?.toString().trim().toLowerCase() !=
                  _commanderName.toLowerCase(),
        );
  }

  return const [];
}

Iterable<Map<String, dynamic>> _commanders(Map<String, dynamic> deck) {
  final commander = deck['commander'];
  if (commander is List) {
    return commander.whereType<Map>().map(
      (item) => item.cast<String, dynamic>(),
    );
  }
  if (commander is Map) {
    return [commander.cast<String, dynamic>()];
  }

  final cards = deck['cards'];
  if (cards is List) {
    return cards
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .where(
          (item) =>
              item['is_commander'] == true ||
              item['name']?.toString().trim().toLowerCase() ==
                  _commanderName.toLowerCase(),
        );
  }

  return const [];
}

int _quantity(Map<String, dynamic> card) {
  final raw = card['quantity'];
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '') ?? 1;
}

String _normalizedName(Map<String, dynamic> card) {
  return card['name']?.toString().trim().toLowerCase() ?? '';
}

bool _isReferencePackageCard(Map<String, dynamic> card) {
  final name = _normalizedName(card);
  if (_referencePackageCards.contains(name)) return true;
  return _referencePackageCards.any(
    (referenceName) =>
        referenceName.contains(' // ') &&
        referenceName.split(' // ').contains(name),
  );
}

bool _isOffIdentity(Map<String, dynamic> card) {
  final identity = card['color_identity'] ?? card['colors'];
  final values =
      identity is List
          ? identity.map((value) => value.toString().toUpperCase())
          : identity is String
          ? identity
              .replaceAll(',', ' ')
              .split(' ')
              .map((value) => value.trim().toUpperCase())
              .where((value) => value.isNotEmpty)
          : const Iterable<String>.empty();
  return values.any((color) => color != 'R' && color != 'W');
}

String _classification({
  required bool validationOk,
  required int onThemeMatches,
  required int offIdentityCount,
  required int totalWithCommander,
  required int loreholdCommanderCount,
  required int loreholdInMainCount,
}) {
  if (!validationOk ||
      offIdentityCount > 0 ||
      totalWithCommander != 100 ||
      loreholdCommanderCount != 1 ||
      loreholdInMainCount != 0) {
    return 'off_theme';
  }
  if (onThemeMatches >= 25) return 'on_theme';
  if (onThemeMatches >= 10) return 'generic';
  if (onThemeMatches > 0) return 'questionable';
  return 'off_theme';
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'SM A135M runtime: Lorehold generate uses public reference stats and saves valid Commander deck',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiClient.setToken(null);

      final api = ApiClient();
      expect(ApiClient.baseUrl, isNotEmpty);
      // ignore: avoid_print
      print('LOREHOLD_RUNTIME_BASE_URL ${ApiClient.baseUrl}');

      final healthResponse = await api.get('/health');
      expect(healthResponse.statusCode, 200);
      final health = (healthResponse.data as Map).cast<String, dynamic>();
      // ignore: avoid_print
      print(
        'LOREHOLD_RUNTIME_HEALTH status=${healthResponse.statusCode} '
        'git_sha=${health['git_sha']} latency_ms=${healthResponse.durationMs}',
      );

      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();
      await pumpUntilFound(tester, find.text('Entrar'), attempts: 90);
      await captureVisualProof(binding, tester, 'lorehold_generate_01_login');

      final registerLink = find.byKey(const Key('login-open-register-button'));
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.byKey(const Key('register-username-field')),
        attempts: 60,
      );
      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      const password = 'BetaQa!2026-Deck';
      final username = 'qa_lorehold_runtime_$unique';
      final email = '$username@example.invalid';

      await tester.enterText(
        find.byKey(const Key('register-username-field')),
        username,
      );
      await tester.enterText(
        find.byKey(const Key('register-email-field')),
        email,
      );
      await tester.enterText(
        find.byKey(const Key('register-password-field')),
        password,
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password-field')),
        password,
      );
      await tester.tap(find.byKey(const Key('register-submit-button')));
      await tester.pump();

      await pumpUntilFound(tester, find.text('Decks'), attempts: 120);
      await captureVisualProof(
        binding,
        tester,
        'lorehold_generate_02_registered',
      );
      expectNoRawTechnicalErrorText(tester);

      await tester.tap(find.text('Decks').first);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Meus Decks'), attempts: 60);
      await tester.tap(
        find.byKey(const Key('deck-list-empty-generate-button')),
      );
      await tester.pump();

      await pumpUntilFound(tester, find.text('Gerar Deck'), attempts: 60);
      await tester.enterText(
        find.byKey(const Key('deck-generate-commander-field')),
        _commanderName,
      );
      await tester.enterText(
        find.byKey(const Key('deck-generate-prompt-field')),
        _prompt,
      );
      await captureVisualProof(
        binding,
        tester,
        'lorehold_generate_03_prompt_with_commander',
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final feedbackStopwatch = Stopwatch()..start();
      final generateSubmit = find.byKey(
        const Key('deck-generate-submit-button'),
      );
      await tester.ensureVisible(generateSubmit);
      await tester.pump();
      await tester.tap(generateSubmit);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Pedido aceito'),
        attempts: 45,
        step: const Duration(milliseconds: 200),
      );
      // ignore: avoid_print
      print(
        'LOREHOLD_RUNTIME_INITIAL_FEEDBACK_MS '
        '${feedbackStopwatch.elapsedMilliseconds}',
      );

      await pumpUntilFound(
        tester,
        find.text('Preview antes de salvar'),
        attempts: 180,
        step: const Duration(seconds: 1),
      );
      await captureVisualProof(binding, tester, 'lorehold_generate_04_preview');
      expect(find.text(_commanderName), findsWidgets);
      expectNoRawTechnicalErrorText(tester);

      final deckName = 'QA Lorehold Reference Stats $unique';
      await tester.enterText(
        find.byKey(const Key('deck-generate-name-field')),
        deckName,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('deck-generate-save-button')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('deck-generate-save-button')));
      await tester.pump();

      await pumpUntilAnyFound(
        tester,
        [find.text('Meus Decks'), find.text('Decks')],
        attempts: 180,
        step: const Duration(seconds: 1),
      );
      await pumpUntilFound(
        tester,
        find.text(deckName),
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );
      await captureVisualProof(binding, tester, 'lorehold_generate_05_saved');

      final deckListResponse = await api.get('/decks');
      expect(deckListResponse.statusCode, 200);
      final deckRows = (deckListResponse.data as List).cast<Map>();
      final createdDeck = deckRows.firstWhere(
        (deck) => deck['name']?.toString() == deckName,
      );
      final deckId = createdDeck['id']?.toString();
      expect(deckId, isNotNull);
      // ignore: avoid_print
      print('LOREHOLD_RUNTIME_DECK_ID $deckId');

      final deckRow = find.byKey(ValueKey('deck-list-row-$deckId'));
      await pumpUntilFound(tester, deckRow, attempts: 90);
      await tester.ensureVisible(deckRow);
      await tester.tap(deckRow);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Detalhes do Deck'),
        attempts: 120,
      );
      await pumpUntilFound(tester, find.text(_commanderName), attempts: 120);
      await captureVisualProof(binding, tester, 'lorehold_generate_06_details');
      expectNoRawTechnicalErrorText(tester);

      final deckResponse = await api.get('/decks/$deckId');
      expect(deckResponse.statusCode, 200);
      final deck = (deckResponse.data as Map).cast<String, dynamic>();
      final mainBoard = _flattenMainBoard(deck).toList(growable: false);
      final commanders = _commanders(deck).toList(growable: false);
      final validationResponse = await api.post('/decks/$deckId/validate', {});
      expect(validationResponse.statusCode, 200);
      final validation =
          (validationResponse.data as Map).cast<String, dynamic>();
      final validationOk =
          validation['ok'] == true ||
          validation['is_valid'] == true ||
          validation['valid'] == true;

      final loreholdCommanderCount = commanders
          .where(
            (card) => _normalizedName(card) == _commanderName.toLowerCase(),
          )
          .fold<int>(0, (total, card) => total + _quantity(card));
      final loreholdInMainCount = mainBoard
          .where(
            (card) => _normalizedName(card) == _commanderName.toLowerCase(),
          )
          .fold<int>(0, (total, card) => total + _quantity(card));
      final mainQty = mainBoard.fold<int>(
        0,
        (total, card) => total + _quantity(card),
      );
      final totalWithCommander = mainQty + loreholdCommanderCount;
      final onThemeMatches = mainBoard
          .where(_isReferencePackageCard)
          .fold<int>(0, (total, card) => total + _quantity(card));
      final offIdentityCount = [...mainBoard, ...commanders]
          .where(_isOffIdentity)
          .fold<int>(0, (total, card) => total + _quantity(card));
      final classification = _classification(
        validationOk: validationOk,
        onThemeMatches: onThemeMatches,
        offIdentityCount: offIdentityCount,
        totalWithCommander: totalWithCommander,
        loreholdCommanderCount: loreholdCommanderCount,
        loreholdInMainCount: loreholdInMainCount,
      );

      // ignore: avoid_print
      print(
        'LOREHOLD_RUNTIME_SUMMARY '
        '${jsonEncode({'deck_id': deckId, 'validation_ok': validationOk, 'classification': classification, 'on_theme_reference_matches': onThemeMatches, 'main_qty': mainQty, 'total_with_commander': totalWithCommander, 'lorehold_commander_count': loreholdCommanderCount, 'lorehold_in_99_count': loreholdInMainCount, 'off_identity_count': offIdentityCount})}',
      );

      expect(validationOk, isTrue);
      expect(classification, anyOf('on_theme', 'generic'));
      expect(totalWithCommander, 100);
      expect(loreholdCommanderCount, 1);
      expect(loreholdInMainCount, 0);
      expect(offIdentityCount, 0);
    },
  );
}
