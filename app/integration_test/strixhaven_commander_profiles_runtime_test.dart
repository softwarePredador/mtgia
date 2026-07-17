import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/main.dart' as app;

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

class _CommanderRuntimeCase {
  const _CommanderRuntimeCase({
    required this.slug,
    required this.commanderName,
    required this.prompt,
    required this.allowedColors,
  });

  final String slug;
  final String commanderName;
  final String prompt;
  final Set<String> allowedColors;
}

const _cases = [
  _CommanderRuntimeCase(
    slug: 'lorehold',
    commanderName: 'Lorehold, the Historian',
    prompt:
        'Commander Boros Lorehold miracle big spells with topdeck setup, '
        'artifact ramp, interaction, spell-copy payoffs and token finishers.',
    allowedColors: {'R', 'W'},
  ),
  _CommanderRuntimeCase(
    slug: 'dina',
    commanderName: 'Dina, Essence Brewer',
    prompt:
        'Commander Golgari Dina sacrifice deck with recursive fodder, '
        'lifegain, +1/+1 counters, card draw and resilient value engines.',
    allowedColors: {'B', 'G'},
  ),
  _CommanderRuntimeCase(
    slug: 'zimone',
    commanderName: 'Zimone, Infinite Analyst',
    prompt:
        'Commander Simic Zimone deck built around X spells, +1/+1 counters, '
        'ramp, card draw, protection and scalable late-game finishers.',
    allowedColors: {'G', 'U'},
  ),
];

class _RuntimeCredentials {
  const _RuntimeCredentials({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'SM A135M runtime: Strixhaven commander profiles generate/save/validate three Commander decks',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      await clearRuntimeAuth();
      final api = ApiClient();
      expect(ApiClient.baseUrl, isNotEmpty);
      // ignore: avoid_print
      print('STRIXHAVEN_RUNTIME_BASE_URL ${ApiClient.baseUrl}');

      final healthResponse = await api.get('/health');
      expect(healthResponse.statusCode, 200);
      final health = (healthResponse.data as Map).cast<String, dynamic>();
      // ignore: avoid_print
      print(
        'STRIXHAVEN_RUNTIME_HEALTH status=${healthResponse.statusCode} '
        'git_sha=${health['git_sha']} latency_ms=${healthResponse.durationMs}',
      );

      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();

      final credentials = await _registerByUi(binding, tester);
      await _loginByUi(binding, tester, credentials);
      await _openDeckList(tester);

      final summaries = <Map<String, dynamic>>[];
      for (final runtimeCase in _cases) {
        final summary = await _generateSaveOpenAndValidate(
          binding,
          tester,
          api,
          runtimeCase,
        );
        summaries.add(summary);
      }

      // ignore: avoid_print
      print('STRIXHAVEN_RUNTIME_ALL_SUMMARIES ${jsonEncode(summaries)}');
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Future<_RuntimeCredentials> _registerByUi(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  await pumpUntilFound(tester, find.text('Entrar'), attempts: 90);
  await captureVisualProof(binding, tester, 'strixhaven_01_login');

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
  final username = 'qa_strixhaven_runtime_$unique';
  final email = '$username@example.invalid';

  await tester.enterText(
    find.byKey(const Key('register-username-field')),
    username,
  );
  await tester.enterText(find.byKey(const Key('register-email-field')), email);
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
  await captureVisualProof(binding, tester, 'strixhaven_02_registered');
  expectNoRawTechnicalErrorText(tester);

  return _RuntimeCredentials(
    username: username,
    email: email,
    password: password,
  );
}

Future<void> _loginByUi(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  _RuntimeCredentials credentials,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await clearRuntimeAuth();
  await tester.pumpWidget(app.ManaLoomApp(key: UniqueKey()));
  await tester.pump();

  await pumpUntilFound(tester, find.text('Entrar'), attempts: 90);
  await tester.enterText(
    find.byKey(const Key('login-email-field')),
    credentials.email,
  );
  await tester.enterText(
    find.byKey(const Key('login-password-field')),
    credentials.password,
  );
  await tester.tap(find.byKey(const Key('login-submit-button')));
  await tester.pump();

  await pumpUntilFound(tester, find.text('Decks'), attempts: 120);
  await captureVisualProof(binding, tester, 'strixhaven_03_logged_in');
  expectNoRawTechnicalErrorText(tester);
  // ignore: avoid_print
  print('STRIXHAVEN_AUTH_SUMMARY registered=true login_ui=true');
}

Future<void> _openDeckList(WidgetTester tester) async {
  await tester.tap(find.text('Decks').first);
  await tester.pump();
  await pumpUntilFound(tester, find.text('Meus Decks'), attempts: 90);
}

Future<Map<String, dynamic>> _generateSaveOpenAndValidate(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  ApiClient api,
  _CommanderRuntimeCase runtimeCase,
) async {
  await _openGenerateScreen(tester);

  await tester.enterText(
    find.byKey(const Key('deck-generate-commander-field')),
    runtimeCase.commanderName,
  );
  await tester.enterText(
    find.byKey(const Key('deck-generate-prompt-field')),
    runtimeCase.prompt,
  );
  await captureVisualProof(
    binding,
    tester,
    'strixhaven_${runtimeCase.slug}_01_prompt',
  );

  FocusManager.instance.primaryFocus?.unfocus();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();

  final feedbackStopwatch = Stopwatch()..start();
  final submit = find.byKey(const Key('deck-generate-submit-button'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pump();

  await pumpUntilAnyFound(
    tester,
    [find.text('Pedido aceito'), find.text('Preview antes de salvar')],
    attempts: 60,
    step: const Duration(milliseconds: 250),
  );
  // ignore: avoid_print
  print(
    'STRIXHAVEN_GENERATE_INITIAL_FEEDBACK '
    'commander="${runtimeCase.commanderName}" '
    'elapsed_ms=${feedbackStopwatch.elapsedMilliseconds}',
  );

  await pumpUntilFound(
    tester,
    find.text('Preview antes de salvar'),
    attempts: 180,
    step: const Duration(seconds: 1),
  );
  await captureVisualProof(
    binding,
    tester,
    'strixhaven_${runtimeCase.slug}_02_preview',
  );
  expect(find.text(runtimeCase.commanderName), findsWidgets);
  expectNoRawTechnicalErrorText(tester);

  final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  final deckName = 'QA Strixhaven ${runtimeCase.slug} $unique';
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

  final deckListResponse = await api.get('/decks');
  expect(deckListResponse.statusCode, 200);
  final deckRows = (deckListResponse.data as List).cast<Map>();
  final createdDeck = deckRows.firstWhere(
    (deck) => deck['name']?.toString() == deckName,
  );
  final deckId = createdDeck['id']?.toString();
  expect(deckId, isNotNull);

  final deckRow = find.byKey(ValueKey('deck-list-row-$deckId'));
  await pumpUntilFound(tester, deckRow, attempts: 90);
  await tester.ensureVisible(deckRow);
  await tester.tap(deckRow);
  await tester.pump();

  await pumpUntilFound(tester, find.text('Detalhes do Deck'), attempts: 120);
  await pumpUntilFound(
    tester,
    find.text(runtimeCase.commanderName),
    attempts: 120,
  );
  await captureVisualProof(
    binding,
    tester,
    'strixhaven_${runtimeCase.slug}_03_details',
  );
  expectNoRawTechnicalErrorText(tester);

  final summary = await _validateSavedDeck(api, deckId!, runtimeCase);
  // ignore: avoid_print
  print('STRIXHAVEN_RUNTIME_SUMMARY ${jsonEncode(summary)}');

  await _returnToDeckList(tester);
  return summary;
}

Future<void> _openGenerateScreen(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text('Meus Decks'), attempts: 90);

  final emptyGenerate = find.byKey(
    const Key('deck-list-empty-generate-button'),
  );
  if (emptyGenerate.evaluate().isNotEmpty) {
    await tester.ensureVisible(emptyGenerate);
    await tester.tap(emptyGenerate);
  } else {
    final fabMenu = find.byKey(const Key('deck-list-fab-menu'));
    await pumpUntilFound(tester, fabMenu, attempts: 90);
    await tester.tap(fabMenu);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    final menuGenerate = find.byKey(const Key('deck-list-menu-generate'));
    await pumpUntilFound(tester, menuGenerate, attempts: 30);
    await tester.tap(menuGenerate);
  }

  await tester.pump();
  await pumpUntilFound(tester, find.text('Gerar Deck'), attempts: 90);
}

Future<void> _returnToDeckList(WidgetTester tester) async {
  final backButton = find.byTooltip('Back');
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await tester.pump();
  }
  await pumpUntilAnyFound(tester, [
    find.text('Meus Decks'),
    find.text('Decks'),
  ], attempts: 90);
  if (find.text('Meus Decks').evaluate().isEmpty) {
    await tester.tap(find.text('Decks').first);
    await tester.pump();
  }
  await pumpUntilFound(tester, find.text('Meus Decks'), attempts: 90);
}

Future<Map<String, dynamic>> _validateSavedDeck(
  ApiClient api,
  String deckId,
  _CommanderRuntimeCase runtimeCase,
) async {
  final deckResponse = await api.get('/decks/$deckId');
  expect(deckResponse.statusCode, 200);
  final deck = (deckResponse.data as Map).cast<String, dynamic>();
  final mainBoard = _flattenMainBoard(
    deck,
    runtimeCase.commanderName,
  ).toList(growable: false);
  final commanders = _commanders(
    deck,
    runtimeCase.commanderName,
  ).toList(growable: false);

  final validationResponse = await api.post('/decks/$deckId/validate', {});
  expect(validationResponse.statusCode, 200);
  final validation = (validationResponse.data as Map).cast<String, dynamic>();
  final validationOk =
      validation['ok'] == true ||
      validation['is_valid'] == true ||
      validation['valid'] == true;

  final commanderCount = commanders
      .where(
        (card) =>
            _normalizedName(card) == runtimeCase.commanderName.toLowerCase(),
      )
      .fold<int>(0, (total, card) => total + _quantity(card));
  final commanderInMainCount = mainBoard
      .where(
        (card) =>
            _normalizedName(card) == runtimeCase.commanderName.toLowerCase(),
      )
      .fold<int>(0, (total, card) => total + _quantity(card));
  final mainQty = mainBoard.fold<int>(
    0,
    (total, card) => total + _quantity(card),
  );
  final totalWithCommander = mainQty + commanderCount;
  final offIdentityCount = [...mainBoard, ...commanders]
      .where((card) => _isOffIdentity(card, runtimeCase.allowedColors))
      .fold<int>(0, (total, card) => total + _quantity(card));

  final summary = {
    'deck_id': deckId,
    'commander': runtimeCase.commanderName,
    'validation_ok': validationOk,
    'main_qty': mainQty,
    'total_with_commander': totalWithCommander,
    'commander_count': commanderCount,
    'commander_in_99_count': commanderInMainCount,
    'off_identity_count': offIdentityCount,
  };

  expect(validationOk, isTrue);
  expect(mainQty, 99);
  expect(totalWithCommander, 100);
  expect(commanderCount, 1);
  expect(commanderInMainCount, 0);
  expect(offIdentityCount, 0);
  return summary;
}

Iterable<Map<String, dynamic>> _flattenMainBoard(
  Map<String, dynamic> deck,
  String commanderName,
) {
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
              _normalizedName(item) != commanderName.toLowerCase(),
        );
  }

  return const [];
}

Iterable<Map<String, dynamic>> _commanders(
  Map<String, dynamic> deck,
  String commanderName,
) {
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
              _normalizedName(item) == commanderName.toLowerCase(),
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
  return _cardName(card).trim().toLowerCase();
}

String _cardName(Map<String, dynamic> card) {
  final direct = card['name']?.toString();
  if (direct != null && direct.trim().isNotEmpty) return direct;
  final nested = card['card'];
  if (nested is Map) {
    return nested['name']?.toString() ?? '';
  }
  return '';
}

bool _isOffIdentity(Map<String, dynamic> card, Set<String> allowedColors) {
  final nested = card['card'];
  final source = nested is Map ? nested : card;
  final identity = source['color_identity'] ?? source['colors'];
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
  return values.any((color) => !allowedColors.contains(color));
}
