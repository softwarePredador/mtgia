// ignore_for_file: avoid_print

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/sql_statement_splitter.dart';

import 'migrate.dart' as migrate;

const _fixtureEmail = 'migration-038-040@isolated.manaloom.invalid';
const _fixtureCardName = 'Migration 038-040 Fixture';

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      !const {
        'prepare-prior',
        'assert-prior',
        'assert-post',
      }.contains(args[0])) {
    stderr.writeln(
      'Uso: dart run bin/migration_038_040_isolated_support.dart '
      '<prepare-prior|assert-prior|assert-post>',
    );
    exitCode = 2;
    return;
  }

  final host = Platform.environment['DB_HOST'] ?? '';
  final database = Platform.environment['DB_NAME'] ?? '';
  if (!migrate.isLoopbackMigrationHost(host) ||
      !database.startsWith('manaloom_s1_migrations_')) {
    stderr.writeln(
      'BLOCKED: helper aceita somente banco descartável '
      'manaloom_s1_migrations_* em host loopback.',
    );
    exitCode = 2;
    return;
  }

  final connection = await Connection.open(
    Endpoint(
      host: host,
      database: database,
      username: Platform.environment['DB_USER'] ?? '',
      password: Platform.environment['DB_PASS'] ?? '',
      port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    switch (args.single) {
      case 'prepare-prior':
        await _preparePriorClone(connection);
      case 'assert-prior':
        await _assertPriorClone(connection);
      case 'assert-post':
        await _assertPostMigration(connection);
    }
    print('${args.single}: PASS');
  } finally {
    await connection.close();
  }
}

Future<void> _preparePriorClone(Connection connection) async {
  await connection.runTx((tx) async {
    for (final version in const ['040', '039', '038']) {
      final migration = migrate.migrations.singleWhere(
        (candidate) => candidate.version == version,
      );
      for (final statement in splitPostgresStatements(migration.down!)) {
        await tx.execute(statement);
      }
    }

    await tx.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await tx.execute('DELETE FROM schema_migrations');
    for (final migration in migrate.migrations.where(
      (candidate) => int.parse(candidate.version) <= 37,
    )) {
      await tx.execute(
        Sql.named('''
          INSERT INTO schema_migrations (version, name)
          VALUES (@version, @name)
        '''),
        parameters: {'version': migration.version, 'name': migration.name},
      );
    }

    await tx.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES ('migration_038_040', @email, 'isolated-not-a-real-password')
        ON CONFLICT (email) DO NOTHING
      '''),
      parameters: {'email': _fixtureEmail},
    );
    await tx.execute(
      Sql.named('''
        INSERT INTO cards (scryfall_id, name, is_reserved)
        VALUES (
          '00000000-0000-4000-8000-000000000040'::uuid,
          @name,
          NULL
        )
        ON CONFLICT (scryfall_id) DO UPDATE SET is_reserved = NULL
      '''),
      parameters: {'name': _fixtureCardName},
    );
    await tx.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format)
        SELECT id, 'Migration 038-040 Deck', 'commander'
        FROM users
        WHERE email = @email
          AND NOT EXISTS (
            SELECT 1 FROM decks WHERE name = 'Migration 038-040 Deck'
          )
      '''),
      parameters: {'email': _fixtureEmail},
    );
  });
  await _assertPriorClone(connection);
}

Future<void> _assertPriorClone(Connection connection) async {
  await _expectScalar(
    connection,
    "SELECT COUNT(*)::int FROM schema_migrations WHERE version <= '037'",
    37,
    'ledger anterior deve conter migrations 001-037',
  );
  await _expectScalar(
    connection,
    "SELECT COUNT(*)::int FROM schema_migrations WHERE version IN ('038','039','040')",
    0,
    'migrations 038-040 não podem estar registradas no clone anterior',
  );
  await _expectScalar(
    connection,
    "SELECT to_regclass('public.privacy_keyring') IS NULL",
    true,
    'privacy_keyring deve estar ausente antes da 038',
  );
  await _expectScalar(
    connection,
    '''
      SELECT NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'decks'
          AND column_name = 'validation_state'
      )
    ''',
    true,
    'validation_state deve estar ausente antes da 039',
  );
  await _expectScalar(
    connection,
    '''
      SELECT is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'cards'
        AND column_name = 'is_reserved'
    ''',
    'YES',
    'is_reserved deve aceitar NULL antes da 040',
  );
}

Future<void> _assertPostMigration(Connection connection) async {
  await _ensurePostFixtures(connection);
  await _expectScalar(
    connection,
    "SELECT COUNT(*)::int FROM schema_migrations WHERE version IN ('038','039','040')",
    3,
    'ledger deve registrar 038-040 exatamente uma vez',
  );
  for (final table in const [
    'post_game_sync_state',
    'account_deletion_receipts',
    'privacy_keyring',
    'privacy_deleted_deck_tombstones',
  ]) {
    await _expectScalar(
      connection,
      "SELECT to_regclass('public.$table') IS NOT NULL",
      true,
      '$table deve existir depois da 038',
    );
  }
  await _expectScalar(
    connection,
    '''
      SELECT COUNT(*)::int
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'decks'
        AND column_name IN (
          'validation_state',
          'validation_reasons',
          'validation_updated_at'
        )
    ''',
    3,
    'colunas de review da 039 devem existir',
  );
  await _expectScalar(
    connection,
    '''
      SELECT is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'cards'
        AND column_name = 'is_reserved'
    ''',
    'NO',
    'is_reserved deve ser NOT NULL depois da 040',
  );
  await _expectScalar(
    connection,
    Sql.named('SELECT is_reserved FROM cards WHERE name = @name'),
    false,
    '040 deve converter NULL preexistente para false',
    parameters: {'name': _fixtureCardName},
  );

  await connection.runTx((tx) async {
    await tx.execute(
      Sql.named('''
        UPDATE decks
        SET validation_state = 'validated',
            validation_reasons = '[]'::jsonb,
            validation_updated_at = CURRENT_TIMESTAMP
        WHERE name = 'Migration 038-040 Deck'
      '''),
    );
    await tx.execute('''
      INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
      SELECT deck.id, card.id, 1, FALSE
      FROM decks deck
      CROSS JOIN cards card
      WHERE deck.name = 'Migration 038-040 Deck'
        AND card.name = '$_fixtureCardName'
      ON CONFLICT (deck_id, card_id)
      DO UPDATE SET quantity = deck_cards.quantity + 1
    ''');
  });
  await _expectScalar(
    connection,
    "SELECT validation_state FROM decks WHERE name = 'Migration 038-040 Deck'",
    'draft',
    'mutação de deck_cards deve invalidar review anterior',
  );
}

Future<void> _ensurePostFixtures(Connection connection) async {
  await connection.runTx((tx) async {
    await tx.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES ('migration_038_040', @email, 'isolated-not-a-real-password')
        ON CONFLICT (email) DO NOTHING
      '''),
      parameters: {'email': _fixtureEmail},
    );
    await tx.execute(
      Sql.named('''
        INSERT INTO cards (scryfall_id, name)
        VALUES ('00000000-0000-4000-8000-000000000040'::uuid, @name)
        ON CONFLICT (scryfall_id) DO NOTHING
      '''),
      parameters: {'name': _fixtureCardName},
    );
    await tx.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format)
        SELECT id, 'Migration 038-040 Deck', 'commander'
        FROM users
        WHERE email = @email
          AND NOT EXISTS (
            SELECT 1 FROM decks WHERE name = 'Migration 038-040 Deck'
          )
      '''),
      parameters: {'email': _fixtureEmail},
    );
  });
}

Future<void> _expectScalar(
  Session session,
  Object query,
  Object expected,
  String message, {
  Map<String, dynamic>? parameters,
}) async {
  final result = await session.execute(query, parameters: parameters);
  final actual = result.isEmpty ? null : result.first[0];
  if (actual != expected) {
    throw StateError('$message: esperado=$expected atual=$actual');
  }
}
