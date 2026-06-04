import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/main.dart' as app;

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const commanders = <String>[
    "Atraxa, Praetors' Voice",
    'Kinnan, Bonder Prodigy',
    'Korvold, Fae-Cursed King',
    'Lorehold, the Historian',
    'Winota, Joiner of Forces',
  ];

  String screenshotNameFor(String commander) {
    return 'learned_button_${commander.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_").replaceAll(RegExp(r"_+$"), "")}';
  }

  testWidgets(
    'iPhone runtime: learned deck button appears for five promoted commanders',
    (tester) async {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      final api = ApiClient();
      await clearRuntimeAuth();
      await seedAuthenticatedSession(
        api,
        usernamePrefix: 'learned_five_runtime',
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

      final commanderField = find.byKey(
        const Key('deck-generate-commander-field'),
      );
      final learnedDeckButton = find.byKey(
        const Key('deck-generate-learned-deck-button'),
      );
      final generateSubmitButton = find.byKey(
        const Key('deck-generate-submit-button'),
      );

      expect(learnedDeckButton, findsNothing);
      await tester.scrollUntilVisible(
        generateSubmitButton,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await captureVisualProof(
        binding,
        tester,
        '00_no_commander_no_learned_button',
      );

      final results = <Map<String, dynamic>>[];
      for (final commander in commanders) {
        await tester.ensureVisible(commanderField);
        await tester.enterText(commanderField, '');
        await tester.pump();
        await tester.enterText(commanderField, commander);
        await tester.pump();

        await pumpUntilFound(
          tester,
          learnedDeckButton,
          attempts: 120,
          step: const Duration(milliseconds: 500),
        );
        expect(find.text('Usar deck aprendido do comandante'), findsOneWidget);
        expect(
          find.textContaining('Deck aprendido disponível:'),
          findsOneWidget,
        );
        expect(find.textContaining('commander_legal'), findsOneWidget);
        await tester.ensureVisible(learnedDeckButton);
        await captureVisualProof(binding, tester, screenshotNameFor(commander));

        final helperText =
            tester
                .widgetList<Text>(
                  find.textContaining('Deck aprendido disponível:'),
                )
                .map((widget) => widget.data ?? widget.textSpan?.toPlainText())
                .whereType<String>()
                .first;
        results.add({
          'commander': commander,
          'button_visible': true,
          'helper_text': helperText,
        });
      }

      // ignore: avoid_print
      print(
        'COMMANDER_LEARNED_AVAILABILITY_RUNTIME_SUMMARY '
        '${jsonEncode({'commanders': results})}',
      );
    },
  );
}
