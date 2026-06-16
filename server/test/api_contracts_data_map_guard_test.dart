import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String contracts;

  setUpAll(() {
    contracts = File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();
  });

  group('API contracts data map source guards', () {
    test('documents route-discovery edge cases and operational aliases', () {
      for (final route in const [
        'GET /cards/:id/rulings',
        'GET /binder/stats',
        'GET /community/decks/following',
        'GET /ready',
      ]) {
        expect(
          contracts,
          contains('| `$route'),
          reason:
              '$route must stay documented in API_CONTRACTS_AND_DATA_MAP.md',
        );
      }
    });

    test('does not document a generic GET binder item route', () {
      expect(
        contracts,
        isNot(contains('| `GET /binder/:id`')),
        reason:
            'server/routes/binder/[id]/index.dart only supports GET for the '
            'special /binder/stats alias; item detail GET is not a contract.',
      );
    });

    test('preserves recently added AI contract rows from source-backed docs',
        () {
      for (final route in const [
        'POST /ai/simulate',
        'POST /ai/simulate-matchup',
        'POST /ai/weakness-analysis',
        'GET /ai/commander-learning?commander=',
      ]) {
        expect(
          contracts,
          contains('| `$route'),
          reason:
              '$route is source-backed and must not be dropped by docs sync.',
        );
      }
    });
  });
}
