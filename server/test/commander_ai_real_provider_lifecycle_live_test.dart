@Tags(['live', 'live_backend', 'live_db_write', 'live_external'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

void main() {
  const password = 'BetaQa!2026-Deck';
  const commanderName = 'Lorehold, the Historian';
  const commanderBracket = 2;
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final lifecycleRequested =
      Platform.environment['RUN_REAL_PROVIDER_LIFECYCLE'] == '1';
  final mutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final baseUrl = (Platform.environment['TEST_API_BASE_URL'] ?? '')
      .trim()
      .replaceFirst(RegExp(r'/+$'), '');
  final target = Uri.tryParse(baseUrl);
  final targetIsLoopback =
      target != null &&
      (target.host == '127.0.0.1' ||
          target.host == 'localhost' ||
          target.host == '::1');
  final targetConfigured =
      target != null &&
      target.hasScheme &&
      (target.scheme == 'https' ||
          (target.scheme == 'http' && targetIsLoopback)) &&
      target.host.isNotEmpty;
  final expectedGitSha =
      (Platform.environment['MANALOOM_EXPECTED_API_GIT_SHA'] ?? '')
          .trim()
          .toLowerCase();
  final revisionPinned = RegExp(r'^[0-9a-f]{40}$').hasMatch(expectedGitSha);
  final skipReason =
      !liveRequested
          ? 'Teste requer RUN_INTEGRATION_TESTS=1.'
          : !lifecycleRequested
          ? 'Teste requer RUN_REAL_PROVIDER_LIFECYCLE=1.'
          : !mutationApproved
          ? 'Teste requer aprovação explícita de mutação.'
          : !targetConfigured
          ? 'Teste requer TEST_API_BASE_URL HTTPS explícito ou loopback HTTP.'
          : !revisionPinned
          ? 'Teste requer MANALOOM_EXPECTED_API_GIT_SHA com 40 hex.'
          : null;
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final email = 's6_09_real_provider_$suffix@example.invalid';
  String? token;

  Map<String, dynamic> decode(http.Response response) {
    final value = jsonDecode(response.body);
    return value is Map
        ? value.cast<String, dynamic>()
        : <String, dynamic>{'value': value};
  }

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 90),
  }) => http
      .post(
        Uri.parse('$baseUrl$path'),
        headers: headers(),
        body: jsonEncode(body),
      )
      .timeout(timeout);

  Future<http.Response> get(String path) =>
      http.get(Uri.parse('$baseUrl$path'), headers: headers());

  Future<void> assertTargetRevision() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    expect(response.statusCode, 200, reason: response.body);
    final health = decode(response);
    expect(health['status'], 'healthy', reason: response.body);
    expect(
      health['git_sha']?.toString().toLowerCase(),
      expectedGitSha,
      reason: 'O backend alvo diverge da revisão explicitamente aprovada.',
    );
  }

  Future<http.Response> pollOptimize(String jobId) async {
    for (var attempt = 0; attempt < 90; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final response = await get('/ai/optimize/jobs/$jobId');
      expect(response.statusCode, 200, reason: response.body);
      final body = decode(response);
      switch (body['status']) {
        case 'completed':
          return http.Response(jsonEncode(body['result']), 200);
        case 'failed':
          return http.Response(
            jsonEncode({
              'error': body['error'],
              'quality_error': body['quality_error'],
              'can_apply': false,
              'learning_eligible': false,
            }),
            422,
          );
        case 'cancelled':
          fail('Optimize job was cancelled unexpectedly: ${response.body}');
      }
    }
    fail('Optimize job polling timed out.');
  }

  Future<http.Response> optimize(
    String deckId, {
    required String intensity,
  }) async {
    final response = await post('/ai/optimize', {
      'deck_id': deckId,
      'archetype': 'spellslinger',
      'bracket': commanderBracket,
      'intensity': intensity,
      'async': false,
      'recommendation_context': {
        'explain_swaps': true,
        'include_price_risk_curve_bracket': true,
      },
    }, timeout: const Duration(minutes: 3));
    if (response.statusCode != 202) return response;
    final jobId = decode(response)['job_id']?.toString();
    expect(jobId, isNotNull, reason: response.body);
    return pollOptimize(jobId!);
  }

  List<Map<String, dynamic>> createCards(Map<String, dynamic> generatedDeck) {
    final cards = <Map<String, dynamic>>[];
    final commander = generatedDeck['commander'];
    if (commander is Map && commander['name'] is String) {
      cards.add({
        'name': commander['name'],
        'quantity': 1,
        'is_commander': true,
      });
    }
    for (final raw in (generatedDeck['cards'] as List? ?? const [])) {
      if (raw is! Map || raw['name'] is! String) continue;
      cards.add({
        'name': raw['name'],
        'quantity': (raw['quantity'] as num?)?.toInt() ?? 1,
        'is_commander': false,
      });
    }
    return cards;
  }

  test(
    'real provider traverses Commander generate, validate, analyze, preview and replay',
    () async {
      String? deckId;
      var accountCreated = false;
      try {
        await assertTargetRevision();
        final registration = await post('/auth/register', {
          'email': email,
          'password': password,
          'username': 's6_09_$suffix',
          'legal_accepted': true,
          'terms_version': currentTermsVersion,
          'privacy_version': currentPrivacyVersion,
        });
        expect(
          registration.statusCode,
          anyOf(200, 201),
          reason: registration.body,
        );
        token = decode(registration)['token'] as String;
        accountCreated = true;

        final generationResponse = await post('/ai/generate', {
          'prompt':
              'Commander Boros B2 de Miracle Big Spells com topdeck setup, '
              'interação e plano de vitória claro.',
          'format': 'Commander',
          'commander_name': commanderName,
          'bracket': commanderBracket,
          'generation_constraints': {'prefer_collection': true},
        }, timeout: const Duration(minutes: 2));
        expect(
          generationResponse.statusCode,
          200,
          reason: generationResponse.body,
        );
        final generation = decode(generationResponse);
        expect(generation['is_mock'], isFalse);
        expect(
          generation['generation_mode'],
          anyOf('ai_generate', 'provider_validated_repair'),
        );
        expect(generation['bracket'], commanderBracket);
        expect(generation['can_save'], isNot(false));
        final deckbuildingContract =
            (generation['deckbuilding_contract'] as Map)
                .cast<String, dynamic>();
        expect(
          deckbuildingContract['status'],
          anyOf('ready', 'ready_for_battle_gate'),
        );
        expect(deckbuildingContract['commander_name'], commanderName);
        expect(deckbuildingContract['blockers'], isEmpty);
        final generatedDeck =
            (generation['generated_deck'] as Map).cast<String, dynamic>();
        final generatedCommander =
            (generatedDeck['commander'] as Map).cast<String, dynamic>();
        expect(generatedCommander['name'], commanderName);
        final cards = createCards(generatedDeck);
        final generatedQuantity = cards.fold<int>(
          0,
          (total, card) => total + (card['quantity'] as int),
        );
        expect(generatedQuantity, 100);
        expect(
          cards.where((card) => card['is_commander'] == true),
          hasLength(1),
        );

        final created = await post('/decks', {
          'name': 'S6-09 real provider $suffix',
          'format': 'commander',
          'archetype': 'spellslinger',
          'bracket': commanderBracket,
          'description': 'Disposable real-provider lifecycle evidence.',
          'cards': cards,
        });
        expect(created.statusCode, anyOf(200, 201), reason: created.body);
        deckId = decode(created)['id'] as String;

        final validated = await post('/decks/$deckId/validate', const {});
        expect(validated.statusCode, 200, reason: validated.body);
        expect(decode(validated)['ok'], isTrue, reason: validated.body);

        final before = await get('/decks/$deckId');
        expect(before.statusCode, 200, reason: before.body);
        final beforeBody = decode(before);
        final beforeTotal = (beforeBody['stats'] as Map)['total_cards'];
        final beforeValidationAt = beforeBody['validation_updated_at'];

        final analysis = await get('/decks/$deckId/analysis');
        expect(analysis.statusCode, 200, reason: analysis.body);
        expect(decode(analysis), isNotEmpty);

        final preview = await optimize(deckId, intensity: 'focused');
        expect(preview.statusCode, anyOf(200, 422), reason: preview.body);
        final previewBody = decode(preview);
        expect(previewBody['is_mock'], isNot(true));
        if (preview.statusCode == 422 || previewBody['can_apply'] == false) {
          expect(previewBody['can_apply'], isFalse);
          expect(previewBody['learning_eligible'], isFalse);
        } else {
          expect(previewBody['mode'], anyOf('optimize', 'complete'));
          expect(previewBody['post_analysis'], isA<Map>());
        }

        final rebuild = await optimize(deckId, intensity: 'rebuild');
        expect(rebuild.statusCode, 200, reason: rebuild.body);
        final rebuildBody = decode(rebuild);
        expect(rebuildBody['mode'], 'rebuild_guided');
        expect(rebuildBody['can_apply'], isFalse);
        expect(rebuildBody['learning_eligible'], isFalse);

        final afterPreviews = await get('/decks/$deckId');
        expect(afterPreviews.statusCode, 200, reason: afterPreviews.body);
        final afterPreviewsBody = decode(afterPreviews);
        expect((afterPreviewsBody['stats'] as Map)['total_cards'], beforeTotal);
        expect(afterPreviewsBody['validation_updated_at'], beforeValidationAt);

        final goldfish = await post('/ai/simulate', {
          'deck_id': deckId,
          'type': 'goldfish',
          'simulations': 250,
        });
        expect(goldfish.statusCode, 200, reason: goldfish.body);
        final goldfishBody = decode(goldfish);
        final replayId = goldfishBody['replay_id']?.toString();
        expect(replayId, isNotNull);
        expect((goldfishBody['persistence'] as Map)['status'], 'saved');

        final replayList = await get('/decks/$deckId/battle-replays');
        final replayDetail = await get(
          '/decks/$deckId/battle-replays/$replayId',
        );
        expect(replayList.statusCode, 200, reason: replayList.body);
        expect(replayDetail.statusCode, 200, reason: replayDetail.body);
        expect(
          ((decode(replayList)['data'] as List).single as Map)['id'],
          replayId,
        );
        expect((decode(replayDetail)['replay'] as Map)['id'], replayId);

        final deleted = await http.delete(
          Uri.parse('$baseUrl/decks/$deckId'),
          headers: headers(),
        );
        expect(deleted.statusCode, 204, reason: deleted.body);
        deckId = null;
      } finally {
        if (deckId != null) {
          final deckCleanup = await http.delete(
            Uri.parse('$baseUrl/decks/$deckId'),
            headers: headers(),
          );
          expect(deckCleanup.statusCode, 204, reason: deckCleanup.body);
        }
        if (accountCreated && token != null) {
          final accountCleanup = await http.delete(
            Uri.parse('$baseUrl/users/me'),
            headers: headers(),
            body: jsonEncode({
              'confirmation': 'EXCLUIR MINHA CONTA',
              'password': password,
            }),
          );
          expect(accountCleanup.statusCode, 200, reason: accountCleanup.body);
          expect(decode(accountCleanup)['account_deleted'], isTrue);
        }
      }
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
