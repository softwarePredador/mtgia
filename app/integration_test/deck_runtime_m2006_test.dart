import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_optimize_sheet_widgets.dart';
import 'package:manaloom/main.dart' as app;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _completeCommanderImportList = '''
1x Talrand, Sky Summoner [Commander]
38x Island
1x Sol Ring
1x Arcane Signet
1x Mind Stone
1x Thought Vessel
1x Sky Diamond
1x Sapphire Medallion
1x Wayfarer's Bauble
1x Prismatic Lens
1x Worn Powerstone
1x Midnight Clock
1x Brainstorm
1x Ponder
1x Preordain
1x Opt
1x Consider
1x Serum Visions
1x Gitaxian Probe
1x Frantic Search
1x Impulse
1x Chart a Course
1x Strategic Planning
1x Treasure Cruise
1x Dig Through Time
1x Fact or Fiction
1x Blue Sun's Zenith
1x Counterspell
1x Negate
1x Arcane Denial
1x Mana Leak
1x Swan Song
1x Dispel
1x Spell Pierce
1x Essence Scatter
1x Delay
1x Dissolve
1x Dissipate
1x Rewind
1x Sinister Sabotage
1x Unwind
1x Cancel
1x Rapid Hybridization
1x Pongify
1x Reality Shift
1x Cyclonic Rift
1x Into the Roil
1x Blink of an Eye
1x Resculpt
1x Aetherize
1x Whelming Wave
1x Evacuation
1x Murmuring Mystic
1x Docent of Perfection
1x Baral, Chief of Compliance
1x Metallurgic Summonings
1x Shark Typhoon
1x Talrand's Invocation
1x Archmage Emeritus
1x Deekah, Fractal Theorist
1x Octavia, Living Thesis
1x Haughty Djinn
1x Ominous Seas
''';

const _runtimeOptimizeIntensityLabel = String.fromEnvironment(
  'RUNTIME_OPTIMIZE_INTENSITY_LABEL',
  defaultValue: 'Agressivo',
);

const _runtimeOptimizeRequireApply = bool.fromEnvironment(
  'RUNTIME_OPTIMIZE_REQUIRE_APPLY',
);

const _runtimeOptimizeForceArchetype = String.fromEnvironment(
  'RUNTIME_OPTIMIZE_FORCE_ARCHETYPE',
);

String _safeCaptureSuffix(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

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

Future<void> _waitForDeckListReady(WidgetTester tester) {
  return _pumpUntilAny(
    tester,
    [
      find.text('Nenhum deck criado'),
      find.text('Gerar com IA'),
      find.byType(PopupMenuButton<String>),
      find.text('Novo Deck'),
    ],
    attempts: 120,
    step: const Duration(milliseconds: 500),
  );
}

Future<void> _openCreateDeckDialog(WidgetTester tester) async {
  final fabMenu = find.byType(PopupMenuButton<String>);
  if (fabMenu.evaluate().isNotEmpty) {
    await tester.tap(fabMenu.first);
    await tester.pump();

    final popupCreateEntry = find.descendant(
      of: find.byType(PopupMenuItem<String>),
      matching: find.text('Novo Deck'),
    );
    await _pumpUntilFound(
      tester,
      popupCreateEntry,
      attempts: 60,
      step: const Duration(milliseconds: 300),
    );
    await tester.tap(popupCreateEntry.first);
    await tester.pump();
    return;
  }

  final newDeckText = find.text('Novo Deck');
  await _pumpUntilFound(
    tester,
    newDeckText,
    attempts: 90,
    step: const Duration(milliseconds: 500),
  );
  final newDeckButton = find.ancestor(
    of: newDeckText,
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  if (newDeckButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(newDeckButton.first);
    await tester.tap(newDeckButton.first);
  } else {
    await tester.ensureVisible(newDeckText.first);
    await tester.tap(newDeckText.first);
  }
  await tester.pump();
}

Future<void> _openCreatedDeckDetails(
  WidgetTester tester,
  String deckName,
) async {
  final createdText = find.text(deckName);
  await _pumpUntilFound(
    tester,
    createdText,
    attempts: 120,
    step: const Duration(milliseconds: 500),
  );

  final tappable = find.ancestor(
    of: createdText,
    matching: find.byWidgetPredicate(
      (w) =>
          w is InkWell ||
          w is ListTile ||
          w is ElevatedButton ||
          w is OutlinedButton,
    ),
  );

  if (tappable.evaluate().isNotEmpty) {
    await tester.tap(tappable.first);
  } else {
    await tester.tap(createdText.first);
  }
  await tester.pump();
}

Future<String> _findDeckIdByName(String deckName) async {
  final response = await ApiClient().get('/decks');
  expect(response.statusCode, 200);
  final deckRows = (response.data as List).cast<Map>();
  final createdDeck = deckRows.firstWhere(
    (deck) => deck['name']?.toString() == deckName,
  );
  final createdDeckId = createdDeck['id']?.toString();
  expect(createdDeckId, isNotNull);
  return createdDeckId!;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'device runtime: iPhone 15 register -> create commander -> complete -> apply -> validate',
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
      expect(registerLink, findsOneWidget);
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Criar Conta'), attempts: 60);

      final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
      final username = 'iphone15_$unique';
      final email = 'iphone15_$unique@example.com';
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
      await _waitForDeckListReady(tester);
      await _capture(binding, tester, '03_decks');

      await _openCreateDeckDialog(tester);

      final createDialog = find.byType(AlertDialog);
      await _pumpUntilFound(tester, createDialog, attempts: 60);

      final createdDeckName = 'iPhone15 Runtime Talrand $unique';
      final createDialogNameField =
          find
              .descendant(of: createDialog, matching: find.byType(TextField))
              .first;
      await tester.enterText(createDialogNameField, createdDeckName);
      await tester.pump(const Duration(milliseconds: 300));

      final createDeckSubmit = find.descendant(
        of: createDialog,
        matching: find.widgetWithText(ElevatedButton, 'Criar'),
      );
      await tester.tap(createDeckSubmit);
      await tester.pump();

      await _pumpUntilAbsent(tester, createDialog, attempts: 60);
      await _capture(binding, tester, '04_deck_created');

      await _openCreatedDeckDetails(tester, createdDeckName);

      await _pumpUntilFound(
        tester,
        find.text('Detalhes do Deck'),
        attempts: 120,
      );
      await _capture(binding, tester, '05_empty_deck_details');

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pump();

      final importMenuEntry = find.text('Colar lista de cartas');
      await _pumpUntilFound(tester, importMenuEntry, attempts: 30);
      await tester.tap(importMenuEntry.last);
      await tester.pump();

      final importDialogTitle = find.text('Importar Lista');
      await _pumpUntilFound(tester, importDialogTitle, attempts: 30);

      final importListField = find.byType(TextField).last;
      await tester.enterText(importListField, _completeCommanderImportList);
      await tester.pump(const Duration(milliseconds: 300));
      await _capture(binding, tester, '06_import_commander');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Importar'));
      await tester.pump();

      await _pumpUntilAbsent(tester, importDialogTitle, attempts: 120);

      await tester.tap(find.text('Cartas').first);
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Comandante'), attempts: 60);
      await _pumpUntilFound(
        tester,
        find.text('Talrand, Sky Summoner'),
        attempts: 120,
      );
      await _capture(binding, tester, '07_commander_imported');

      if (_runtimeOptimizeForceArchetype.trim().isNotEmpty) {
        final createdDeckId = await _findDeckIdByName(createdDeckName);
        final detailsContext = tester.element(
          find.text('Detalhes do Deck').first,
        );
        await detailsContext.read<DeckProvider>().updateDeckStrategy(
          deckId: createdDeckId,
          archetype: _runtimeOptimizeForceArchetype,
          bracket: 2,
        );
        await tester.pump();
        // ignore: avoid_print
        print(
          'RUNTIME_OPTIMIZE_FORCED_ARCHETYPE $_runtimeOptimizeForceArchetype',
        );
      }

      await tester.tap(find.byTooltip('Otimizar deck').first);
      await tester.pump();

      await _pumpUntilFound(tester, find.text('Otimizar Deck'), attempts: 60);
      final applyCurrentStrategy = find.text('Aplicar estratégia atual');
      final strategyCards = find.byType(StrategyOptionCard);
      await _pumpUntilAny(tester, [
        strategyCards,
        applyCurrentStrategy,
      ], attempts: 240);
      await _capture(binding, tester, '08_optimize_sheet');

      final optimizeScrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Intensidade'),
        220,
        scrollable: optimizeScrollable,
      );
      await tester.pump();
      final intensityChoice = find.text(_runtimeOptimizeIntensityLabel);
      await _pumpUntilFound(tester, intensityChoice, attempts: 30);
      await tester.tap(intensityChoice.first);
      await tester.pump();
      await _capture(
        binding,
        tester,
        '08c_optimize_sheet_${_safeCaptureSuffix(_runtimeOptimizeIntensityLabel)}',
      );

      await _pumpUntilAny(tester, [
        strategyCards,
        applyCurrentStrategy,
      ], attempts: 240);

      if (applyCurrentStrategy.evaluate().isNotEmpty) {
        await tester.ensureVisible(applyCurrentStrategy.first);
        await tester.tap(applyCurrentStrategy.first);
      } else if (strategyCards.evaluate().isNotEmpty) {
        final strategyTapTarget = find.descendant(
          of: strategyCards.first,
          matching: find.byType(Text),
        );
        await tester.scrollUntilVisible(
          strategyTapTarget.first,
          200,
          scrollable: optimizeScrollable,
        );
        final strategyCard = tester.widget<StrategyOptionCard>(
          strategyCards.first,
        );
        strategyCard.onTap();
      } else {
        fail('Runtime optimize sheet did not expose an actionable strategy.');
      }
      await tester.pump();

      await _pumpUntilAny(tester, [
        find.textContaining('Completar deck ('),
        find.textContaining('Sugestões para '),
        find.text('Criar reconstrução guiada'),
        find.text('Nenhuma melhoria segura encontrada'),
        find.textContaining('Não foi possível concluir a otimização agora'),
      ], attempts: 240);

      if (find
          .textContaining('Não foi possível concluir a otimização agora')
          .evaluate()
          .isNotEmpty) {
        await _capture(binding, tester, '09_friendly_optimize_failure');
        expect(find.textContaining('executor interno'), findsNothing);
        expect(find.textContaining('resposta invalida'), findsNothing);
        expect(find.textContaining('resposta inválida'), findsNothing);
        if (_runtimeOptimizeRequireApply) {
          fail(
            'Runtime optimize returned a friendly failure before preview/apply; backend job did not produce suggestions.',
          );
        }
        return;
      }

      if (find.text('Criar reconstrução guiada').evaluate().isNotEmpty) {
        await _capture(binding, tester, '09_rebuild_guided_blocker');
        if (_runtimeOptimizeRequireApply) {
          fail(
            'Runtime optimize returned rebuild_guided, but apply proof was required.',
          );
        }
        return;
      }

      if (find
          .text('Nenhuma melhoria segura encontrada')
          .evaluate()
          .isNotEmpty) {
        await _pumpUntilFound(
          tester,
          find.textContaining('gate bloqueou as inseguras'),
          attempts: 30,
          step: const Duration(milliseconds: 500),
        );
        expect(find.textContaining('Candidatos analisados:'), findsWidgets);
        expect(find.textContaining('Pares avaliados:'), findsWidgets);
        expect(find.textContaining('Swaps seguros retornados:'), findsWidgets);
        expect(find.textContaining('Principal bloqueio:'), findsWidgets);
        final lowCoverage = find.textContaining('Faltaram candidatos seguros');
        if (lowCoverage.evaluate().isEmpty) {
          // ignore: avoid_print
          print('LOW_CANDIDATE_COVERAGE_NOT_PRESENT_IN_LIVE_RESPONSE');
        } else {
          expect(lowCoverage, findsWidgets);
        }
        expect(
          find.textContaining('aggressive_candidate_quality'),
          findsNothing,
        );
        expect(find.textContaining('quality_gate_rejected'), findsNothing);
        await _capture(binding, tester, '09_quality_rejected_blocker');
        if (_runtimeOptimizeRequireApply) {
          fail(
            'Runtime optimize returned safe no-op, but apply proof was required.',
          );
        }
        return;
      }

      await _capture(binding, tester, '09_preview');

      final canDeselectWithoutBreakingCompletion =
          find.textContaining('Sugestões para ').evaluate().isNotEmpty;
      if (!canDeselectWithoutBreakingCompletion ||
          find.byType(Checkbox).evaluate().length < 2) {
        fail('Runtime preview did not expose selectable swap suggestions');
      }
      final firstCheckboxToDeselect = find.byType(Checkbox).first;
      await tester.ensureVisible(firstCheckboxToDeselect);
      await tester.pump();
      final firstSelectedBeforeDeselect =
          tester.widget<Checkbox>(firstCheckboxToDeselect).value;
      await tester.tap(firstCheckboxToDeselect);
      await tester.pump();
      final firstSelectedAfterDeselect =
          tester.widget<Checkbox>(firstCheckboxToDeselect).value;
      expect(
        firstSelectedAfterDeselect,
        isNot(firstSelectedBeforeDeselect),
        reason:
            'Runtime preview removal checkbox did not toggle for partial apply.',
      );

      final lastCheckboxToDeselect = find.byType(Checkbox).last;
      await tester.ensureVisible(lastCheckboxToDeselect);
      await tester.pump();
      final lastSelectedBeforeDeselect =
          tester.widget<Checkbox>(lastCheckboxToDeselect).value;
      await tester.tap(lastCheckboxToDeselect);
      await tester.pump();
      final lastSelectedAfterDeselect =
          tester.widget<Checkbox>(lastCheckboxToDeselect).value;
      expect(
        lastSelectedAfterDeselect,
        isNot(lastSelectedBeforeDeselect),
        reason: 'Runtime preview checkbox did not toggle for partial apply.',
      );
      await _capture(binding, tester, '09b_preview_partial_selection');

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
      await _capture(binding, tester, '10_complete_validated');

      await _pumpUntil(tester, () {
        final titleElements = find.text('Detalhes do Deck').evaluate();
        if (titleElements.isEmpty) return false;
        final deck = titleElements.first.read<DeckProvider>().selectedDeck;
        return deck?.commander.any(
              (card) => card.name == 'Talrand, Sky Summoner',
            ) ??
            false;
      }, description: 'commander preserved after partial apply');
      final hasCompletionSignal =
          find.text('100 / 100 cartas').evaluate().isNotEmpty ||
          find.text('Deck completo!').evaluate().isNotEmpty ||
          find.text('Válido').evaluate().isNotEmpty ||
          find.text('✅ Deck válido!').evaluate().isNotEmpty;
      expect(hasCompletionSignal, isTrue);
    },
  );
}
