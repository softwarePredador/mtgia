import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/main.dart' as app;

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

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 30,
  Duration step = const Duration(seconds: 1),
}) async {
  for (var i = 0; i < attempts; i += 1) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Widget not found: $finder');
}

Future<void> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  int attempts = 30,
  Duration step = const Duration(seconds: 1),
}) async {
  for (var i = 0; i < attempts; i += 1) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  fail('Widget still present: $finder');
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
    await tester.pump(const Duration(seconds: 2));

    // Login screen.
    await _pumpUntilFound(tester, find.text('Entrar'), attempts: 60);
    await tester.pump(const Duration(seconds: 1));

    await _capture(binding, tester, '01_login');

    // Navigate to register.
    await tester.tap(find.text('Criar conta'));
    await tester.pump();

    await _pumpUntilFound(tester, find.text('Criar Conta'), attempts: 60);

    final unique = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final username = 'qa$unique';
    final email = 'qa$unique@example.com';
    const password = 'Qa123456!';

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), username);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
    await tester.enterText(fields.at(3), password);
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(binding, tester, '02_register_filled');

    // Tap the submit button (there is also a heading with the same text).
    final submit = find.widgetWithText(InkWell, 'Criar Conta');
    await tester.ensureVisible(submit);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(submit);
    await tester.pump();

    // Main shell should appear when authenticated.
    await _pumpUntilFound(tester, find.text('Decks'), attempts: 90);
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, tester, '03_home');

    // Decks tab.
    await tester.tap(find.text('Decks'));
    await tester.pump(const Duration(seconds: 2));
    await _capture(binding, tester, '04_decks');

    // Create a minimal deck to also validate/capture the Deck Details surface.
    String? createdName;
    final newDeckText = find.text('Novo Deck');
    final newDeckButton = find.ancestor(
      of: newDeckText,
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    if (newDeckText.evaluate().isNotEmpty) {
      if (newDeckButton.evaluate().isNotEmpty) {
        await tester.tap(newDeckButton.first);
      } else {
        await tester.tap(newDeckText.first);
      }
      await tester.pump();

      final dialog = find.byType(AlertDialog);
      await _pumpUntilFound(tester, dialog, attempts: 60);
      await tester.pump(const Duration(milliseconds: 300));
      await _capture(binding, tester, '04a_create_deck_dialog');

      createdName = 'QA Deck $unique';
      final nameField = find
          .descendant(of: dialog, matching: find.byType(TextField))
          .first;
      await tester.enterText(nameField, createdName);
      await tester.pump(const Duration(milliseconds: 300));

      final createButton = find.descendant(
        of: dialog,
        matching: find.widgetWithText(ElevatedButton, 'Criar'),
      );
      await tester.tap(createButton);
      await tester.pump();

      // Wait for the dialog to close before asserting the deck list updates.
      await _pumpUntilAbsent(tester, dialog, attempts: 60);

      final createdText = find.text(createdName);
      await _pumpUntilFound(tester, createdText, attempts: 120);
      await tester.ensureVisible(createdText);
      await tester.pump(const Duration(seconds: 1));
    }

    if (createdName != null) {
      final createdText = find.text(createdName);
      final tappable = find.ancestor(of: createdText, matching: find.byType(InkWell));
      if (tappable.evaluate().isNotEmpty) {
        await tester.tap(tappable.first);
      } else {
        await tester.tap(createdText.first);
      }
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Detalhes do Deck'), attempts: 90);
      await tester.pump(const Duration(seconds: 2));
      await _capture(binding, tester, '04b_deck_details');

      // Back to deck list.
      final back = find.byType(BackButton);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
        await tester.pump();
      }
      await _pumpUntilFound(tester, find.text('Meus Decks'), attempts: 60);
      await tester.pump(const Duration(seconds: 1));
    }

    // Open deck generator.
    // NOTE: do not tap scanner/camera flows in this test; they can trigger OS
    // permission prompts or external activities and make the app appear to go
    // to background during automated runs.
    final fabMenu = find.byType(PopupMenuButton<String>);
    if (fabMenu.evaluate().isNotEmpty) {
      await tester.tap(fabMenu);
      await tester.pump(const Duration(seconds: 1));

      // Constrain the tap to the popup menu overlay.
      final generateEntry = find.descendant(
        of: find.byType(PopupMenuItem<String>),
        matching: find.text('Gerar com IA'),
      );
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
    await _pumpUntilFound(tester, find.text('Gerador de Decks'), attempts: 60);
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, tester, '05_generate');

    // Generate preview (mock mode is allowed when OPENAI_API_KEY is missing).
    await tester.enterText(
      find.byType(TextField).first,
      'Deck agressivo de goblins vermelhos com curva baixa e muito burn.',
    );
    final generateButtonLabel = find.text('Gerar Deck').last;
    await tester.ensureVisible(generateButtonLabel);
    await tester.tap(generateButtonLabel);
    await tester.pump();
    final previewTitle = find.text('Preview do Deck');
    await _pumpUntilFound(tester, previewTitle, attempts: 120);
    await tester.ensureVisible(previewTitle);
    await tester.pump(const Duration(seconds: 1));
    await _capture(binding, tester, '06_generate_preview');

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
