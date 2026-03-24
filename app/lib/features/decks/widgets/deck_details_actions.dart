import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../../core/theme/app_theme.dart';

typedef DeckSnackBarPresenter =
    void Function({
      required String message,
      required Color backgroundColor,
    });

typedef DeckValidationResultHandler =
    void Function(Map<String, dynamic> result, Set<String> invalidCardNames);

typedef DeckErrorDialogPresenter =
    Future<void> Function({
      required String title,
      required String message,
    });

typedef DeckExportTextLoader =
    Future<Map<String, dynamic>> Function(String deckId);

typedef DeckVisibilityToggler =
    Future<bool> Function(String deckId, {required bool isPublic});

typedef DeckValidator = Future<Map<String, dynamic>> Function(String deckId);

typedef DeckPricingLoader =
    Future<Map<String, dynamic>> Function(String deckId, {required bool force});

typedef DeckDescriptionUpdater =
    Future<bool> Function({
      required String deckId,
      required String description,
    });

String? extractDeckExportText(Map<String, dynamic> result) {
  if (result.containsKey('error')) {
    return null;
  }
  return result['text'] as String? ?? '';
}

String extractDeckExportError(
  Map<String, dynamic> result, {
  String fallback = 'Erro ao exportar deck',
}) {
  return result['error']?.toString() ?? fallback;
}

Future<void> executeToggleDeckVisibility({
  required String deckId,
  required bool currentIsPublic,
  required DeckVisibilityToggler togglePublic,
  required DeckSnackBarPresenter showSnackBar,
}) async {
  final newState = !currentIsPublic;
  final success = await togglePublic(deckId, isPublic: newState);

  showSnackBar(
    message:
        success
            ? (newState
                ? 'Deck agora é público! 🌍'
                : 'Deck agora é privado 🔒')
            : 'Erro ao alterar visibilidade',
    backgroundColor: success ? AppTheme.success : AppTheme.error,
  );
}

Future<void> executeShareDeckText({
  required String deckId,
  required DeckExportTextLoader exportDeckAsText,
  required DeckSnackBarPresenter showSnackBar,
  Future<void> Function(String text)? shareText,
}) async {
  final result = await exportDeckAsText(deckId);
  final text = extractDeckExportText(result);

  if (text == null) {
    showSnackBar(
      message: extractDeckExportError(result),
      backgroundColor: AppTheme.error,
    );
    return;
  }

  await (shareText ?? Share.share)(text);
}

Future<void> executeCopyDeckText({
  required String deckId,
  required DeckExportTextLoader exportDeckAsText,
  required DeckSnackBarPresenter showSnackBar,
  Future<void> Function(String text)? copyText,
}) async {
  final result = await exportDeckAsText(deckId);
  final text = extractDeckExportText(result);

  if (text == null) {
    showSnackBar(
      message: extractDeckExportError(result),
      backgroundColor: AppTheme.error,
    );
    return;
  }

  await (copyText ?? _copyTextToClipboard)(text);
  showSnackBar(
    message: 'Lista de cartas copiada para a área de transferência! 📋',
    backgroundColor: AppTheme.success,
  );
}

Future<void> executeDeckValidation({
  required String deckId,
  required DeckValidator validateDeck,
  required Set<String> Function(Map<String, dynamic> result)
  extractInvalidCardNames,
  required VoidCallback showLoading,
  required VoidCallback closeLoading,
  required DeckValidationResultHandler onValidationResult,
  required DeckSnackBarPresenter showSnackBar,
  required DeckErrorDialogPresenter showErrorDialog,
}) async {
  showLoading();

  try {
    final result = await validateDeck(deckId);
    closeLoading();
    onValidationResult(result, extractInvalidCardNames(result));

    final ok = result['ok'] == true;
    showSnackBar(
      message: ok ? '✅ Deck válido!' : 'Deck inválido',
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    );
  } catch (error) {
    closeLoading();
    await showErrorDialog(
      title: 'Deck inválido',
      message: error.toString().replaceFirst('Exception: ', ''),
    );
  }
}

Future<void> executeSilentDeckValidation({
  required String deckId,
  required DeckValidator validateDeck,
  required Set<String> Function(Map<String, dynamic> result)
  extractInvalidCardNames,
  required ValueChanged<bool> onLoadingChanged,
  required DeckValidationResultHandler onValidationResult,
}) async {
  onLoadingChanged(true);
  try {
    final result = await validateDeck(deckId);
    onValidationResult(result, extractInvalidCardNames(result));
  } catch (error) {
    final errorResult = {
      'ok': false,
      'error': error.toString().replaceFirst('Exception: ', ''),
    };
    onValidationResult(errorResult, extractInvalidCardNames(errorResult));
  } finally {
    onLoadingChanged(false);
  }
}

Future<void> executeDeckPricingLoad({
  required String deckId,
  required bool force,
  required DeckPricingLoader fetchDeckPricing,
  required ValueChanged<bool> onLoadingChanged,
  required ValueChanged<Map<String, dynamic>> onPricingLoaded,
  required void Function(String message) onError,
}) async {
  onLoadingChanged(true);
  try {
    final pricing = await fetchDeckPricing(deckId, force: force);
    onPricingLoaded(pricing);
  } catch (error) {
    onError(error.toString().replaceFirst('Exception: ', ''));
  } finally {
    onLoadingChanged(false);
  }
}

Future<void> executeDeckDescriptionUpdate({
  required String deckId,
  required String description,
  required DeckDescriptionUpdater updateDeckDescription,
  required DeckSnackBarPresenter showSnackBar,
}) async {
  final response = await updateDeckDescription(
    deckId: deckId,
    description: description,
  );

  if (!response) return;

  showSnackBar(
    message: description.isEmpty ? 'Descrição removida' : 'Descrição atualizada',
    backgroundColor: AppTheme.success,
  );
}

Future<void> _copyTextToClipboard(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}
