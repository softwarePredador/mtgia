@Tags(['live', 'live_backend', 'live_db_write', 'battle_product_e2e'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final enabled = Platform.environment['RUN_BATTLE_PRODUCT_E2E'] == '1';
  final runForcedDiagnostic =
      Platform.environment['BATTLE_E2E_RUN_FORCED_DIAGNOSTIC'] == '1';
  final baseUrl = Platform.environment['TEST_API_BASE_URL'] ?? '';
  final runToken = Platform.environment['BATTLE_E2E_RUN_TOKEN'] ?? '';
  final harnessOwnsCleanup =
      Platform.environment['BATTLE_E2E_DEFER_CLEANUP_TO_HARNESS'] == '1';

  test(
    'app API persists reviewed execution and deck analysis consumes natural evidence',
    () async {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null) {
        fail('TEST_API_BASE_URL must be a valid URL.');
      }
      expect(uri.scheme, 'http');
      expect(
        uri.host,
        '127.0.0.1',
        reason: 'Mutable E2E must use IPv4 loopback.',
      );
      expect(uri.hasPort, isTrue);
      expect(
        RegExp(r'^[A-Za-z0-9_-]{12,96}$').hasMatch(runToken),
        isTrue,
        reason: 'BATTLE_E2E_RUN_TOKEN must be unique and harness-generated.',
      );
      expect(
        harnessOwnsCleanup,
        isTrue,
        reason: 'The isolated shell harness must own database cleanup.',
      );

      final user = {
        'email': 'battle.product.e2e.$runToken@example.invalid',
        'password': 'BattleProductE2E123!${runToken.substring(0, 12)}',
        'username': 'battle_product_e2e_$runToken',
      };
      final intruder = {
        'email': 'battle.product.e2e.intruder.$runToken@example.invalid',
        'password': 'BattleProductE2E456!${runToken.substring(0, 12)}',
        'username': 'battle_product_e2e_intruder_$runToken',
      };
      final token = await _registerUniqueIdentity(baseUrl, user);
      final intruderToken = await _registerUniqueIdentity(baseUrl, intruder);
      final headers = {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      };
      final intruderHeaders = {
        'authorization': 'Bearer $intruderToken',
        'content-type': 'application/json',
      };
      final baseline = _loadLoreholdDeck();
      final candidate = baseline
          .map((card) => Map<String, dynamic>.from(card))
          .toList(growable: false);
      final replaced = candidate.firstWhere(
        (card) => card['name'] == 'Aetherflux Reservoir',
      );
      replaced['name'] = 'A Good Day to Pie';

      final deckA = await _createDeck(
        baseUrl,
        headers,
        'Battle Product E2E Candidate $runToken',
        candidate,
      );
      final deckB = await _createDeck(
        baseUrl,
        headers,
        'Battle Product E2E Baseline $runToken',
        baseline,
      );

      if (runForcedDiagnostic) {
        final diagnostic = await _simulate(baseUrl, headers, deckA, deckB, {
          'seed': 0,
          'focus_cards': ['A Good Day to Pie'],
          'force_focus_access_mode': 'opening_hand',
        });
        expect(diagnostic['engine'], 'manaloom_native_reviewed');
        expect(
          diagnostic['engine_contract'],
          'native_reviewed_rules_execution',
        );
        expect(diagnostic['forced_access_mode'], 'opening_hand');
        final diagnosticEvidence =
            (diagnostic['battle_learning_evidence'] as Map)
                .cast<String, dynamic>();
        expect(diagnosticEvidence['natural_sample'], isFalse);
        expect(diagnosticEvidence['positive_exposure_ready'], isTrue);
        _expectReviewedAction(diagnostic);
      }

      final natural = await _simulate(baseUrl, headers, deckA, deckB, const {
        'seed': 2,
        'max_turns': 12,
        'focus_cards': ['A Good Day to Pie'],
      });
      final naturalEvidence =
          (natural['battle_learning_evidence'] as Map).cast<String, dynamic>();
      expect(natural['engine'], 'manaloom_native_reviewed');
      expect(natural['engine_contract'], 'native_reviewed_rules_execution');
      expect(natural['forced_access_mode'], 'none');
      expect(natural['max_turns'], 12);
      expect(natural['turns'], lessThanOrEqualTo(12));
      expect(naturalEvidence['natural_sample'], isTrue);
      expect(naturalEvidence['positive_exposure_ready'], isTrue);
      _expectReviewedAction(natural);
      _expectSavedReplayContract(natural);

      final repeatedNatural = await _simulate(
        baseUrl,
        headers,
        deckA,
        deckB,
        const {
          'seed': 2,
          'max_turns': 12,
          'focus_cards': ['A Good Day to Pie'],
        },
      );
      _expectSavedReplayContract(repeatedNatural);
      expect(
        repeatedNatural['replay_id'],
        isNot(natural['replay_id']),
        reason: 'Each durable execution must receive its own replay id.',
      );
      expect(
        _deterministicBattleProjection(repeatedNatural),
        _deterministicBattleProjection(natural),
        reason:
            'The same canonical deck order and seed must reproduce the '
            'observable Battle contract.',
      );

      final replayListResponse = await http.get(
        Uri.parse('$baseUrl/decks/$deckA/battle-replays?limit=5'),
        headers: headers,
      );
      expect(
        replayListResponse.statusCode,
        200,
        reason: replayListResponse.body,
      );
      final replayList = _json(replayListResponse);
      final replays = (replayList['data'] as List).whereType<Map>().toList();
      expect(replays, isNotEmpty);
      final replayIds = replays.map((replay) => replay['id']?.toString()).toSet();
      expect(replayIds, contains(natural['replay_id'].toString()));
      expect(replayIds, contains(repeatedNatural['replay_id'].toString()));
      expect(
        (replayList['simulation_contract'] as Map)['status'],
        'per_replay_engine_contract',
      );
      expect(replayList['advisory'], isFalse);
      final latestReplay = replays.first.cast<String, dynamic>();
      expect(
        (latestReplay['metrics'] as Map)['engine'],
        'manaloom_native_reviewed',
      );
      expect(
        (latestReplay['simulation_contract']
            as Map)['reviewed_native_rules_execution'],
        isTrue,
      );
      final replayId = natural['replay_id'].toString();
      final replayDetailResponse = await http.get(
        Uri.parse('$baseUrl/decks/$deckA/battle-replays/$replayId'),
        headers: headers,
      );
      expect(
        replayDetailResponse.statusCode,
        200,
        reason: replayDetailResponse.body,
      );
      final replay =
          (_json(replayDetailResponse)['replay'] as Map)
              .cast<String, dynamic>();
      expect(replay['engine'], 'manaloom_native_reviewed');
      final replayContract =
          (replay['simulation_contract'] as Map).cast<String, dynamic>();
      expect(replayContract['rules_execution'], isTrue);
      expect(replayContract['reviewed_native_rules_execution'], isTrue);
      expect(replayContract['rules_engine_priority'], 'native_residual');
      _expectReviewedAction(replay);

      final intruderListResponse = await http.get(
        Uri.parse('$baseUrl/decks/$deckA/battle-replays?limit=5'),
        headers: intruderHeaders,
      );
      _expectSanitizedNotFound(intruderListResponse);
      final intruderDetailResponse = await http.get(
        Uri.parse('$baseUrl/decks/$deckA/battle-replays/$replayId'),
        headers: intruderHeaders,
      );
      _expectSanitizedNotFound(intruderDetailResponse);

      final analysisResponse = await http.get(
        Uri.parse('$baseUrl/decks/$deckA/analysis'),
        headers: headers,
      );
      expect(analysisResponse.statusCode, 200, reason: analysisResponse.body);
      final analysis = _json(analysisResponse);
      final aggregate =
          (analysis['battle_learning_evidence'] as Map).cast<String, dynamic>();
      expect(aggregate['source'], 'battle_simulations');
      expect(
        aggregate['trusted_battle_count'],
        greaterThanOrEqualTo(runForcedDiagnostic ? 3 : 2),
      );
      expect(
        aggregate['positive_exposure_battle_count'],
        greaterThanOrEqualTo(1),
      );
      expect(aggregate['positive_exposure_ready'], isTrue);
      expect(aggregate['exposed_card_names_normalized'], isNotEmpty);
      expect(aggregate['promotion_allowed'], isFalse);
    },
    skip:
        enabled
            ? null
            : 'Run scripts/manaloom_battle_product_gate.sh --isolated-e2e.',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

List<Map<String, dynamic>> _loadLoreholdDeck() {
  final candidates = [
    File(
      '../docs/hermes-analysis/manaloom-knowledge/import_queue/lorehold/'
      'lorehold_best_of_learned_no_premium_mox_20260602.txt',
    ),
    File(
      'docs/hermes-analysis/manaloom-knowledge/import_queue/lorehold/'
      'lorehold_best_of_learned_no_premium_mox_20260602.txt',
    ),
  ];
  final file = candidates.firstWhere((candidate) => candidate.existsSync());
  final cards = <Map<String, dynamic>>[];
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line.trim());
    if (match == null) continue;
    var name = match.group(2)!;
    if (name == 'Needleverge Pathway') name = 'Turbulent Steppe';
    cards.add({
      'name': name,
      'quantity': int.parse(match.group(1)!),
      'is_commander': name == 'Lorehold, the Historian',
    });
  }
  if (cards.fold<int>(0, (sum, card) => sum + card['quantity'] as int) != 100) {
    throw StateError('Lorehold E2E fixture must contain exactly 100 cards.');
  }
  return cards;
}

Future<String> _registerUniqueIdentity(
  String baseUrl,
  Map<String, String> user,
) async {
  Future<http.Response> login() => http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode({'email': user['email'], 'password': user['password']}),
  );

  var response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode(user),
  );
  expect(response.statusCode, anyOf(200, 201), reason: response.body);
  response = await login();
  expect(response.statusCode, 200, reason: response.body);
  return _json(response)['token'] as String;
}

Future<String> _createDeck(
  String baseUrl,
  Map<String, String> headers,
  String name,
  List<Map<String, dynamic>> cards,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/decks'),
    headers: headers,
    body: jsonEncode({
      'name': name,
      'format': 'commander',
      'is_public': false,
      'cards': cards,
    }),
  );
  expect(response.statusCode, anyOf(200, 201), reason: response.body);
  return _json(response)['id'].toString();
}

Future<Map<String, dynamic>> _simulate(
  String baseUrl,
  Map<String, String> headers,
  String deckA,
  String deckB,
  Map<String, dynamic> options,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ai/simulate'),
    headers: headers,
    body: jsonEncode({
      'type': 'battle',
      'deck_id': deckA,
      'opponent_deck_id': deckB,
      'timeout_ms': 40000,
      ...options,
    }),
  );
  expect(response.statusCode, 200, reason: response.body);
  return _json(response);
}

Map<String, dynamic> _json(http.Response response) =>
    (jsonDecode(response.body) as Map).cast<String, dynamic>();

void _expectSanitizedNotFound(http.Response response) {
  expect(response.statusCode, 404, reason: response.body);
  final normalized = response.body.toLowerCase();
  expect(normalized, isNot(contains('battle_simulations')));
  expect(normalized, isNot(contains('select ')));
  expect(normalized, isNot(contains('postgres')));
  expect(normalized, isNot(contains('stack trace')));
}

void _expectReviewedAction(Map<String, dynamic> battle) {
  final actionEvents = (battle['events'] as List)
      .whereType<Map>()
      .where(
        (event) => event['event_type'] == 'unfinity_sticker_spell_resolved',
      )
      .toList(growable: false);
  expect(actionEvents, isNotEmpty);
  expect(actionEvents.first['card'], 'A Good Day to Pie');
  expect(actionEvents.first['rule_source'], 'curated');
  expect(actionEvents.first['rule_review_status'], 'verified');
  expect(
    actionEvents.first['rule_logical_key'],
    'battle_rule_v1:7cea0ab3329b942fa24b1b77ce9156c6',
  );
  expect(
    actionEvents.first['rule_oracle_hash'],
    '2be3fd92e4894d72dc08a6564f332157',
  );
}

void _expectSavedReplayContract(Map<String, dynamic> battle) {
  final replayId = battle['replay_id']?.toString() ?? '';
  final persistence =
      (battle['persistence'] as Map?)?.cast<String, dynamic>() ?? const {};
  expect(
    RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(replayId),
    isTrue,
  );
  expect(persistence['status'], 'saved');
  expect(persistence['required'], isTrue);
  expect(persistence['replay_id'], replayId);
}

Map<String, dynamic> _deterministicBattleProjection(
  Map<String, dynamic> battle,
) => {
  'status': battle['status'],
  'engine': battle['engine'],
  'engine_contract': battle['engine_contract'],
  'seed': battle['seed'],
  'winner': battle['winner'],
  'winner_deck_id': battle['winner_deck_id'],
  'turns': battle['turns'],
  'max_turns': battle['max_turns'],
  'win_condition': battle['win_condition'],
  'forced_access_mode': battle['forced_access_mode'],
  'events': battle['events'],
  'decision_trace': battle['decision_trace'],
  'visual_snapshots': battle['visual_snapshots'],
  'deck_construction': battle['deck_construction'],
  'learning_contract': battle['learning_contract'],
  'battle_learning_evidence': battle['battle_learning_evidence'],
};
