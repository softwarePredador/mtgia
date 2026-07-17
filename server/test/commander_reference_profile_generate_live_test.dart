@Tags(['live', 'live_backend', 'live_external'])
library;

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _approvalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
const _productionBaseUrl = 'https://evolution-cartinhas.2ta7qx.easypanel.host';

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
  final enabled =
      Platform.environment['RUN_LOREHOLD_REFERENCE_PROFILE_LIVE'] == '1' &&
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
          _approvalPhrase &&
      Platform.environment['MANALOOM_CONFIRM_POSTGRES_WRITES'] ==
          _approvalPhrase;
  final skipReason =
      enabled
          ? null
          : 'Defina RUN_LOREHOLD_REFERENCE_PROFILE_LIVE=1 e as duas '
              'aprovacoes canonicas para provar /ai/generate live.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? _productionBaseUrl;
  final expectCardStats =
      Platform.environment['LIVE_REFERENCE_CARD_STATS'] == '1';

  Map<String, dynamic> decodeJson(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'value': decoded};
  }

  Future<String> authToken() async {
    if (baseUrl != _productionBaseUrl) {
      throw StateError('TEST_API_BASE_URL diverge do destino live aprovado.');
    }
    final suffix = DateTime.now().millisecondsSinceEpoch;
    final user = {
      'username': 'lorehold_profile_live_$suffix',
      'email': 'lorehold_profile_live_$suffix@example.invalid',
      'password': _secureProbePassword(),
    };

    final register = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
    expect(register.statusCode, anyOf(200, 201), reason: register.body);
    return decodeJson(register)['token'] as String;
  }

  group('Commander Reference Profile v1 live generate', () {
    test(
      'Lorehold request exposes profile diagnostics without assuming other commanders lack profiles',
      () async {
        final token = await authToken();
        final response = await http
            .post(
              Uri.parse('$baseUrl/ai/generate'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'prompt':
                    'Boros miracle big spells with topdeck setup and interaction',
                'format': 'Commander',
                'commander_name': 'Lorehold, the Historian',
              }),
            )
            .timeout(const Duration(seconds: 120));

        expect(response.statusCode, anyOf(200, 422), reason: response.body);
        final body = decodeJson(response);
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

        final generatedDeck =
            (body['generated_deck'] as Map?)?.cast<String, dynamic>();
        if (response.statusCode == 200 && generatedDeck != null) {
          final commander =
              (generatedDeck['commander'] as Map?)?.cast<String, dynamic>();
          expect(commander?['name'], equals('Lorehold, the Historian'));
        }

        final otherResponse = await http
            .post(
              Uri.parse('$baseUrl/ai/generate'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'prompt': 'Atraxa proliferate counters and value',
                'format': 'Commander',
                'commander_name': 'Atraxa, Praetors\' Voice',
              }),
            )
            .timeout(const Duration(seconds: 120));

        expect(
          otherResponse.statusCode,
          anyOf(200, 422),
          reason: otherResponse.body,
        );
        final otherBody = decodeJson(otherResponse);
        final otherDiagnostics =
            (otherBody['diagnostics'] as Map?)?.cast<String, dynamic>();
        expect(otherDiagnostics, isNotNull, reason: otherBody.toString());
        expect(otherDiagnostics, contains('reference_profile_used'));
        if (otherDiagnostics?['reference_profile_used'] == true) {
          expect(otherDiagnostics, contains('profile_confidence'));
          expect(otherDiagnostics, contains('source_count'));
        }
      },
      skip: skipReason,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
