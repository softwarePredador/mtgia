import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/forge_battle_client.dart';
import 'package:test/test.dart';

void main() {
  test('returns a successful Forge battle payload', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080/',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://forge.internal:8080/simulate');
        expect(jsonDecode(request.body), containsPair('seed', 42));
        return http.Response(
          jsonEncode({
            'status': 'completed',
            'engine': 'forge',
            'winner_deck_id': 'deck-a',
          }),
          200,
        );
      }),
    );

    final result = await client.simulate({'seed': 42});

    expect(result['engine'], 'forge');
    expect(result['winner_deck_id'], 'deck-a');
  });

  test('exposes unsupported cards from the strict Forge contract', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'error': 'forge_coverage_incomplete',
              'message': 'Forge could not resolve one card',
              'unsupported_cards': [
                {'deck': 'deck_a', 'name': 'Unknown Card'},
              ],
            }),
            422,
          )),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<ForgeCoverageIncomplete>().having(
          (error) => error.unsupportedCards.single['name'],
          'unsupported card',
          'Unknown Card',
        ),
      ),
    );
  });

  test('does not reinterpret Forge process failures as battles', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'error': 'simulation_failed',
              'message': 'Forge returned no completed game result',
            }),
            500,
          )),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<ForgeServiceException>()
            .having((error) => error.statusCode, 'status', 500),
      ),
    );
  });
}
