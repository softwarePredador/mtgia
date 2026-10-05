@Tags(['live', 'live_db_write'])
library;

import 'package:postgres/postgres.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/auth_service.dart';
import '../lib/user_data_privacy_service.dart';
import 'support/privacy_db_fixture.dart';

/// D-66 (BT-PRIV-002) em PostgreSQL descartável.
///
/// A chave `trade_items.owner_id` estava com `ON DELETE CASCADE` na migration
/// 041 e sem ação na produção (BT-DB-001). A 059 a deixa `RESTRICT` nos dois
/// bancos. Este teste reproduz a falha que a auditoria achou na produção (um
/// `DELETE` direto na linha de `users` de quem tem item de troca), mostra o
/// banco novo apagando em silêncio o histórico da outra parte antes da 059 e
/// os dois recusando igual depois dela.
///
/// A exclusão de conta do produto não apaga a linha de `users` (ela
/// pseudonimiza): passa nas três formas da chave e trata os itens como a D-66
/// manda. Oferta aberta é cancelada e perde os itens do titular. Troca
/// concluída fica com a outra pessoa, e o item do titular perde o vínculo com
/// o fichário dele.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = privacyDbTestsEnabled();
  final skipReason = enabled ? null : privacyDbSkipReason;
  const password = 'Senha!Titular-2026';
  late Pool pool;

  final migration059 = migrate.migrations.singleWhere(
    (migration) => migration.version == '059',
  );

  Future<void> setOwnerKey(String action) async {
    await pool.execute(
      'ALTER TABLE trade_items DROP CONSTRAINT trade_items_owner_id_fkey',
    );
    await pool.execute(
      'ALTER TABLE trade_items ADD CONSTRAINT trade_items_owner_id_fkey '
      'FOREIGN KEY (owner_id) REFERENCES users(id) $action',
    );
  }

  Future<void> applyMigration059() async {
    for (final statement in splitPostgresStatements(migration059.up)) {
      await pool.execute(statement);
    }
  }

  /// D recebeu uma oferta de E e só tem o item pedido nela: sem mensagem nem
  /// mudança de status, para isolar a chave de `trade_items.owner_id`.
  Future<({String receiver, String sender, String offer})> seedReceiverOnly(
    String suffix,
  ) async {
    Future<String> one(String sql, Map<String, Object?> parameters) async {
      final result = await pool.execute(Sql.named(sql), parameters: parameters);
      return result.single.single!.toString();
    }

    // Sufixo único por rodada: o banco descartável pode guardar rodadas
    // anteriores, e usuário e e-mail são únicos.
    final run = DateTime.now().microsecondsSinceEpoch;
    Future<String> user(String name) => one(
      '''
      INSERT INTO users (username, email, password_hash)
      VALUES (@username, @email, 'x')
      RETURNING id::text
      ''',
      {
        'username': 'trade_${name}_${suffix}_$run',
        'email': 'trade_${name}_${suffix}_$run@example.invalid',
      },
    );
    final receiver = await user('d');
    final sender = await user('e');
    final offer = await one(
      '''
      INSERT INTO trade_offers (sender_id, receiver_id, status)
      VALUES (CAST(@sender AS uuid), CAST(@receiver AS uuid), 'completed')
      RETURNING id::text
      ''',
      {'sender': sender, 'receiver': receiver},
    );
    await pool.execute(
      Sql.named('''
        INSERT INTO trade_items (trade_offer_id, owner_id, direction)
        VALUES
          (CAST(@offer AS uuid), CAST(@receiver AS uuid), 'requesting'),
          (CAST(@offer AS uuid), CAST(@sender AS uuid), 'offering')
      '''),
      parameters: {'offer': offer, 'receiver': receiver, 'sender': sender},
    );
    return (receiver: receiver, sender: sender, offer: offer);
  }

  /// Apaga direto a linha de `users` numa transação que sempre é desfeita.
  /// Devolve o erro do banco, ou nulo, e o que sobrou da troca da outra parte
  /// antes de desfazer.
  Future<({Object? error, int senderItems})> hardDelete(
    ({String receiver, String sender, String offer}) seeded,
  ) async {
    Object? error;
    var senderItems = -1;
    try {
      await pool.runTx((tx) async {
        await tx.execute(
          Sql.named('DELETE FROM users WHERE id = CAST(@id AS uuid)'),
          parameters: {'id': seeded.receiver},
        );
        final remaining = await tx.execute(
          Sql.named('''
            SELECT COUNT(*)::int FROM trade_items
            WHERE owner_id = CAST(@sender AS uuid)
          '''),
          parameters: {'sender': seeded.sender},
        );
        senderItems = remaining.single.single! as int;
        throw const _Rollback();
      });
    } on _Rollback {
      error = null;
    } catch (exception) {
      error = exception;
    }
    return (error: error, senderItems: senderItems);
  }

  Matcher violatesOwnerKey() => isA<ServerException>()
      .having((error) => error.code, 'code', '23503')
      .having(
        (error) => error.constraintName,
        'constraint',
        'trade_items_owner_id_fkey',
      );

  setUpAll(() async {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = openPrivacyTestPool();
  });

  tearDownAll(() async {
    if (!enabled) return;
    await applyMigration059();
    await pool.close();
  });

  group('chave trade_items.owner_id', () {
    test('a 059 deixa RESTRICT e um só trigger de conta ativa, com o nome '
        'da chave nova, mesmo aplicada de novo', () async {
      // Duas vezes: a segunda troca o OID da chave de novo, e um trigger
      // antigo que ficasse para trás apareceria aqui.
      await applyMigration059();
      await applyMigration059();
      final key = await pool.execute('''
        SELECT oid::text, confdeltype::text
        FROM pg_constraint
        WHERE conrelid = 'public.trade_items'::regclass
          AND conname = 'trade_items_owner_id_fkey'
      ''');
      expect(key.single[1], 'r');
      final triggers = await pool.execute('''
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'public.trade_items'::regclass
          AND NOT tgisinternal
          AND left(tgname, 21) = 'manaloom_active_user_'
      ''');
      expect(
        [for (final row in triggers) row[0]],
        ['manaloom_active_user_${key.single[0]}'],
      );
    }, skip: skipReason);

    test('produção antes da 059 (sem ação): o DELETE direto em users de quem '
        'tem item de troca falha', () async {
      final seeded = await seedReceiverOnly('sem_acao');
      await setOwnerKey('');
      final result = await hardDelete(seeded);
      await applyMigration059();
      expect(result.error, violatesOwnerKey());
    }, skip: skipReason);

    test('banco novo antes da 059 (CASCADE): o mesmo DELETE passa e leva o '
        'histórico da outra parte', () async {
      final seeded = await seedReceiverOnly('cascade');
      await setOwnerKey('ON DELETE CASCADE');
      final result = await hardDelete(seeded);
      await applyMigration059();
      expect(result.error, isNull);
      expect(result.senderItems, 0, reason: 'os itens de E sumiram junto');
    }, skip: skipReason);

    test('com a 059 (RESTRICT): os dois bancos recusam igual', () async {
      final seeded = await seedReceiverOnly('restrict');
      await applyMigration059();
      final result = await hardDelete(seeded);
      expect(result.error, violatesOwnerKey());
    }, skip: skipReason);
  });

  test('com a chave do fichário sem ação, a exclusão ainda passa: o item de '
      'troca solta o fichário do titular antes', () async {
    final fixture = await PrivacyDbFixture.seed(
      pool,
      passwordHash: AuthService().hashPassword(password),
    );
    Future<void> setBinderKey(String action) async {
      await pool.execute(
        'ALTER TABLE trade_items DROP CONSTRAINT trade_items_binder_item_id_fkey',
      );
      await pool.execute(
        'ALTER TABLE trade_items ADD CONSTRAINT trade_items_binder_item_id_fkey '
        'FOREIGN KEY (binder_item_id) REFERENCES user_binder_items(id) $action',
      );
    }

    await setBinderKey('');
    try {
      await UserDataPrivacyService(
        pool,
      ).deleteAndAnonymizeAccount(userId: fixture.userA, password: password);
    } finally {
      await setBinderKey('ON DELETE SET NULL');
    }
    final item = await pool.execute(
      Sql.named('''
        SELECT binder_item_id FROM trade_items WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': fixture.itemOfAInCompletedTrade},
    );
    expect(item.single.single, isNull);
  }, skip: skipReason);

  for (final shape
      in const {
        'sem ação (produção antes da 059)': '',
        'CASCADE (banco novo antes da 059)': 'ON DELETE CASCADE',
        'RESTRICT (059)': null,
      }.entries) {
    test('a exclusão do produto passa com a chave ${shape.key} e trata os '
        'itens de troca (D-66)', () async {
      final fixture = await PrivacyDbFixture.seed(
        pool,
        passwordHash: AuthService().hashPassword(password),
      );
      if (shape.value == null) {
        await applyMigration059();
      } else {
        await setOwnerKey(shape.value!);
      }
      try {
        await UserDataPrivacyService(
          pool,
        ).deleteAndAnonymizeAccount(userId: fixture.userA, password: password);
      } finally {
        await applyMigration059();
      }

      Future<Map<String, String?>> statusOf(List<String> offers) async {
        final rows = await pool.execute(
          Sql.named('''
            SELECT id::text, status FROM trade_offers
            WHERE id = ANY(CAST(@ids AS uuid[]))
          '''),
          parameters: {'ids': offers},
        );
        return {for (final row in rows) row[0]! as String: row[1] as String?};
      }

      Future<Map<String, Map<String, dynamic>>> items(List<String> ids) async {
        final rows = await pool.execute(
          Sql.named('''
            SELECT id::text, owner_id::text AS owner, binder_item_id::text AS binder
            FROM trade_items
            WHERE id = ANY(CAST(@ids AS uuid[]))
          '''),
          parameters: {'ids': ids},
        );
        return {
          for (final row in rows)
            row.toColumnMap()['id'] as String: row.toColumnMap(),
        };
      }

      final status = await statusOf([
        fixture.tradeFromA,
        fixture.tradeFromB,
        fixture.tradeCompletedAB,
      ]);
      expect(status[fixture.tradeFromA], 'cancelled');
      expect(status[fixture.tradeFromB], 'cancelled');
      expect(status[fixture.tradeCompletedAB], 'completed');

      final kept = await items([
        fixture.itemOfAInOpenOfferFromA,
        fixture.itemOfBInOpenOfferFromA,
        fixture.itemOfAInOpenOfferFromB,
        fixture.itemOfBInOpenOfferFromB,
        fixture.itemOfAInCompletedTrade,
        fixture.itemOfBInCompletedTrade,
      ]);
      expect(
        kept.keys.toSet(),
        {
          fixture.itemOfBInOpenOfferFromA,
          fixture.itemOfBInOpenOfferFromB,
          fixture.itemOfAInCompletedTrade,
          fixture.itemOfBInCompletedTrade,
        },
        reason: 'itens de A nas ofertas abertas saem; o resto fica',
      );
      expect(kept[fixture.itemOfAInCompletedTrade]!['binder'], isNull);
      expect(kept[fixture.itemOfAInCompletedTrade]!['owner'], fixture.userA);
      expect(kept[fixture.itemOfBInCompletedTrade]!['owner'], fixture.userB);

      final history = await pool.execute(
        Sql.named('''
          SELECT trade_offer_id::text, old_status, new_status, notes
          FROM trade_status_history
          WHERE trade_offer_id = ANY(CAST(@ids AS uuid[]))
            AND new_status = 'cancelled'
          ORDER BY trade_offer_id
        '''),
        parameters: {
          'ids': [fixture.tradeFromA, fixture.tradeFromB],
        },
      );
      expect(history, hasLength(2));
      for (final row in history) {
        expect(row[1], 'pending');
        expect(row[3], openTradeOfferCancelledNote);
      }

      final receipt = await pool.execute('''
        SELECT retention_summary FROM account_deletion_receipts
        ORDER BY completed_at DESC LIMIT 1
      ''');
      expect(receipt.single[0], containsPair('open_trade_offers', 'cancelled'));
    }, skip: skipReason);
  }
}

class _Rollback implements Exception {
  const _Rollback();
}
