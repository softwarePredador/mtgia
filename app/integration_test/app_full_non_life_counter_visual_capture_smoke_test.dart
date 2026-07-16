import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/main.dart' as app;

import 'runtime_test_helpers.dart';

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
  try {
    await binding.convertFlutterSurfaceToImage().timeout(
      const Duration(seconds: 25),
    );
    _surfaceConverted = true;
    // ignore: avoid_print
    print('CAPTURE_CONVERT_DONE $forName');
  } catch (e, st) {
    // ignore: avoid_print
    print('CAPTURE_CONVERT_ERROR $forName $e');
    // ignore: avoid_print
    print(st);
    rethrow;
  }
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

  try {
    // ignore: avoid_print
    print('CAPTURE_TAKING $name');
    final screenshot = await binding
        .takeScreenshot(name)
        .timeout(const Duration(seconds: 90));
    // ignore: avoid_print
    print('CAPTURE_TAKEN $name bytes=${screenshot.length}');

    _emitScreenshot(name, screenshot);
  } catch (e, st) {
    // ignore: avoid_print
    print('CAPTURE_ERROR $name $e');
    // ignore: avoid_print
    print(st);

    // Retry once: some devices lose the converted surface after navigation.
    _surfaceConverted = false;
    await _ensureSurfaceConverted(binding, name);

    // ignore: avoid_print
    print('CAPTURE_RETRY_TAKING $name');
    final screenshot = await binding
        .takeScreenshot(name)
        .timeout(const Duration(seconds: 90));
    // ignore: avoid_print
    print('CAPTURE_TAKEN $name bytes=${screenshot.length}');

    _emitScreenshot(name, screenshot);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('captures non-life-counter app tabs + deck generate preview', (
    tester,
  ) async {
    await binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(const app.ManaLoomApp());
    await tester.pump();
    await _capture(binding, tester, '00_splash');
    await tester.pump(const Duration(seconds: 2));

    // Login screen.
    await pumpUntilFound(tester, find.text('Entrar'), attempts: 60);
    await tester.pump(const Duration(seconds: 1));

    await _capture(binding, tester, '01_login');

    // Navigate to register.
    await tester.tap(find.byKey(const Key('login-open-register-button')));
    await tester.pump();

    await pumpUntilFound(
      tester,
      find.byKey(const Key('register-username-field')),
      attempts: 60,
    );

    final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final username = 'qa$unique';
    final email = 'qa$unique@example.com';
    const password = 'Qa123456!';

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
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(binding, tester, '02_register_filled');

    // Tap the submit button (there is also a heading with the same text).
    final submit = find.byKey(const Key('register-submit-button'));
    await tester.ensureVisible(submit);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(submit);
    await tester.pump();

    // Main shell should appear when authenticated.
    await pumpUntilFound(tester, find.text('Decks'), attempts: 90);
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, tester, '03_home');

    await tester.tap(find.text('Construir deck'));
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.text('Criar e Otimizar Deck'),
      attempts: 60,
    );
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, tester, '03a_onboarding_core_flow');

    // Decks tab.
    await tester.tap(find.text('Decks'));
    await tester.pump(const Duration(seconds: 2));
    await _capture(binding, tester, '04_decks');

    // Create a minimal deck to also validate/capture the Deck Details surface.
    String? createdName;
    final newDeckButton = find.byKey(
      const Key('deck-list-empty-create-button'),
    );
    if (newDeckButton.evaluate().isNotEmpty) {
      await tester.tap(newDeckButton);
      await tester.pump();

      final dialog = find.byKey(const Key('deck-create-dialog'));
      await pumpUntilFound(tester, dialog, attempts: 60);
      await tester.pump(const Duration(milliseconds: 300));
      await _capture(binding, tester, '04a_create_deck_dialog');

      createdName = 'QA Deck $unique';
      await tester.enterText(
        find.byKey(const Key('deck-create-name-field')),
        createdName,
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('deck-create-submit-button')));
      await tester.pump();

      // Wait for the dialog to close before asserting the deck list updates.
      await pumpUntilAbsent(tester, dialog, attempts: 60);

      final createdText = find.text(createdName);
      await pumpUntilFound(tester, createdText, attempts: 120);
      await tester.ensureVisible(createdText);
      await tester.pump(const Duration(seconds: 1));
    }

    if (createdName != null) {
      final createdText = find.text(createdName);
      final tappable = find.ancestor(
        of: createdText,
        matching: find.byType(InkWell),
      );
      if (tappable.evaluate().isNotEmpty) {
        await tester.tap(tappable.first);
      } else {
        await tester.tap(createdText.first);
      }
      await tester.pump();
      await pumpUntilFound(tester, find.text('Detalhes do Deck'), attempts: 90);
      await tester.pump(const Duration(seconds: 2));
      await _capture(binding, tester, '04b_deck_details');

      // Back to deck list.
      final back = find.byType(BackButton);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
        await tester.pump();
      }
      await pumpUntilFound(tester, find.text('Meus Decks'), attempts: 60);
      await tester.pump(const Duration(seconds: 1));
    }

    // Open deck generator.
    // NOTE: do not tap scanner/camera flows in this test; they can trigger OS
    // permission prompts or external activities and make the app appear to go
    // to background during automated runs.
    final fabMenu = find.byKey(const Key('deck-list-fab-menu'));
    if (fabMenu.evaluate().isNotEmpty) {
      await tester.tap(fabMenu);
      await tester.pump(const Duration(seconds: 1));

      final importEntry = find.byKey(const Key('deck-list-menu-import'));
      expect(importEntry, findsOneWidget);
      await tester.tap(importEntry);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Importar Lista'), attempts: 60);
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, '04c_deck_import');

      final importBack = find.byIcon(Icons.arrow_back);
      expect(importBack, findsOneWidget);
      await tester.tap(importBack);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Meus Decks'), attempts: 60);

      await tester.tap(fabMenu);
      await tester.pump(const Duration(seconds: 1));

      final generateEntry = find.byKey(const Key('deck-list-menu-generate'));
      expect(generateEntry, findsOneWidget);
      await tester.tap(generateEntry);
      await tester.pump();
    } else {
      final generateText = find.text('Gerar com IA');
      final generateButton = find.ancestor(
        of: generateText,
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(generateText, findsWidgets);
      if (generateButton.evaluate().isNotEmpty) {
        await tester.tap(generateButton.first);
      } else {
        await tester.tap(generateText.first);
      }
      await tester.pump();
    }
    await pumpUntilFound(tester, find.text('Gerador de Decks'), attempts: 60);
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, tester, '05_generate');

    // Generate preview (mock mode is allowed when OPENAI_API_KEY is missing).
    await tester.enterText(
      find.byKey(const Key('deck-generate-prompt-field')),
      'Deck agressivo de goblins vermelhos com curva baixa e muito burn.',
    );
    final generateButton = find.byKey(const Key('deck-generate-submit-button'));
    await tester.ensureVisible(generateButton);
    await tester.tap(generateButton);
    await tester.pump();
    final previewTitle = find.text('Preview antes de salvar');
    final asyncAccepted = find.text('Pedido aceito');
    final rawError = find.textContaining('Exception');
    await pumpUntilAnyFound(tester, [
      previewTitle,
      asyncAccepted,
      find.textContaining('Erro'),
      find.textContaining('Falha'),
      rawError,
    ], attempts: 120);
    if (previewTitle.evaluate().isNotEmpty) {
      await tester.ensureVisible(previewTitle);
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, '06_generate_preview');
    } else {
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, tester, '06_generate_preview_not_proven');
      expect(rawError, findsNothing);
      if (find.text('Comunidade').evaluate().isEmpty) {
        await tester.pageBack();
        await tester.pump();
        await pumpUntilAnyFound(tester, [
          find.text('Decks'),
          find.text('Meus Decks'),
        ]);
      }
    }

    // Community tab.
    await tester.tap(find.text('Comunidade'));
    await tester.pump(const Duration(seconds: 2));
    await _capture(binding, tester, '07_community');

    // Collection tab.
    await tester.tap(find.text('Coleção'));
    await tester.pump(const Duration(seconds: 2));
    await _capture(binding, tester, '08_collection');

    // Profile tab.
    await tester.tap(find.text('Perfil'));
    await tester.pump(const Duration(seconds: 2));
    await _capture(binding, tester, '09_profile');
  });
}
