import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_sheet_widgets.dart';
import 'package:manaloom/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void _emitScreenshot(String name, List<int> pngBytes) {
  final encoded = base64Encode(pngBytes);
  const chunkSize = 2000;
  // ignore: avoid_print
  print('SCREENSHOT_BEGIN $name');
  for (var offset = 0; offset < encoded.length; offset += chunkSize) {
    final end =
        (offset + chunkSize < encoded.length)
            ? offset + chunkSize
            : encoded.length;
    // ignore: avoid_print
    print('SCREENSHOT_CHUNK $name ${encoded.substring(offset, end)}');
  }
  // ignore: avoid_print
  print('SCREENSHOT_END $name');
}

bool _surfaceConverted = false;

Future<void> _ensureSurfaceConverted(
  IntegrationTestWidgetsFlutterBinding binding,
  String forName,
) async {
  if (_surfaceConverted) return;
  // ignore: avoid_print
  print('CAPTURE_CONVERT_BEGIN $forName');
  await binding.convertFlutterSurfaceToImage().timeout(
    const Duration(seconds: 25),
  );
  _surfaceConverted = true;
  // ignore: avoid_print
  print('CAPTURE_CONVERT_DONE $forName');
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  // ignore: avoid_print
  print('CAPTURE_START $name');
  await tester.pump(const Duration(milliseconds: 250));
  await _ensureSurfaceConverted(binding, name);
  final screenshot = await binding
      .takeScreenshot(name)
      .timeout(const Duration(seconds: 90));
  // ignore: avoid_print
  print('CAPTURE_TAKEN $name bytes=${screenshot.length}');
  _emitScreenshot(name, screenshot);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  int attempts = 60,
  Duration step = const Duration(seconds: 1),
}) async {
  for (var i = 0; i < attempts; i += 1) {
    await tester.pump(step);
    if (condition()) return;
  }
  fail('Timeout waiting for $description');
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
  Duration step = const Duration(seconds: 1),
}) {
  return _pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    description: finder.toString(),
    attempts: attempts,
    step: step,
  );
}

Future<void> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
  Duration step = const Duration(seconds: 1),
}) {
  return _pumpUntil(
    tester,
    () => finder.evaluate().isEmpty,
    description: '${finder.toString()} to disappear',
    attempts: attempts,
    step: step,
  );
}

Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  int attempts = 60,
  Duration step = const Duration(seconds: 1),
}) {
  return _pumpUntil(
    tester,
    () => finders.any((finder) => finder.evaluate().isNotEmpty),
    description: finders.map((finder) => finder.toString()).join(' OR '),
    attempts: attempts,
    step: step,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'iPhone 15 runtime: generate async -> save -> details -> optimize -> apply -> validate',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiClient.setToken(null);

      expect(ApiClient.baseUrl, isNotEmpty);
      // ignore: avoid_print
      print('DEVICE_RUNTIME_BASE_URL ${ApiClient.baseUrl}');

      await tester.pumpWidget(const app.ManaLoomApp());
      await tester.pump();

      await _pumpUntilFound(
        tester,
        find.text('Entrar'),
        attempts: 90,
        step: const Duration(milliseconds: 500),
      );
      await _capture(binding, tester, '01_login');

      final registerLink = find.widgetWithText(TextButton, 'Criar conta');
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Criar Conta'), attempts: 60);

      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      final username = 'iphone15_async_$unique';
      final email = 'iphone15_async_$unique@example.com';
      const password = 'Qa123456!';

      final registerFields = find.byType(TextFormField);
      expect(registerFields, findsNWidgets(4));

      await tester.enterText(registerFields.at(0), username);
      await tester.enterText(registerFields.at(1), email);
      await tester.enterText(registerFields.at(2), password);
      await tester.enterText(registerFields.at(3), password);

      final registerSubmit = find.widgetWithText(InkWell, 'Criar Conta');
      await tester.ensureVisible(registerSubmit);
      await tester.tap(registerSubmit);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Decks'), attempts: 120);
      await _capture(binding, tester, '02_registered_home');

      await tester.tap(find.text('Decks').first);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Meus Decks'), attempts: 60);
      await _pumpUntilAny(
        tester,
        [
          find.text('Gerar com IA'),
          find.text('Novo Deck'),
          find.byType(PopupMenuButton<String>),
        ],
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );
      await _capture(binding, tester, '03_decks');

      final generateCta = find.text('Gerar com IA');
      await _pumpUntilFound(
        tester,
        generateCta,
        attempts: 90,
        step: const Duration(milliseconds: 500),
      );
      await tester.ensureVisible(generateCta.first);
      await tester.tap(generateCta.first);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Gerar Deck'), attempts: 60);
      await _capture(binding, tester, '04_generate_screen');

      const prompt =
          'Deck Commander mono azul de Talrand spellslinger com instants baratos, '
          'cantrips, counters e finalizacao por tokens de Drake.';
      await tester.enterText(find.byType(TextField).first, prompt);
      final generateButton = find.widgetWithText(
        ElevatedButton,
        'Gerar proposta',
      );
      await tester.ensureVisible(generateButton);

      final feedbackStopwatch = Stopwatch()..start();
      await tester.tap(generateButton);
      await tester.pump();

      await _pumpUntilFound(
        tester,
        find.text('Pedido aceito'),
        attempts: 30,
        step: const Duration(milliseconds: 100),
      );
      final feedbackMs = feedbackStopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('ASYNC_GENERATE_INITIAL_FEEDBACK_MS $feedbackMs');
      await _capture(binding, tester, '05_generate_async_progress');

      await _pumpUntilFound(
        tester,
        find.text('Preview antes de salvar'),
        attempts: 180,
        step: const Duration(seconds: 1),
      );
      await _capture(binding, tester, '06_generate_preview');

      final deckName = 'iPhone15 Async Talrand $unique';
      await tester.enterText(
        find.widgetWithText(TextField, 'Nome do Deck'),
        deckName,
      );

      final generateScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Salvar deck revisado'),
        250,
        scrollable: generateScrollable,
      );
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Salvar deck revisado'),
      );
      await tester.pump();

      await _pumpUntilAbsent(
        tester,
        find.text('Preview antes de salvar'),
        attempts: 180,
        step: const Duration(seconds: 1),
      );
      await _pumpUntilAny(
        tester,
        [find.text('Meus Decks'), find.text('Decks')],
        attempts: 180,
        step: const Duration(seconds: 1),
      );
      await _pumpUntilFound(
        tester,
        find.text(deckName),
        attempts: 120,
        step: const Duration(milliseconds: 500),
      );
      await _capture(binding, tester, '07_generated_deck_saved');

      final deckListResponse = await ApiClient().get('/decks');
      expect(deckListResponse.statusCode, 200);
      final deckRows = (deckListResponse.data as List).cast<Map>();
      final createdDeck = deckRows.firstWhere(
        (deck) => deck['name']?.toString() == deckName,
      );
      final createdDeckId = createdDeck['id']?.toString();
      expect(createdDeckId, isNotNull);
      // ignore: avoid_print
      print('GENERATED_DECK_ID $createdDeckId');

      final navContext = tester.element(find.text('Meus Decks').first);
      GoRouter.of(navContext).go('/decks/$createdDeckId');
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.text('Detalhes do Deck'),
        attempts: 120,
      );
      await _capture(binding, tester, '08_deck_details');

      final optimizeButtonFinder = find.ancestor(
        of: find.byIcon(Icons.auto_fix_high),
        matching: find.byType(IconButton),
      );
      await _pumpUntilFound(tester, optimizeButtonFinder, attempts: 60);
      final optimizeButton = tester.widget<IconButton>(
        optimizeButtonFinder.first,
      );
      optimizeButton.onPressed?.call();
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Otimizar Deck'), attempts: 60);
      final applyCurrentStrategy = find.text('Aplicar estratégia atual');
      final strategyCards = find.byType(StrategyOptionCard);
      await _pumpUntilAny(tester, [
        strategyCards,
        applyCurrentStrategy,
      ], attempts: 240);
      await _capture(binding, tester, '09_optimize_sheet');

      if (applyCurrentStrategy.evaluate().isNotEmpty) {
        await tester.ensureVisible(applyCurrentStrategy.first);
        await tester.tap(applyCurrentStrategy.first);
      } else {
        final strategyCard = tester.widget<StrategyOptionCard>(
          strategyCards.first,
        );
        strategyCard.onTap();
      }
      await tester.pump();

      await _pumpUntilAny(tester, [
        find.textContaining('Completar deck ('),
        find.textContaining('Sugestões para '),
        find.text('Criar reconstrução guiada'),
        find.text('Nenhuma melhoria segura encontrada'),
      ], attempts: 240);

      if (find.text('Criar reconstrução guiada').evaluate().isNotEmpty) {
        await _capture(binding, tester, '10_rebuild_guided_blocker');
        return;
      }

      if (find
          .text('Nenhuma melhoria segura encontrada')
          .evaluate()
          .isNotEmpty) {
        await _capture(binding, tester, '10_safe_noop');
        return;
      }

      await _capture(binding, tester, '10_optimize_preview');

      final applyChangesButton = find.text('Aplicar mudanças');
      await tester.ensureVisible(applyChangesButton);
      await tester.tap(applyChangesButton);
      await tester.pump();

      await _pumpUntilAbsent(tester, applyChangesButton, attempts: 240);
      await _pumpUntilAny(tester, [
        find.text('100 / 100 cartas'),
        find.text('Deck completo!'),
        find.text('Válido'),
        find.text('✅ Deck válido!'),
      ], attempts: 240);
      await _capture(binding, tester, '11_complete_validated');

      expect(find.textContaining('Talrand'), findsWidgets);
      final hasCompletionSignal =
          find.text('100 / 100 cartas').evaluate().isNotEmpty ||
          find.text('Deck completo!').evaluate().isNotEmpty ||
          find.text('Válido').evaluate().isNotEmpty ||
          find.text('✅ Deck válido!').evaluate().isNotEmpty;
      expect(hasCompletionSignal, isTrue);
    },
  );
}
