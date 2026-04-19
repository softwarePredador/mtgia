import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../models/deck.dart';
import '../models/deck_details.dart';

class DeckAiFlowException implements Exception {
  DeckAiFlowException({
    required this.message,
    required this.code,
    required this.payload,
    this.outcomeCode,
  });

  final String message;
  final String code;
  final String? outcomeCode;
  final Map<String, dynamic> payload;

  Map<String, dynamic> get qualityError =>
      (payload['quality_error'] is Map)
          ? (payload['quality_error'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  Map<String, dynamic> get nextAction =>
      (payload['next_action'] is Map)
          ? (payload['next_action'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  Map<String, dynamic> get deckState =>
      (payload['deck_state'] is Map)
          ? (payload['deck_state'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  bool get isNeedsRepair =>
      outcomeCode == 'needs_repair' || code == 'OPTIMIZE_NEEDS_REPAIR';

  bool get isNearPeak => outcomeCode == 'near_peak';

  bool get isNoSafeUpgradeFound =>
      outcomeCode == 'no_safe_upgrade_found' ||
      code == 'OPTIMIZE_NO_SAFE_SWAPS' ||
      code == 'OPTIMIZE_NO_ACTIONABLE_SWAPS';

  @override
  String toString() => message;
}

class DeckDetailsFetchState {
  const DeckDetailsFetchState({
    required this.selectedDeck,
    required this.errorMessage,
    required this.statusCode,
  });

  final DeckDetails? selectedDeck;
  final String? errorMessage;
  final int? statusCode;
}

class DeckListFetchState {
  const DeckListFetchState({required this.decks, required this.errorMessage});

  final List<Deck>? decks;
  final String? errorMessage;
}

class DeckDeleteResult {
  const DeckDeleteResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckDeleteState {
  const DeckDeleteState({required this.decks, required this.selectedDeck});

  final List<Deck> decks;
  final DeckDetails? selectedDeck;
}

class DeckAddCardResult {
  const DeckAddCardResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckMutationResult {
  const DeckMutationResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckCreateResult {
  const DeckCreateResult({
    required this.isSuccess,
    this.errorMessage,
    this.deck,
  });

  final bool isSuccess;
  final String? errorMessage;
  final Deck? deck;
}

class DeckAiAnalysisPayload {
  const DeckAiAnalysisPayload({
    required this.raw,
    required this.synergyScore,
    required this.strengths,
    required this.weaknesses,
  });

  final Map<String, dynamic> raw;
  final int? synergyScore;
  final String? strengths;
  final String? weaknesses;
}

class DeckColorIdentityEnrichmentResult {
  const DeckColorIdentityEnrichmentResult({
    required this.detailsByDeckId,
    required this.failedDeckIds,
  });

  final Map<String, DeckDetails> detailsByDeckId;
  final List<String> failedDeckIds;
}

class DeckListHydrationResult {
  const DeckListHydrationResult({
    required this.decks,
    required this.missingColorIdentityDecks,
  });

  final List<Deck> decks;
  final List<Deck> missingColorIdentityDecks;
}

class DeckColorIdentityApplyResult {
  const DeckColorIdentityApplyResult({
    required this.decks,
    required this.cachedDetails,
    required this.enrichedCount,
  });

  final List<Deck> decks;
  final List<DeckDetails> cachedDetails;
  final int enrichedCount;
}

class OptimizeDeckRequestResult {
  const OptimizeDeckRequestResult._({
    required this.isAsync,
    this.result,
    this.jobId,
    this.pollIntervalMs,
    this.totalStages,
  });

  const OptimizeDeckRequestResult.completed(Map<String, dynamic> result)
    : this._(isAsync: false, result: result);

  const OptimizeDeckRequestResult.async({
    required String jobId,
    required int pollIntervalMs,
    required int totalStages,
  }) : this._(
         isAsync: true,
         jobId: jobId,
         pollIntervalMs: pollIntervalMs,
         totalStages: totalStages,
       );

  final bool isAsync;
  final Map<String, dynamic>? result;
  final String? jobId;
  final int? pollIntervalMs;
  final int? totalStages;
}

class RebuildDeckRequestResult {
  const RebuildDeckRequestResult({required this.payload, this.draftDeckId});

  final Map<String, dynamic> payload;
  final String? draftDeckId;
}

class DeckPersistResult {
  const DeckPersistResult({
    required this.validation,
    required this.elapsedMilliseconds,
  });

  final Map<String, dynamic> validation;
  final int elapsedMilliseconds;
}

class OptimizeJobPollResult {
  const OptimizeJobPollResult.completed(this.result)
    : isCompleted = true,
      stage = null,
      stageNumber = null,
      totalStages = null;

  const OptimizeJobPollResult.pending({
    required this.stage,
    required this.stageNumber,
    required this.totalStages,
  }) : isCompleted = false,
       result = null;

  final bool isCompleted;
  final Map<String, dynamic>? result;
  final String? stage;
  final int? stageNumber;
  final int? totalStages;
}

class NamedOptimizationApplyResult {
  const NamedOptimizationApplyResult({
    required this.currentCards,
    required this.skippedForIdentity,
    required this.hasStructuralChange,
  });

  final Map<String, Map<String, dynamic>> currentCards;
  final List<String> skippedForIdentity;
  final bool hasStructuralChange;
}

class NamedOptimizationPayloadResult {
  const NamedOptimizationPayloadResult({
    required this.cardsPayload,
    required this.skippedForIdentity,
  });

  final List<Map<String, dynamic>> cardsPayload;
  final List<String> skippedForIdentity;
}

Map<String, dynamic> asDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String extractApiError(dynamic data, {required String fallback}) {
  if (data is Map) {
    final error = data['error'] ?? data['message'];
    if (error != null) {
      final text = error.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  return fallback;
}

Set<String>? getCommanderIdentitySet(DeckDetails? deck) {
  if (deck == null) return null;
  if (deck.commander.isEmpty) return null;
  final commander = deck.commander.first;
  final identity =
      commander.colorIdentity.isNotEmpty
          ? commander.colorIdentity
          : commander.colors;
  return identity.map((e) => e.toUpperCase()).toSet();
}

List<Map<String, dynamic>> extractCardSearchResults(dynamic responseData) {
  if (responseData is Map && responseData['data'] is List) {
    return (responseData['data'] as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  if (responseData is List) {
    return responseData
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  return const <Map<String, dynamic>>[];
}

Future<List<T>> resolveCardNamesInParallel<T>({
  required List<String> cardNames,
  required Future<T?> Function(String cardName) resolver,
}) async {
  final results = await Future.wait(cardNames.map(resolver));
  return results.whereType<T>().toList();
}

DeckAiFlowException buildDeckAiFlowException(
  dynamic data, {
  required String fallbackMessage,
  required String fallbackCode,
}) {
  final payload = asDynamicMap(data);
  final qualityError = asDynamicMap(payload['quality_error']);
  final message =
      payload['error']?.toString() ??
      qualityError['message']?.toString() ??
      fallbackMessage;
  final code = qualityError['code']?.toString() ?? fallbackCode;
  final outcomeCode = payload['outcome_code']?.toString();
  return DeckAiFlowException(
    message: message,
    code: code,
    outcomeCode: outcomeCode,
    payload: payload,
  );
}

Future<void> saveOptimizeDebugSnapshot({
  Map<String, dynamic>? request,
  Map<String, dynamic>? response,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (request != null) {
      await prefs.setString(
        'debug_last_ai_optimize_request',
        jsonEncode(request),
      );
    }
    if (response != null) {
      await prefs.setString(
        'debug_last_ai_optimize_response',
        jsonEncode(response),
      );
    }
    await prefs.setString(
      'debug_last_ai_optimize_at',
      DateTime.now().toIso8601String(),
    );
  } catch (_) {
    // Silencioso: não deve quebrar fluxo do app.
  }
}

void ensureSuccessfulDeckMutationResponse(
  ApiResponse response, {
  required String fallbackMessage,
}) {
  if (response.statusCode == 200) {
    return;
  }
  final data = response.data;
  final msg =
      (data is Map && data['error'] != null)
          ? data['error'].toString()
          : '$fallbackMessage: ${response.statusCode}';
  throw Exception(msg);
}

Map<String, dynamic> buildConnectionFailureResult(Object error) {
  return {'success': false, 'error': 'Erro de conexão: $error'};
}

Map<String, dynamic> buildExportConnectionFailureResult(Object error) {
  return {'error': 'Erro de conexão: $error'};
}

Future<Map<String, dynamic>> runConnectionSafeMapRequest(
  Future<Map<String, dynamic>> Function() operation,
) async {
  try {
    return await operation();
  } catch (error) {
    return buildConnectionFailureResult(error);
  }
}

Map<String, Map<String, dynamic>> buildCurrentCardsMap(DeckDetails deck) {
  final currentCards = <String, Map<String, dynamic>>{};

  for (final commander in deck.commander) {
    currentCards[commander.id] = {
      'card_id': commander.id,
      'quantity': commander.quantity,
      'is_commander': true,
    };
  }

  for (final entry in deck.mainBoard.entries) {
    for (final card in entry.value) {
      if (!card.isCommander) {
        currentCards[card.id] = {
          'card_id': card.id,
          'quantity': card.quantity,
          'is_commander': false,
        };
      }
    }
  }

  return currentCards;
}
