@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;

/// BT-DB-007 num PostgreSQL descartável migrado do zero
/// (`database_setup.sql` + `bin/migrate.dart`): a trava de conta ativa
/// (`manaloom_active_user_<oid>`, migration 038) em toda chave de uma coluna
/// para `users`, e a 074, que refaz o laço. O banco migrado da produção é
/// simulado com uma chave criada depois do último laço, como a 067 e a 069
/// fizeram. Tudo o que muda o banco roda numa transação desfeita.
///
/// Requer `RUN_SCHEMA_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável em loopback.
void main() {
  final enabled = Platform.environment['RUN_SCHEMA_DB_TESTS'] == '1';
  final skipReason =
      enabled
          ? null
          : 'Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.';
  final migration074 = migrate.migrations.singleWhere(
    (migration) => migration.version == '074',
  );
  late Pool pool;

  setUpAll(() {
    if (!enabled) return;
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    if (!const {'127.0.0.1', 'localhost', '::1'}.contains(host)) {
      throw StateError('RUN_SCHEMA_DB_TESTS só roda em banco loopback: $host');
    }
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: host,
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME']!,
          username: Platform.environment['DB_USER']!,
          password: Platform.environment['DB_PASS'] ?? '',
        ),
      ],
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 1,
      ),
    );
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  /// Roda [body] numa transação que sempre termina em ROLLBACK.
  Future<T> rolledBack<T>(Future<T> Function(Connection connection) body) =>
      pool.withConnection((connection) async {
        await connection.execute('BEGIN');
        try {
          return await body(connection);
        } finally {
          await connection.execute('ROLLBACK');
        }
      });

  Future<void> apply074(Session session) async {
    for (final statement in splitPostgresStatements(migration074.up)) {
      await session.execute(statement);
    }
  }

  /// As chaves de uma coluna para users sem o gatilho de conta ativa com o
  /// OID delas: a mesma leitura do contrato do deploy
  /// (`active_user_triggers`, em scripts/manaloom_deploy_backend_image.sh).
  Future<List<String>> keysWithoutTrigger(Session session) async {
    final result = await session.execute('''
      SELECT constraint_row.conrelid::regclass::text || '.' || attribute_row.attname
      FROM pg_constraint constraint_row
      JOIN pg_attribute attribute_row
        ON attribute_row.attrelid = constraint_row.conrelid
       AND attribute_row.attnum = constraint_row.conkey[1]
      WHERE constraint_row.contype = 'f'
        AND constraint_row.confrelid = 'public.users'::regclass
        AND array_length(constraint_row.conkey, 1) = 1
        AND NOT EXISTS (
          SELECT 1
          FROM pg_trigger trigger_row
          WHERE trigger_row.tgrelid = constraint_row.conrelid
            AND trigger_row.tgname =
              'manaloom_active_user_' || constraint_row.oid::text
            AND trigger_row.tgfoid =
              'public.manaloom_require_active_user()'::regprocedure
            AND trigger_row.tgenabled IN ('O', 'A')
            AND NOT trigger_row.tgisinternal
        )
      ORDER BY 1
    ''');
    return [for (final row in result) row[0] as String];
  }

  /// Nome e definição de cada gatilho de conta ativa do banco.
  Future<Map<String, String>> activeUserTriggers(Session session) async {
    final result = await session.execute('''
      SELECT tgname, pg_get_triggerdef(oid)
      FROM pg_trigger
      WHERE NOT tgisinternal
        AND left(tgname, 21) = 'manaloom_active_user_'
      ORDER BY tgname
    ''');
    return {for (final row in result) row[0] as String: row[1] as String};
  }

  Future<String> insertUser(
    Session session,
    String label, {
    bool deleted = false,
  }) async {
    final result = await session.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash, deleted_at)
        VALUES (@username, @email, 'x',
                ${deleted ? 'CURRENT_TIMESTAMP' : 'NULL'})
        RETURNING id::text
      '''),
      parameters: {
        'username': 'bt_db_007_$label',
        'email': 'bt_db_007_$label@example.invalid',
      },
    );
    return result.single.single as String;
  }

  test('toda chave de uma coluna para users tem o gatilho de conta ativa, com '
      'o OID da chave no nome, a coluna dela e a função da 038', () async {
    expect(await keysWithoutTrigger(pool), isEmpty);
    final result = await pool.execute('''
        SELECT 'manaloom_active_user_' || constraint_row.oid::text,
               format(
                 'CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %I ON %s '
                 'FOR EACH ROW EXECUTE FUNCTION manaloom_require_active_user(%L)',
                 'manaloom_active_user_' || constraint_row.oid::text,
                 attribute_row.attname,
                 constraint_row.conrelid::regclass::text,
                 attribute_row.attname
               )
        FROM pg_constraint constraint_row
        JOIN pg_attribute attribute_row
          ON attribute_row.attrelid = constraint_row.conrelid
         AND attribute_row.attnum = constraint_row.conkey[1]
        WHERE constraint_row.contype = 'f'
          AND constraint_row.confrelid = 'public.users'::regclass
          AND array_length(constraint_row.conkey, 1) = 1
      ''');
    final expected = {
      for (final row in result) row[0] as String: row[1] as String,
    };
    // As 40 chaves do bootstrap de hoje; cada tabela nova só aumenta.
    expect(expected.length, greaterThanOrEqualTo(40));
    final triggers = await activeUserTriggers(pool);
    for (final entry in expected.entries) {
      expect(
        triggers[entry.key]?.replaceFirst(' ON public.', ' ON '),
        entry.value.replaceFirst(' ON public.', ' ON '),
        reason: entry.key,
      );
    }
  }, skip: skipReason);

  test('banco migrado: a chave criada depois do último laço fica sem gatilho e '
      'aceita conta excluída; a 074 põe o gatilho e a trava volta', () async {
    await rolledBack((connection) async {
      // Como a 067 e a 069 no banco migrado: a tabela nasce depois do laço.
      await connection.execute('''
          CREATE TABLE bt_db_007_chave_tardia (
            id BIGSERIAL PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
      expect(await keysWithoutTrigger(connection), [
        'bt_db_007_chave_tardia.user_id',
      ]);
      final active = await insertUser(connection, 'ativa');
      final deleted = await insertUser(connection, 'excluida', deleted: true);
      Future<void> insertRow(String userId) => connection.execute(
        Sql.named(
          'INSERT INTO bt_db_007_chave_tardia (user_id) '
          'VALUES (@user_id::uuid)',
        ),
        parameters: {'user_id': userId},
      );

      // O buraco: sem o gatilho, a linha que aponta para a conta excluída
      // entra.
      await connection.execute('SAVEPOINT antes_da_074');
      await insertRow(deleted);
      await connection.execute('ROLLBACK TO SAVEPOINT antes_da_074');

      await apply074(connection);
      expect(await keysWithoutTrigger(connection), isEmpty);
      await insertRow(active);
      await expectLater(
        insertRow(deleted),
        throwsA(
          isA<ServerException>()
              .having((error) => error.code, 'code', '23503')
              .having(
                (error) => error.message,
                'message',
                'inactive_user_reference',
              ),
        ),
      );
    });
  }, skip: skipReason);

  test('a 074 devolve o gatilho que falta numa chave antiga, com o mesmo nome, '
      'e rodar de novo não duplica nem muda gatilho nenhum', () async {
    await rolledBack((connection) async {
      final before = await activeUserTriggers(connection);
      final key = await connection.execute('''
          SELECT oid::text
          FROM pg_constraint
          WHERE conrelid = 'public.decks'::regclass
            AND contype = 'f'
            AND confrelid = 'public.users'::regclass
        ''');
      final trigger = 'manaloom_active_user_${key.single.single}';
      expect(before, contains(trigger));
      await connection.execute('DROP TRIGGER $trigger ON public.decks');
      expect(await keysWithoutTrigger(connection), ['decks.user_id']);

      await apply074(connection);
      await apply074(connection);
      expect(await activeUserTriggers(connection), before);
      expect(await keysWithoutTrigger(connection), isEmpty);
    });
  }, skip: skipReason);
}
