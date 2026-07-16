import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/edhrec_service.dart';
import 'package:test/test.dart';

void main() {
  const authorizationFlag = EdhrecService.automatedCollectionAuthorizationFlag;

  setUp(EdhrecService.clearCache);

  group('EDHREC automated collection authorization', () {
    test('is disabled by default and for non-truthy flag values', () {
      for (final environment in <Map<String, String>>[
        const {},
        const {authorizationFlag: ''},
        const {authorizationFlag: '0'},
        const {authorizationFlag: 'false'},
        const {authorizationFlag: 'disabled'},
      ]) {
        expect(
          EdhrecService(environment: environment).automatedCollectionAuthorized,
          isFalse,
        );
      }
    });

    test('accepts only an explicit truthy authorization flag', () {
      for (final value in const ['1', 'true', 'TRUE', 'yes', 'on']) {
        expect(
          EdhrecService(
            environment: {authorizationFlag: value},
          ).automatedCollectionAuthorized,
          isTrue,
        );
      }
    });

    test(
      'blocks both collection endpoints before any network request',
      () async {
        var requestCount = 0;
        final client = MockClient((request) async {
          requestCount++;
          return http.Response('{}', 500);
        });
        addTearDown(client.close);
        final service = EdhrecService(environment: const {}, client: client);

        expect(
          await service.fetchCommanderData('Atraxa, Praetors Voice'),
          isNull,
        );
        expect(
          await service.fetchAverageDeckData('Atraxa, Praetors Voice'),
          isNull,
        );
        expect(requestCount, 0);
      },
    );

    test('explicit authorization enables collection and parsing', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (request.url.path.contains('/average-decks/')) {
          return http.Response(
            jsonEncode({
              'num_decks': 20,
              'deck': {'Sol Ring': 1},
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'container': {
              'json_dict': {
                'cardlists': [
                  {
                    'header': 'Ramp',
                    'cardviews': [
                      {
                        'name': 'Sol Ring',
                        'synergy': 0.1,
                        'inclusion': 10,
                        'num_decks': 10,
                        'potential_decks': 20,
                      },
                    ],
                  },
                ],
              },
            },
          }),
          200,
        );
      });
      addTearDown(client.close);
      final service = EdhrecService(
        environment: const {authorizationFlag: 'true'},
        client: client,
      );

      final commander = await service.fetchCommanderData(
        'Atraxa, Praetors Voice',
      );
      final average = await service.fetchAverageDeckData(
        'Atraxa, Praetors Voice',
      );

      expect(commander?.topCards.single.name, 'Sol Ring');
      expect(commander?.topCards.single.inclusionRate, 0.5);
      expect(average?.seedCards.single.name, 'Sol Ring');
      expect(requestCount, 2);
    });

    test(
      'authorization is checked before cached evidence is returned',
      () async {
        var requestCount = 0;
        final client = MockClient((request) async {
          requestCount++;
          return http.Response(
            jsonEncode({
              'container': {
                'json_dict': {'cardlists': <Object>[]},
              },
            }),
            200,
          );
        });
        addTearDown(client.close);
        final authorized = EdhrecService(
          environment: const {authorizationFlag: 'true'},
          client: client,
        );
        final unauthorized = EdhrecService(
          environment: const {},
          client: client,
        );

        expect(
          await authorized.fetchCommanderData('Kaalia of the Vast'),
          isNotNull,
        );
        expect(requestCount, 1);
        expect(
          await unauthorized.fetchCommanderData('Kaalia of the Vast'),
          isNull,
        );
        expect(requestCount, 1);
      },
    );
  });
}
