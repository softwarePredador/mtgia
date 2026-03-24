import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/widgets/deck_details_actions.dart';

void main() {
  test('executeToggleDeckVisibility reports success copy', () async {
    String? snackMessage;
    Color? snackBackgroundColor;

    await executeToggleDeckVisibility(
      deckId: 'deck-1',
      currentIsPublic: false,
      togglePublic: (_, {required isPublic}) async => isPublic,
      showSnackBar: ({
        required String message,
        required Color backgroundColor,
      }) {
        snackMessage = message;
        snackBackgroundColor = backgroundColor;
      },
    );
    expect(snackMessage, 'Deck agora é público! 🌍');
    expect(snackBackgroundColor, AppTheme.success);
  });

  test('executeCopyDeckText reports export failure', () async {
    String? snackMessage;
    Color? snackBackgroundColor;

    await executeCopyDeckText(
      deckId: 'deck-1',
      exportDeckAsText: (_) async => {'error': 'falhou'},
      showSnackBar: ({
        required String message,
        required Color backgroundColor,
      }) {
        snackMessage = message;
        snackBackgroundColor = backgroundColor;
      },
      copyText: (_) async {},
    );

    expect(snackMessage, 'falhou');
    expect(snackBackgroundColor, AppTheme.error);
  });

  test('executeDeckValidation returns result and success snack', () async {
    Map<String, dynamic>? capturedResult;
    Set<String>? capturedInvalidNames;
    String? snackMessage;
    var loadingShown = 0;
    var loadingClosed = 0;

    await executeDeckValidation(
      deckId: 'deck-1',
      validateDeck: (_) async => {'ok': true},
      extractInvalidCardNames: (_) => <String>{},
      showLoading: () => loadingShown++,
      closeLoading: () => loadingClosed++,
      onValidationResult: (result, invalidNames) {
        capturedResult = result;
        capturedInvalidNames = invalidNames;
      },
      showSnackBar: ({
        required message,
        required backgroundColor,
      }) {
        snackMessage = message;
      },
      showErrorDialog: ({required title, required message}) async {},
    );

    expect(loadingShown, 1);
    expect(loadingClosed, 1);
    expect(capturedResult?['ok'], true);
    expect(capturedInvalidNames, isEmpty);
    expect(snackMessage, '✅ Deck válido!');
  });

  test('executeSilentDeckValidation converts exception into error result', () async {
    Map<String, dynamic>? capturedResult;
    Set<String>? capturedInvalidNames;
    final loadingStates = <bool>[];

    await executeSilentDeckValidation(
      deckId: 'deck-1',
      validateDeck: (_) async => throw Exception('erro local'),
      extractInvalidCardNames: (result) =>
          {(result['error'] ?? '').toString()},
      onLoadingChanged: loadingStates.add,
      onValidationResult: (result, invalidNames) {
        capturedResult = result;
        capturedInvalidNames = invalidNames;
      },
    );

    expect(loadingStates, [true, false]);
    expect(capturedResult?['ok'], false);
    expect(capturedInvalidNames, {'erro local'});
  });

  test('executeDeckPricingLoad reports loaded pricing', () async {
    Map<String, dynamic>? pricing;
    final loadingStates = <bool>[];

    await executeDeckPricingLoad(
      deckId: 'deck-1',
      force: true,
      fetchDeckPricing: (_, {required force}) async => {
        'estimated_total_usd': force ? 12.5 : 0,
      },
      onLoadingChanged: loadingStates.add,
      onPricingLoaded: (value) => pricing = value,
      onError: (_) {},
    );

    expect(loadingStates, [true, false]);
    expect(pricing?['estimated_total_usd'], 12.5);
  });
}
