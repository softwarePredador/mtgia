import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/sinergia.dart';
import 'package:test/test.dart';

void main() {
  group('SynergyEngine runtime', () {
    test(
      'commander lookup timeout degrades to an empty candidate list',
      () async {
        final engine = SynergyEngine(
          client: MockClient((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 25));
            return http.Response('{}', 200);
          }),
          requestTimeout: const Duration(milliseconds: 1),
        );

        final result = await engine.fetchCommanderSynergies(
          commanderName: 'Lorehold, the Historian',
          colors: const ['R', 'W'],
          archetype: 'spellslinger',
        );

        expect(result, isEmpty);
      },
    );

    test('unsupported function query uses bounded textual fallback', () async {
      var calls = 0;
      final engine = SynergyEngine(
        client: MockClient((request) async {
          calls++;
          final query = request.url.queryParameters['q'] ?? '';
          if (query.contains('function:cantrip')) {
            return http.Response('{}', 404);
          }
          expect(query, contains('o:"draw a card"'));
          return http.Response(
            jsonEncode({
              'data': [
                {'name': 'Faithless Looting'},
              ],
            }),
            200,
          );
        }),
      );

      final result = await engine.searchScryfall('function:cantrip id<=RW');

      expect(result, ['Faithless Looting']);
      expect(calls, 2);
    });
  });
}
