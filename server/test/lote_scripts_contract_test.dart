import 'dart:io';

import 'package:test/test.dart';

/// Contrato dos scripts do lote de deploy (`server/sql/lote/`), sem banco: cada
/// escrita roda numa transação pelo wrapper de escrita, para no primeiro erro,
/// conta antes e depois e nunca apaga em cascata; a leitura roda numa transação
/// só de leitura. A escrita é prévia por padrão (faz tudo e desfaz com ROLLBACK);
/// só grava com `-v aplicar=1` e a contagem esperada de cada objeto da ação
/// (`-v esperado_<objeto>=<n>`). Objeto auxiliar é temporário e nasce dentro da
/// transação. O comportamento de cada um contra um PostgreSQL descartável está nos
/// testes `lote_*_db_live_test.dart`.
void main() {
  const readOnlyScripts = {'d85_5a_legacy_ruling_poststatus_archive.sql'};

  /// Cada script de escrita e os objetos da ação que a gravação exige como
  /// `-v esperado_<objeto>=<n>`.
  const writeScripts = {
    'binder_drop_uq_binder_user_card_cond_foil_list.sql': {'indices_removidos'},
    'd74_dedupe_sets_lower_code.sql': {
      'referencias_levadas_para_a_linha_que_fica',
      'linhas_que_ficam_com_campo_herdado',
      'linhas_apagadas',
    },
    'd85_1_deck_description_generate_prompt.sql': {'descricoes_limpas'},
    'd85_2_orphan_public_deck_reports.sql': {'orfaos_publicos_apagados'},
    'd85_3_activation_event_legacy_metadata.sql': {'eventos_limpos'},
    'd85_4_three_checks_not_valid_validate.sql': {
      'checks_criados_not_valid',
      'checks_validados',
    },
    'd85_5b_drop_legacy_ruling_poststatus.sql': {'objetos_apagados'},
  };

  final directory = Directory('sql/lote');
  final files = {
    for (final entity in directory.listSync())
      if (entity is File && entity.path.endsWith('.sql'))
        entity.uri.pathSegments.last: entity.readAsStringSync(),
  };

  /// O texto sem as linhas de comentário (`--`).
  String code(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('--'))
      .join('\n');

  test('a pasta tem só os scripts conhecidos', () {
    expect(
      files.keys,
      unorderedEquals({...readOnlyScripts, ...writeScripts.keys}),
    );
  });

  for (final name in writeScripts.keys) {
    test('$name: escrita em transação, com contagem e sem cascata', () {
      final source = files[name]!;
      final body = code(source);
      expect(source, contains('with_new_server_pg.sh --write-approved psql'));
      expect(source, contains('-v ON_ERROR_STOP=1'));
      expect(body, contains(r'\set ON_ERROR_STOP on'));
      expect(body, contains('BEGIN;'));
      expect(body, contains('COMMIT;'));
      expect(body.indexOf('BEGIN;'), lessThan(body.lastIndexOf('COMMIT;')));
      expect(body, contains("'antes' AS fase"));
      expect(body, contains("'depois' AS fase"));
      expect(body, contains("SET LOCAL lock_timeout"));
      expect(body.toUpperCase(), isNot(contains('CASCADE')));
    });

    test('$name: prévia por padrão; grava só com -v aplicar=1 e as contagens '
        'esperadas', () {
      final source = files[name]!;
      final body = code(source);
      final firstBegin = body.indexOf('BEGIN;');
      // Sem -v aplicar, o padrão é 0 (prévia), conferido antes de qualquer trava.
      expect(body, contains('\\if :{?aplicar}\n\\else\n\\set aplicar 0\n\\endif'));
      expect(body, contains("SET LOCAL manaloom.lote_aplicar = :'aplicar';"));
      expect(body, contains("NOT IN ('0', '1')"));
      expect(body, contains('AS lote_grava \\gset'));
      expect(body.indexOf('AS lote_grava'), greaterThan(firstBegin));
      final lock = body.indexOf('LOCK TABLE');
      if (lock >= 0) {
        expect(body.indexOf('AS lote_grava'), lessThan(lock));
      }
      // Todo COMMIT é do ramo de gravação; a prévia termina em ROLLBACK.
      final commits = RegExp(r'^COMMIT;$', multiLine: true).allMatches(body);
      expect(commits, isNotEmpty);
      for (final commit in commits) {
        final before = body.substring(0, commit.start);
        expect(
          before.trimRight().endsWith('\\if :lote_grava'),
          isTrue,
          reason: 'COMMIT fora do ramo de gravação em ${commit.start}',
        );
      }
      expect(
        body,
        contains(
          '\\if :lote_grava\nCOMMIT;\n'
          "SELECT 'modo' AS fase, 'desfecho' AS objeto, 'commit' AS quantidade;\n"
          '\\else\nROLLBACK;\n'
          "SELECT 'modo' AS fase, 'desfecho' AS objeto, 'rollback' AS quantidade;\n"
          '\\endif',
        ),
      );
      expect(body.trimRight(), endsWith('\\endif'));
      // Cada objeto da ação tem a sua contagem esperada, documentada no
      // cabeçalho e conferida no corpo.
      for (final target in writeScripts[name]!) {
        expect(source, contains('esperado_$target='), reason: target);
        expect(body, contains('\\if :{?esperado_$target}'), reason: target);
        expect(body, contains("'acao' AS fase, '$target' AS objeto"),
            reason: target);
      }
      expect(source, contains('-v aplicar=1'));
      expect(source.toLowerCase(), contains('prévia'));
    });

    test('$name: objeto auxiliar só temporário e dentro da transação', () {
      final body = code(files[name]!);
      final upper = body.toUpperCase();
      final firstBegin = body.indexOf('BEGIN;');
      for (final create in RegExp(r'CREATE\s+(\w+)').allMatches(upper)) {
        expect(create.group(1), 'TEMP', reason: 'CREATE sem TEMP: ${create[0]}');
        expect(create.start, greaterThan(firstBegin),
            reason: 'objeto temporário fora da transação');
      }
      // A view temporária sai antes do fim; a tabela temporária sai no COMMIT.
      for (final view in RegExp(r'CREATE TEMP VIEW (\w+)').allMatches(body)) {
        expect(body, contains('DROP VIEW ${view.group(1)};'));
      }
      for (final table
          in RegExp(r'CREATE TEMP TABLE (\w+)( ON COMMIT DROP)?').allMatches(body)) {
        expect(table.group(2), isNotNull, reason: table.group(1));
      }
    });
  }

  for (final name in readOnlyScripts) {
    test('$name: só leitura', () {
      final source = files[name]!;
      final body = code(source);
      expect(source, contains('with_new_server_pg.sh --read-only psql'));
      expect(body, contains('READ ONLY'));
      expect(body, contains('ROLLBACK;'));
      expect(body, isNot(contains('COMMIT')));
      for (final verb in const ['INSERT ', 'UPDATE ', 'DELETE ', 'DROP ', 'ALTER ']) {
        expect(body.toUpperCase(), isNot(contains(verb)), reason: verb);
      }
    });
  }

  test('d85_4: cada CHECK nasce NOT VALID e, na gravação, só é validado numa '
      'segunda transação, depois de contar zero violações', () {
    final body = code(files['d85_4_three_checks_not_valid_validate.sql']!);
    final notValid = RegExp(r'\) NOT VALID;').allMatches(body).toList();
    expect(notValid, hasLength(3));
    final refusal = body.indexOf('d85_4 recusado');
    final validate = body.indexOf('VALIDATE CONSTRAINT');
    expect(refusal, greaterThan(0));
    expect(validate, greaterThan(0));
    for (final match in notValid) {
      expect(refusal, lessThan(match.start));
      expect(match.start, lessThan(validate));
    }
    final firstCommit = body.indexOf('COMMIT;', notValid.last.end);
    expect(firstCommit, greaterThan(notValid.last.end));
    expect(body.indexOf('BEGIN;', firstCommit), lessThan(validate));
    // A troca de transação é só da gravação; na prévia tudo é uma transação.
    expect(
      body.substring(notValid.last.end, validate),
      contains('\\if :lote_grava\nCOMMIT;\nBEGIN;\n\\endif'),
    );
  });

  test('D-118: a contagem da origem do Generate só lê, e a correção 1 diz '
      'que na produção o esperado é 0', () {
    final source = File(
      'sql/readonly/d85_1_generate_origin_count.sql',
    ).readAsStringSync();
    final body = code(source);
    expect(source, contains('with_new_server_pg.sh --read-only psql'));
    expect(body, contains('BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;'));
    expect(body.trimRight(), endsWith('ROLLBACK;'));
    expect(body, isNot(contains('COMMIT')));
    for (final verb in const [
      'INSERT ',
      'UPDATE ',
      'DELETE ',
      'DROP ',
      'ALTER ',
      'CREATE ',
      'TRUNCATE ',
    ]) {
      expect(body.toUpperCase(), isNot(contains(verb)), reason: verb);
    }
    for (final result in const [
      'sem_marca:',
      'com_marca_sem_deck:',
      "'com_marca: '",
      "'coluna_de_origem_em_decks: '",
    ]) {
      expect(body, contains(result), reason: result);
    }
    final correction = files['d85_1_deck_description_generate_prompt.sql']!;
    expect(correction, contains('Na produção, o esperado é achar 0 (D-118)'));
    expect(
      correction,
      contains('server/sql/readonly/d85_1_generate_origin_count.sql'),
    );
  });

  test('d85_4: um CHECK com o nome certo só conta com a definição esperada, '
      'a mesma que o script cria', () {
    final body = code(files['d85_4_three_checks_not_valid_validate.sql']!);
    expect(body, contains('pg_get_constraintdef(restricao.oid)'));
    expect(body, contains("' NOT VALID\$'"));
    expect(body, contains("THEN 'definicao_divergente'"));
    expect(body, contains('já existe restrição com o nome e outra definição'));
    // A recusa pela definição vem antes de qualquer ADD CONSTRAINT.
    expect(
      body.indexOf('outra definição'),
      lessThan(body.indexOf('ADD CONSTRAINT')),
    );
  });

  test('d74: a fusão de campos vai inteira para o receipt e o script roda '
      'antes da primeira migration', () {
    final source = files['d74_dedupe_sets_lower_code.sql']!;
    final body = code(source);
    expect(body, contains("'campo_herdado:' || campo.nome"));
    expect(body, contains("SELECT 'fusao' AS fase"));
    expect(body, contains("'saem=' || fusao.saem || ';herda='"));
    expect(source, contains('antes da primeira migration e fora da janela'));
    expect(source, isNot(contains('na janela das migrations')));
  });

  test('binder_drop: conta os itens com language nulo', () {
    final body = code(
      files['binder_drop_uq_binder_user_card_cond_foil_list.sql']!,
    );
    expect(body, contains("'itens_com_language_nulo'"));
    expect(body, contains('WHERE language IS NULL'));
  });

  test('d85_5: o passo b recalcula o mesmo arquivo do passo a', () {
    final archive = code(files['d85_5a_legacy_ruling_poststatus_archive.sql']!);
    final drop = code(files['d85_5b_drop_legacy_ruling_poststatus.sql']!);
    for (final fragment in const [
      "'objeto', 'public.poststatus'",
      "'tipo', 'enum'",
      'json_agg(enum_row.enumlabel ORDER BY enum_row.enumsortorder)',
      "'objeto', 'public.card_rulings_legacy'",
      "'linha', row_to_json(registro)",
      'COLLATE "C"',
    ]) {
      expect(archive, contains(fragment), reason: fragment);
      expect(drop, contains(fragment), reason: fragment);
    }
    expect(drop, contains('arquivo_sha256'));
    expect(drop, contains('arquivo_linhas'));
  });
}
