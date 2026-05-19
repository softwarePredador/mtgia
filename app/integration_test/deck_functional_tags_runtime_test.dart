import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_analysis_tab.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';

Future<String> _resolveFirstCardId(ApiClient api, String name) async {
  final query = Uri(queryParameters: {'name': name, 'limit': '1'}).query;
  final response = await api.get('/cards?$query');
  expect(response.statusCode, 200, reason: 'resolve $name');
  final data = response.data as Map<String, dynamic>;
  final rows = (data['data'] as List?) ?? const [];
  expect(rows, isNotEmpty, reason: 'card exists locally: $name');
  final card = rows.first as Map<String, dynamic>;
  final id = card['id']?.toString();
  expect(id, isNotNull, reason: 'card id for $name');
  return id!;
}

Future<String> _createSmallFunctionalDeck(ApiClient api) async {
  const cardNames = [
    'Talrand, Sky Summoner',
    'Sol Ring',
    'Arcane Signet',
    'Brainstorm',
    'Pongify',
    'Counterspell',
    'Whelming Wave',
  ];
  final cardIds = <String, String>{};
  for (final name in cardNames) {
    cardIds[name] = await _resolveFirstCardId(api, name);
  }

  final response = await api.post('/decks', {
    'name': 'Runtime Functional Tags',
    'format': 'commander',
    'description': 'Runtime sanitized functional tags proof',
    'cards': [
      {
        'card_id': cardIds['Talrand, Sky Summoner'],
        'quantity': 1,
        'is_commander': true,
      },
      for (final name in cardNames.skip(1))
        {'card_id': cardIds[name], 'quantity': 1, 'is_commander': false},
    ],
  });
  expect(response.statusCode, anyOf(200, 201));
  final data = response.data as Map<String, dynamic>;
  final deck = (data['deck'] as Map?)?.cast<String, dynamic>();
  final deckId = data['id']?.toString() ?? deck?['id']?.toString();
  expect(deckId, isNotNull);
  return deckId!;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, int> _pickFunctionalCounts(Map<String, dynamic> counts) {
  const tracked = ['ramp', 'draw', 'removal', 'board_wipe', 'protection'];
  return {for (final tag in tracked) tag: _asInt(counts[tag])};
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await clearRuntimeAuth();
  });

  testWidgets('Deck Analysis shows backend functional tag samples', (
    tester,
  ) async {
    final api = ApiClient();
    final health = await api.get('/health');
    expect(health.statusCode, 200);
    final healthData = _asMap(health.data);

    await seedAuthenticatedSession(
      api,
      usernamePrefix: 'functional_tags_runtime',
    );
    final deckId = await _createSmallFunctionalDeck(api);

    final analysisResponse = await api.get('/decks/$deckId/analysis');
    expect(analysisResponse.statusCode, 200);
    final analysisPayload = _asMap(analysisResponse.data);
    final functionalTags = _asMap(analysisPayload['functional_tags']);
    final source = _asMap(functionalTags['source']);
    final counts = _asMap(functionalTags['counts']);
    final coverage = _asMap(functionalTags['coverage']);
    final samples = _asMap(functionalTags['samples']);
    final sampleDetails = _asMap(functionalTags['sample_details']);

    final persistedRows = _asInt(source['persisted_rows']);
    final persistedCopies = _asInt(source['persisted_copies']);
    final heuristicRows = _asInt(source['heuristic_rows']);
    final heuristicCopies = _asInt(source['heuristic_copies']);
    final trackedCounts = _pickFunctionalCounts(counts);
    final rampSamples = (samples['ramp'] as List?) ?? const [];
    final rampSampleDetails = (sampleDetails['ramp'] as List?) ?? const [];
    final firstRampDetail = rampSampleDetails
        .whereType<Map>()
        .map((value) => value.cast<dynamic, dynamic>())
        .where((value) => value['reason']?.toString().trim().isNotEmpty == true)
        .cast<Map<dynamic, dynamic>?>()
        .firstWhere((value) => value != null, orElse: () => null);

    expect(persistedRows, greaterThan(0));
    expect(persistedCopies, greaterThan(0));
    expect(
      functionalTags['semantic_schema_version']?.toString(),
      'semantic_layer_v2_2026_05_18',
    );
    expect(trackedCounts['ramp'], greaterThanOrEqualTo(2));
    expect(_asInt(coverage['tagged_rows']), greaterThan(0));
    expect(_asInt(coverage['tagged_copies']), greaterThan(0));
    expect(rampSampleDetails, isNotEmpty);
    expect(firstRampDetail, isNotNull);

    final provider = DeckProvider(apiClient: api);
    await provider.fetchDeckDetails(deckId);
    final deck = provider.selectedDeck;
    expect(deck, isA<DeckDetails>());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            body: SingleChildScrollView(child: DeckAnalysisTab(deck: deck!)),
          ),
        ),
      ),
    );

    await pumpUntilFound(
      tester,
      find.byKey(Key('deck-analysis-functional-section-$deckId')),
      attempts: 60,
      step: const Duration(milliseconds: 500),
    );
    await pumpUntilFound(
      tester,
      find.byKey(Key('deck-analysis-functional-origin-$deckId')),
      attempts: 60,
      step: const Duration(milliseconds: 500),
    );

    final rampBucket = find.byKey(
      Key('deck-analysis-functional-bucket-$deckId-ramp'),
    );
    await tester.ensureVisible(rampBucket);
    await tester.tap(rampBucket);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Origem da contagem: functional_tags'),
      findsOneWidget,
    );
    expect(find.textContaining('Sol Ring'), findsWidgets);
    expect(find.textContaining('Conta como ramp'), findsWidgets);
    expectNoRawTechnicalErrorText(tester);

    // Sanitized runtime proof: no auth token, e-mail, raw payload or decklist.
    // Card-name booleans are limited to the tiny fixture used by this test.
    // ignore: avoid_print
    print(
      'DECK_FUNCTIONAL_TAGS_RUNTIME_SUMMARY ${jsonEncode({
        'backend_git_sha': healthData['git_sha']?.toString(),
        'analysis_http_status': analysisResponse.statusCode,
        'functional_tags_schema_version': functionalTags['schema_version']?.toString(),
        'semantic_schema_version': functionalTags['semantic_schema_version']?.toString(),
        'source_priority': source['priority']?.toString(),
        'persisted_rows': persistedRows,
        'persisted_copies': persistedCopies,
        'heuristic_rows': heuristicRows,
        'heuristic_copies': heuristicCopies,
        'counts': trackedCounts,
        'coverage': {'card_rows': _asInt(coverage['card_rows']), 'card_copies': _asInt(coverage['card_copies']), 'tagged_rows': _asInt(coverage['tagged_rows']), 'tagged_copies': _asInt(coverage['tagged_copies']), 'other_rows': _asInt(coverage['other_rows']), 'other_copies': _asInt(coverage['other_copies'])},
        'ramp_sample_count': rampSamples.length,
        'ramp_sample_detail_count': rampSampleDetails.length,
        'has_explainability_reason': firstRampDetail != null,
        'ui_rendered': true,
        'sol_ring_visible': true,
        'explainability_visible': true,
      })}',
    );

    // Keep binding referenced so visual capture setup stays available if enabled.
    expect(binding, isA<IntegrationTestWidgetsFlutterBinding>());
  });
}
