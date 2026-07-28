@Tags(['live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/optimize_filler_loader_support.dart';
import 'package:test/test.dart';

void main() {
  final enabled =
      Platform.environment['RUN_OPTIMIZE_BASIC_LAND_DB_TESTS'] == '1' &&
      Platform.environment['MANALOOM_DISPOSABLE_POSTGRES'] ==
          'I_APPROVE_DISPOSABLE_LOCAL_POSTGRES';
  if (!enabled) {
    test(
      'basic land aliases require the disposable PostgreSQL gate',
      () {},
      skip: 'Run through scripts/manaloom_local_ci.sh schema.',
    );
    return;
  }

  late Pool pool;
  const plainsId = 'a0000000-0000-4000-8000-000000000001';
  const mountainId = 'a0000000-0000-4000-8000-000000000002';

  setUpAll(() {
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
  });

  tearDownAll(() => pool.close());

  test(
    'resolves Plains and Mountain against duplicated canonical face names',
    () async {
      await pool.execute(
        Sql.named('''
          INSERT INTO cards (
            id, scryfall_id, name, type_line, colors, color_identity
          ) VALUES
            (
              CAST(@plains_id AS uuid),
              'b0000000-0000-4000-8000-000000000001'::uuid,
              'Plains // Plains',
              'Basic Land — Plains',
              ARRAY[]::text[],
              ARRAY['W']::text[]
            ),
            (
              CAST(@mountain_id AS uuid),
              'b0000000-0000-4000-8000-000000000002'::uuid,
              'Mountain // Mountain',
              'Basic Land — Mountain',
              ARRAY[]::text[],
              ARRAY['R']::text[]
            )
          ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            type_line = EXCLUDED.type_line
        '''),
        parameters: {'plains_id': plainsId, 'mountain_id': mountainId},
      );
      addTearDown(
        () => pool.execute(
          Sql.named('''
            DELETE FROM cards
            WHERE id IN (
              CAST(@plains_id AS uuid),
              CAST(@mountain_id AS uuid)
            )
          '''),
          parameters: {'plains_id': plainsId, 'mountain_id': mountainId},
        ),
      );

      final resolved = await loadBasicLandIds(pool, const [
        'Plains',
        'Mountain',
      ]);

      expect(resolved, {'Mountain': mountainId, 'Plains': plainsId});
    },
  );
}
