@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/cards/resolve/index.dart' as resolve_route;
import 'support/lote_database.dart';
import 'support/scripted_pool.dart';

/// BT-CAT-01 / D-74 (decisão do dono de 2026-10-10, item 22): os sets repetidos só
/// pela caixa são fundidos no lote
/// (`server/sql/lote/d74_dedupe_sets_lower_code.sql`) e a migration 077 cria o
/// índice único em LOWER(code).
///
/// Num PostgreSQL descartável migrado do zero, cada cenário copia o banco e volta a
/// cópia para a 076 (sem o índice e sem a 077 no ledger), como a produção. A 077 roda
/// pelo `bin/migrate.dart` de verdade: com duplicata ela falha fechada e não grava
/// nada; depois do script, aplica. O script roda pelo `psql`, como no lote: a
/// prévia (o padrão) não grava nada, e a gravação (`-v aplicar=1`) exige as
/// contagens da prévia.
///
/// Requer `RUN_LOTE_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// em loopback.
void main() {
  const script = 'd74_dedupe_sets_lower_code.sql';
  final enabled = LoteDatabase.enabled;
  final skip = enabled ? false : LoteDatabase.skipReason;
  late LoteDatabase database;

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

  /// A cópia na 076: sem o índice da 077 e sem a 077 no ledger.
  Future<void> backTo076(LoteCopy copy) async {
    await copy.sql('DROP INDEX uq_sets_code_lower');
    await copy.sql("DELETE FROM schema_migrations WHERE version = '077'");
  }

  /// O `bin/migrate.dart` de verdade contra a cópia.
  Future<ProcessResult> migrate(LoteCopy copy) => Process.run(
    Platform.resolvedExecutable,
    ['run', 'bin/migrate.dart'],
    environment: {
      'DB_HOST': Platform.environment['DB_HOST'] ?? '127.0.0.1',
      'DB_PORT': Platform.environment['DB_PORT'] ?? '5432',
      'DB_USER': Platform.environment['DB_USER']!,
      'DB_PASS': Platform.environment['DB_PASS'] ?? '',
      'DB_NAME': copy.name,
      'ENVIRONMENT': 'development',
      'MANALOOM_CONFIRM_POSTGRES_WRITES': 'I_HAVE_EXPLICIT_APPROVAL',
      'MANALOOM_CONFIRM_LIVE_MUTATIONS': 'I_HAVE_EXPLICIT_APPROVAL',
    },
  );

  Future<bool> has077(LoteCopy copy) async =>
      await copy.count(
        "SELECT COUNT(*) FROM schema_migrations WHERE version = '077'",
      ) ==
      1;

  Future<bool> hasUniqueLowerIndex(LoteCopy copy) async =>
      await copy.count('''
        SELECT COUNT(*)
        FROM pg_index index_row
        WHERE index_row.indexrelid = to_regclass('public.uq_sets_code_lower')
          AND index_row.indisunique
      ''') ==
      1;

  Future<Map<String, Map<String, Object?>>> sets(LoteCopy copy) async => {
    for (final row in await copy.sql('''
      SELECT code, name, to_char(release_date, 'YYYY-MM-DD'), type, block,
             is_online_only
      FROM sets
      ORDER BY code COLLATE "C"
    '''))
      row[0] as String: {
        'name': row[1],
        'release_date': row[2],
        'type': row[3],
        'block': row[4],
        'is_online_only': row[5],
      },
  };

  /// Três grupos repetidos (um com três linhas) e um código sozinho; uma tabela
  /// com chave para `sets.code` em cascata apontando para uma linha que sai; e uma
  /// carta cujo código exato é o de uma linha que sai.
  Future<String> seed(LoteCopy copy) async {
    await copy.sql('''
      INSERT INTO sets (code, name, release_date, type, block, is_online_only) VALUES
        ('ABC', 'Alpha Beta (MTGJSON)', '2020-01-01', NULL, 'Bloco A', FALSE),
        ('abc', 'Alpha Beta', '2020-01-01', 'expansion', NULL, NULL),
        ('XYZ', 'Xis', '2019-05-05', 'core', 'Bloco X', TRUE),
        ('xyz', 'Xis novo', '2021-06-06', 'core', NULL, NULL),
        ('Mno', 'Emene 1', NULL, NULL, NULL, NULL),
        ('mno', 'Emene 2', NULL, NULL, NULL, NULL),
        ('MNO', 'Emene 3', NULL, NULL, NULL, NULL),
        ('LEA', 'Limited Edition Alpha', '1993-08-05', 'core', NULL, FALSE)
    ''');
    await copy.sql('''
      CREATE TABLE lote_set_refs (
        id SERIAL PRIMARY KEY,
        set_code TEXT NOT NULL REFERENCES sets(code) ON DELETE CASCADE
      )
    ''');
    await copy.sql(
      "INSERT INTO lote_set_refs (set_code) VALUES ('abc'), ('ABC'), ('Mno')",
    );
    await copy.sql('''
      INSERT INTO cards (scryfall_id, oracle_id, name, set_code, collector_number)
      VALUES (gen_random_uuid(), gen_random_uuid(), 'Carta Lote Alfa', 'abc', '7')
    ''');
    return 'Carta Lote Alfa';
  }

  test(
    'na 076 com duplicata a 077 falha fechada; o script funde e a 077 aplica; '
    'a segunda rodada não muda nada',
    () => withCopy('d74', (copy) async {
      await backTo076(copy);
      final cardName = await seed(copy);

      final refused = await migrate(copy);
      expect(refused.exitCode, isNot(0), reason: '${refused.stdout}');
      expect(
        '${refused.stdout}${refused.stderr}',
        allOf(
          contains('migration 077 recusada'),
          contains('3 código(s)'),
          contains('4 linha(s) a mais'),
          contains('server/sql/lote/d74_dedupe_sets_lower_code.sql'),
        ),
      );
      expect(await has077(copy), isFalse);
      expect(await hasUniqueLowerIndex(copy), isFalse);
      expect(await copy.count('SELECT COUNT(*) FROM sets'), 8);

      final untouched = await copy.fingerprint();
      final preview = await copy.runScript(script);
      expect(preview.exitCode, 0, reason: '$preview');
      expect(preview.previewRolledBack, isTrue, reason: '$preview');
      expect(preview.value('acao', 'linhas_apagadas'), '4');
      expect(preview.value('depois', 'codigos_duplicados'), '0');
      expect(await copy.fingerprint(), untouched);
      final expected = {
        for (final key in const [
          'referencias_levadas_para_a_linha_que_fica',
          'linhas_que_ficam_com_campo_herdado',
          'linhas_apagadas',
        ])
          key: preview.value('acao', key),
      };
      await expectApplyRefusals(
        copy,
        script,
        expected: expected,
        refusal: 'd74 recusado',
      );

      final first = await copy.applyScript(script, expected: expected);
      expect(first.exitCode, 0, reason: '$first');
      expect(first.appliedCommitted, isTrue, reason: '$first');
      expect(first.value('antes', 'sets'), '8');
      expect(first.value('antes', 'codigos_sem_caixa'), '4');
      expect(first.value('antes', 'codigos_duplicados'), '3');
      expect(first.value('antes', 'linhas_a_mais'), '4');
      expect(first.value('antes', 'chaves_estrangeiras_para_sets'), '1');
      expect(
        first.value('antes', 'cartas_com_codigo_exato_de_linha_que_sai'),
        '1',
      );
      expect(
        first.value('acao', 'referencias_levadas_para_a_linha_que_fica'),
        '2',
      );
      expect(first.value('acao', 'linhas_que_ficam_com_campo_herdado'), '2');
      expect(first.value('acao', 'linhas_apagadas'), '4');
      expect(first.value('depois', 'sets'), '4');
      expect(first.value('depois', 'codigos_sem_caixa'), '4');
      expect(first.value('depois', 'codigos_duplicados'), '0');

      // Fica a linha que as leituras já mostravam, com o que faltava herdado.
      expect(await sets(copy), {
        'ABC': {
          'name': 'Alpha Beta (MTGJSON)',
          'release_date': '2020-01-01',
          'type': 'expansion',
          'block': 'Bloco A',
          'is_online_only': false,
        },
        'LEA': {
          'name': 'Limited Edition Alpha',
          'release_date': '1993-08-05',
          'type': 'core',
          'block': null,
          'is_online_only': false,
        },
        'MNO': {
          'name': 'Emene 3',
          'release_date': null,
          'type': null,
          'block': null,
          'is_online_only': null,
        },
        'xyz': {
          'name': 'Xis novo',
          'release_date': '2021-06-06',
          'type': 'core',
          'block': 'Bloco X',
          'is_online_only': true,
        },
      });
      // A chave em cascata não levou ninguém: as referências foram para a linha
      // que fica antes de a outra sair.
      expect(
        [
          for (final row in await copy.sql(
            'SELECT set_code FROM lote_set_refs ORDER BY id',
          ))
            row[0],
        ],
        ['ABC', 'ABC', 'MNO'],
      );

      final applied = await migrate(copy);
      expect(applied.exitCode, 0, reason: '${applied.stdout}${applied.stderr}');
      expect(await has077(copy), isTrue);
      expect(await hasUniqueLowerIndex(copy), isTrue);
      await expectLater(
        copy.sql("INSERT INTO sets (code, name) VALUES ('lea', 'outra caixa')"),
        throwsA(
          isA<ServerException>().having(
            (error) => error.constraintName,
            'constraintName',
            'uq_sets_code_lower',
          ),
        ),
      );

      // A leitura de carta que comparava o código exato acha o set que ficou.
      final resolved = await resolve_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/cards/resolve'),
            body: jsonEncode({'name': cardName}),
          ),
          providers: {Pool: copy.pool()},
        ),
      );
      expect(resolved.statusCode, 200, reason: await resolved.body());
      final card =
          ((jsonDecode(await resolved.body()) as Map)['data'] as List).single
              as Map;
      expect(card['set_code'], 'abc');
      expect(card['set_name'], 'Alpha Beta (MTGJSON)');

      final second = await copy.applyScript(
        script,
        expected: {
          'referencias_levadas_para_a_linha_que_fica': '0',
          'linhas_que_ficam_com_campo_herdado': '0',
          'linhas_apagadas': '0',
        },
      );
      expect(second.exitCode, 0, reason: '$second');
      expect(second.value('antes', 'linhas_a_mais'), '0');
      expect(second.value('acao', 'linhas_apagadas'), '0');
      expect(second.value('acao', 'linhas_que_ficam_com_campo_herdado'), '0');
      expect(second.value('depois', 'sets'), '4');
    }),
    skip: skip,
  );

  test(
    'chave para sets que não é de uma coluna para sets.code recusa e não muda '
    'nada',
    () => withCopy('d74_chave_composta', (copy) async {
      await backTo076(copy);
      await seed(copy);
      await copy.sql(
        'ALTER TABLE sets ADD CONSTRAINT lote_sets_code_name UNIQUE (code, name)',
      );
      await copy.sql('''
        CREATE TABLE lote_set_pairs (
          set_code TEXT,
          set_name TEXT,
          FOREIGN KEY (set_code, set_name) REFERENCES sets (code, name)
        )
      ''');
      final before = await sets(copy);

      final refused = await copy.runScript(script);
      expect(refused.exitCode, isNot(0), reason: '$refused');
      expect(refused.stderr, contains('d74 recusado'));
      expect(await sets(copy), before);
    }),
    skip: skip,
  );

  test(
    'no banco novo a 077 já está aplicada e o script não muda nada',
    () => withCopy('d74_novo', (copy) async {
      expect(await has077(copy), isTrue);
      expect(await hasUniqueLowerIndex(copy), isTrue);
      final run = await copy.runScript(script);
      expect(run.exitCode, 0, reason: '$run');
      expect(run.value('antes', 'codigos_duplicados'), '0');
      expect(run.value('acao', 'linhas_apagadas'), '0');
    }),
    skip: skip,
  );
}
