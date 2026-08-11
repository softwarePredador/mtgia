@Tags(['live', 'live_backend', 'live_db_write', 'live_external'])
library;

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

const _approvalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
const _commanderBracket = 2;

String _secureProbePassword() {
  const alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%_-';
  final random = Random.secure();
  return List<String>.generate(
    32,
    (_) => alphabet[random.nextInt(alphabet.length)],
    growable: false,
  ).join();
}

void main() {
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
  final liveRequested =
      Platform.environment['RUN_LOREHOLD_REFERENCE_PROFILE_LIVE'] == '1';
  final mutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      _approvalPhrase;
  final enabled =
      liveRequested && mutationApproved && targetConfigured && revisionPinned;
  final skipReason =
      enabled
          ? null
          : !liveRequested
          ? 'Defina RUN_LOREHOLD_REFERENCE_PROFILE_LIVE=1.'
          : !mutationApproved
          ? 'Defina a aprovação canônica de mutação live.'
          : !targetConfigured
          ? 'Defina TEST_API_BASE_URL HTTPS explícito ou loopback HTTP.'
          : 'Defina MANALOOM_EXPECTED_API_GIT_SHA com 40 hex.';
  final expectCardStats =
      Platform.environment['LIVE_REFERENCE_CARD_STATS'] == '1';
  final suffix = DateTime.now().millisecondsSinceEpoch;
  final password = _secureProbePassword();
  String? token;
  var accountCreated = false;

  Map<String, dynamic> decodeJson(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'value': decoded};
  }

  Future<void> assertTargetRevision() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    expect(response.statusCode, 200, reason: response.body);
    final health = decodeJson(response);
    expect(health['status'], 'healthy', reason: response.body);
    expect(
      health['git_sha']?.toString().toLowerCase(),
      expectedGitSha,
      reason: 'O backend alvo diverge da revisão explicitamente aprovada.',
    );
  }

  Future<String> authToken() async {
    final user = {
      'username': 'lorehold_profile_live_$suffix',
      'email': 'lorehold_profile_live_$suffix@example.invalid',
      'password': password,
      'legal_accepted': true,
      'terms_version': currentTermsVersion,
      'privacy_version': currentPrivacyVersion,
    };

    final register = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
    expect(register.statusCode, anyOf(200, 201), reason: register.body);
    final registeredToken = decodeJson(register)['token'] as String;
    token = registeredToken;
    accountCreated = true;
    return registeredToken;
  }

  void expectCommanderDeck(
    Map<String, dynamic> body, {
    required String commanderName,
  }) {
    expect(body['is_mock'], isFalse);
    expect(body['bracket'], _commanderBracket);
    expect(body['can_save'], isNot(false));

    final contract =
        (body['deckbuilding_contract'] as Map).cast<String, dynamic>();
    expect(contract['commander_name'], commanderName);
    expect(contract['status'], anyOf('ready', 'ready_for_battle_gate'));
    expect(contract['blockers'], isEmpty);

    final generatedDeck =
        (body['generated_deck'] as Map).cast<String, dynamic>();
    final commander =
        (generatedDeck['commander'] as Map).cast<String, dynamic>();
    expect(commander['name'], commanderName);
    final mainCards = (generatedDeck['cards'] as List)
        .whereType<Map>()
        .map((card) => card.cast<String, dynamic>())
        .toList(growable: false);
    final mainQuantity = mainCards.fold<int>(
      0,
      (total, card) => total + ((card['quantity'] as num?)?.toInt() ?? 1),
    );
    expect(mainQuantity, 99);
    expect(
      mainCards.where(
        (card) =>
            card['name']?.toString().trim().toLowerCase() ==
            commanderName.toLowerCase(),
      ),
      isEmpty,
    );
  }

  group('Commander Reference Profile v1 live generate', () {
    test(
      'Lorehold request exposes profile diagnostics without assuming other commanders lack profiles',
      () async {
        try {
          await assertTargetRevision();
          final auth = await authToken();
          final response = await http
              .post(
                Uri.parse('$baseUrl/ai/generate'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $auth',
                },
                body: jsonEncode({
                  'prompt':
                      'Boros miracle big spells with topdeck setup and interaction',
                  'format': 'Commander',
                  'commander_name': 'Lorehold, the Historian',
                  'bracket': _commanderBracket,
                }),
              )
              .timeout(const Duration(seconds: 120));

          expect(response.statusCode, 200, reason: response.body);
          final body = decodeJson(response);
          expectCommanderDeck(body, commanderName: 'Lorehold, the Historian');
          final diagnostics =
              (body['diagnostics'] as Map?)?.cast<String, dynamic>();
          expect(diagnostics, isNotNull, reason: body.toString());
          expect(diagnostics!['reference_profile_used'], isTrue);
          expect(diagnostics['profile_confidence'], equals('high'));
          expect(diagnostics['source_count'], greaterThanOrEqualTo(4));
          expect(
            diagnostics.containsKey('runtime_profile_origin'),
            isFalse,
            reason:
                'Lorehold deve usar o profile persistido quando ele estiver utilizavel; '
                'se runtime_profile_origin aparecer, o generator ainda caiu no fallback runtime.',
          );
          expect(diagnostics, contains('reference_card_stats_used'));
          expect(diagnostics, contains('on_theme_candidate_count'));
          expect(diagnostics, contains('unresolved_reference_cards'));
          expect(diagnostics, contains('package_keys'));
          if (expectCardStats) {
            expect(diagnostics['reference_card_stats_used'], isTrue);
            expect(diagnostics['on_theme_candidate_count'], greaterThan(0));
          }

          final otherResponse = await http
              .post(
                Uri.parse('$baseUrl/ai/generate'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $auth',
                },
                body: jsonEncode({
                  'prompt': 'Atraxa proliferate counters and value',
                  'format': 'Commander',
                  'commander_name': 'Atraxa, Praetors\' Voice',
                  'bracket': _commanderBracket,
                }),
              )
              .timeout(const Duration(seconds: 120));

          expect(otherResponse.statusCode, 200, reason: otherResponse.body);
          final otherBody = decodeJson(otherResponse);
          expectCommanderDeck(
            otherBody,
            commanderName: 'Atraxa, Praetors\' Voice',
          );
          final otherDiagnostics =
              (otherBody['diagnostics'] as Map?)?.cast<String, dynamic>();
          expect(otherDiagnostics, isNotNull, reason: otherBody.toString());
          expect(otherDiagnostics, contains('reference_profile_used'));
          if (otherDiagnostics?['reference_profile_used'] == true) {
            expect(otherDiagnostics, contains('profile_confidence'));
            expect(otherDiagnostics, contains('source_count'));
          }
        } finally {
          if (accountCreated && token != null) {
            final cleanup = await http.delete(
              Uri.parse('$baseUrl/users/me'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'confirmation': 'EXCLUIR MINHA CONTA',
                'password': password,
              }),
            );
            expect(cleanup.statusCode, 200, reason: cleanup.body);
            expect(decodeJson(cleanup)['account_deleted'], isTrue);
            accountCreated = false;
          }
        }
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
