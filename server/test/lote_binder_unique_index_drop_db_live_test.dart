@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import '../routes/binder/index.dart' as binder_route;
import 'support/lote_database.dart';
import 'support/release_capability_matrix.dart';
import 'support/schema_adoption.dart';
import 'support/scripted_pool.dart';

/// Decisão do dono de 2026-10-10, item 9: o lote tira da produção o índice
/// `uq_binder_user_card_cond_foil_list`
/// (`server/sql/lote/binder_drop_uq_binder_user_card_cond_foil_list.sql`).
///
/// Num PostgreSQL descartável migrado do zero, cada cenário copia o banco e põe
/// nele o índice com a definição da auditoria BT-DB-001. O `POST /binder` roda de
/// verdade: com o índice, a mesma carta em outro idioma dá 500; depois do script,
/// ela entra (201), e a mesma cópia física continua barrada pela identidade da
/// 049 (409). O script roda pelo `psql`, como no lote: a prévia (o padrão) não
/// grava nada, e a gravação (`-v aplicar=1`) exige a contagem da prévia; ela roda
/// duas vezes.
///
/// Requer `RUN_LOTE_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// em loopback.
void main() {
  const script = 'binder_drop_uq_binder_user_card_cond_foil_list.sql';
  final enabled = LoteDatabase.enabled;
  final skip = enabled ? false : LoteDatabase.skipReason;
  late LoteDatabase database;
  final productionIndex = productionOnlyIndexes(
    loadSchemaAudit(),
  )[pendingBinderUniqueIndex]!.replaceFirst(
    'CREATE UNIQUE INDEX ON ',
    'CREATE UNIQUE INDEX $pendingBinderUniqueIndex ON ',
  );

  setUpAll(() {
    if (enabled) database = LoteDatabase.open();
  });

  Future<T> withCopy<T>(
    String label,
    Future<T> Function(LoteCopy copy) body,
  ) async {
    final copy = await database.copy(label);
    try {
      return await body(copy);
    } finally {
      await copy.drop();
    }
  }

  Future<({String user, String card})> seed(LoteCopy copy) async {
    final user = await insertLoteUser(copy, 'lote_fichario');
    final card = (await copy.sql('''
      INSERT INTO cards (scryfall_id, oracle_id, name, set_code, collector_number)
      VALUES (gen_random_uuid(), gen_random_uuid(), 'Carta do fichário', 'tst', '1')
      RETURNING id::text
    ''')).single[0] as String;
    return (user: user, card: card);
  }

  /// O `POST /binder` de verdade, com o banco da cópia.
  Future<Response> post(
    LoteCopy copy,
    ({String user, String card}) owner,
    String language,
  ) => binder_route.onRequest(
    ScriptedRequestContext(
      Request.post(
        Uri.parse('http://localhost/binder'),
        body: jsonEncode({
          'card_id': owner.card,
          'condition': 'NM',
          'is_foil': false,
          'language': language,
          'list_type': 'have',
        }),
      ),
      providers: {
        String: owner.user,
        Pool: copy.pool(),
        ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(const {}),
      },
    ),
  );

  Future<List<String>> languages(LoteCopy copy) async => [
    for (final row in await copy.sql(
      'SELECT language FROM user_binder_items ORDER BY language',
    ))
      row[0] as String,
  ];

  test('o índice do teste é o da auditoria da produção', () {
    expect(
      productionIndex,
      'CREATE UNIQUE INDEX $pendingBinderUniqueIndex ON public.user_binder_items '
      'USING btree (user_id, card_id, condition, is_foil, list_type)',
    );
  });

  test(
    'com o índice da produção o POST /binder de outro idioma dá 500; depois do '
    'script ele entra, a identidade da 049 continua e a segunda rodada não muda '
    'nada',
    () => withCopy('binder', (copy) async {
      await copy.sql(productionIndex);
      final owner = await seed(copy);
      expect((await post(copy, owner, 'en')).statusCode, 201);

      // O defeito da produção: 23505 fora do ON CONFLICT da rota.
      expect((await post(copy, owner, 'pt-br')).statusCode, 500);
      expect(await languages(copy), ['en']);

      final untouched = await copy.fingerprint();
      final preview = await copy.runScript(script);
      expect(preview.exitCode, 0, reason: '$preview');
      expect(preview.previewRolledBack, isTrue, reason: '$preview');
      expect(preview.actionCounts, {'indices_removidos': '1'});
      expect(preview.value('depois', 'uq_binder_user_card_cond_foil_list'), '0');
      expect(await copy.fingerprint(), untouched);
      expect((await post(copy, owner, 'pt-br')).statusCode, 500);
      await expectApplyRefusals(
        copy,
        script,
        expected: preview.actionCounts,
        refusal: 'binder_drop recusado',
      );

      final first = await copy.applyScript(
        script,
        expected: preview.actionCounts,
      );
      expect(first.exitCode, 0, reason: '$first');
      expect(first.appliedCommitted, isTrue, reason: '$first');
      expect(first.value('antes', 'uq_binder_user_card_cond_foil_list'), '1');
      expect(first.value('antes', 'uq_user_binder_items_physical_identity'), '1');
      expect(first.value('antes', 'itens_do_fichario'), '1');
      expect(first.value('antes', 'copias_em_mais_de_um_idioma'), '0');
      expect(first.value('antes', 'itens_com_language_nulo'), '0');
      expect(first.value('acao', 'indices_removidos'), '1');
      expect(first.value('depois', 'uq_binder_user_card_cond_foil_list'), '0');
      expect(first.value('depois', 'uq_user_binder_items_physical_identity'), '1');
      expect(first.value('depois', 'itens_do_fichario'), '1');

      final created = await post(copy, owner, 'pt-br');
      expect(created.statusCode, 201, reason: await created.body());
      expect(await languages(copy), ['en', 'pt-br']);
      // A mesma cópia física cai no ON CONFLICT da 049.
      final repeated = await post(copy, owner, 'pt-br');
      expect(repeated.statusCode, 409);
      expect(
        jsonDecode(await repeated.body()),
        containsPair('code', 'binder_item_identity_conflict'),
      );

      final second = await copy.applyScript(
        script,
        expected: {'indices_removidos': '0'},
      );
      expect(second.exitCode, 0, reason: '$second');
      expect(second.value('antes', 'uq_binder_user_card_cond_foil_list'), '0');
      expect(second.value('antes', 'copias_em_mais_de_um_idioma'), '1');
      expect(second.value('acao', 'indices_removidos'), '0');
      expect(second.value('depois', 'itens_do_fichario'), '2');
    }),
    skip: skip,
  );

  test(
    'conta os itens com language nulo, que a identidade da 049 não barra',
    () => withCopy('binder_language_nulo', (copy) async {
      await copy.sql(productionIndex);
      final owner = await seed(copy);
      // A produção ainda aceita language nulo (D-67).
      await copy.sql(
        'ALTER TABLE user_binder_items ALTER COLUMN language DROP NOT NULL',
      );
      await copy.sql(
        '''
        INSERT INTO user_binder_items (user_id, card_id, condition, language)
        VALUES (CAST(@user AS uuid), CAST(@card AS uuid), 'NM', NULL),
               (CAST(@user AS uuid), CAST(@card AS uuid), 'LP', 'en'),
               (CAST(@user AS uuid), CAST(@card AS uuid), 'MP', 'pt')
        ''',
        {'user': owner.user, 'card': owner.card},
      );

      final preview = await copy.runScript(script);
      expect(preview.exitCode, 0, reason: '$preview');
      expect(preview.value('antes', 'itens_com_language_nulo'), '1');
      expect(preview.value('depois', 'itens_com_language_nulo'), '1');
      expect(preview.value('antes', 'itens_do_fichario'), '3');

      final applied = await copy.applyScript(
        script,
        expected: {'indices_removidos': '1'},
      );
      expect(applied.exitCode, 0, reason: '$applied');
      expect(applied.value('depois', 'itens_com_language_nulo'), '1');
      // Sem o índice antigo, a mesma cópia com language nulo entra de novo.
      await copy.sql(
        '''
        INSERT INTO user_binder_items (user_id, card_id, condition, language)
        VALUES (CAST(@user AS uuid), CAST(@card AS uuid), 'NM', NULL)
        ''',
        {'user': owner.user, 'card': owner.card},
      );
      expect(
        await copy.count(
          'SELECT COUNT(*) FROM user_binder_items WHERE language IS NULL',
        ),
        2,
      );
    }),
    skip: skip,
  );

  test(
    'sem a identidade física da 049, recusa e não remove nada',
    () => withCopy('binder_sem_049', (copy) async {
      await copy.sql(productionIndex);
      await copy.sql('DROP INDEX uq_user_binder_items_physical_identity');

      final refused = await copy.runScript(script);
      expect(refused.exitCode, isNot(0), reason: '$refused');
      expect(refused.stderr, contains('binder_drop recusado'));
      expect(
        await copy.count(
          "SELECT COUNT(*) FROM pg_class WHERE relname = '$pendingBinderUniqueIndex'",
        ),
        1,
      );
    }),
    skip: skip,
  );

  test(
    'um índice com o mesmo nome e outra definição não é removido',
    () => withCopy('binder_outro_indice', (copy) async {
      await copy.sql(
        'CREATE UNIQUE INDEX $pendingBinderUniqueIndex ON user_binder_items '
        '(user_id, card_id, condition, is_foil, language, list_type)',
      );

      final refused = await copy.runScript(script);
      expect(refused.exitCode, isNot(0), reason: '$refused');
      expect(refused.stderr, contains('não é o índice da auditoria'));
      expect(
        await copy.count(
          "SELECT COUNT(*) FROM pg_class WHERE relname = '$pendingBinderUniqueIndex'",
        ),
        1,
      );
    }),
    skip: skip,
  );
}
