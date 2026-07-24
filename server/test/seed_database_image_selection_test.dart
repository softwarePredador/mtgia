import '../bin/seed_database.dart' as seed;
import 'package:test/test.dart';

void main() {
  test('seed prefers a concrete printing without changing oracle identity', () {
    const oracleId = '00000000-0000-4000-8000-000000000010';
    const printingId = '00000000-0000-4000-8000-000000000011';

    final selected = seed.selectSeedCardPayload([
      {
        'name': 'Test Card',
        'identifiers': {'scryfallOracleId': oracleId},
      },
      {
        'name': 'Test Card',
        'identifiers': {'scryfallOracleId': oracleId, 'scryfallId': printingId},
      },
    ]);

    expect(selected, isNotNull);
    expect(selected!['identifiers']['scryfallOracleId'], oracleId);
    expect(selected['identifiers']['scryfallId'], printingId);
  });

  test(
    'seed retains an oracle-only fallback when no printing is available',
    () {
      const oracleId = '00000000-0000-4000-8000-000000000020';

      final selected = seed.selectSeedCardPayload([
        {
          'name': 'Oracle Only',
          'identifiers': {'scryfallOracleId': oracleId},
        },
      ]);

      expect(selected, isNotNull);
      expect(selected!['identifiers']['scryfallOracleId'], oracleId);
    },
  );
}
