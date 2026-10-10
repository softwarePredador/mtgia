import 'dart:io';

import 'package:test/test.dart';

/// Contrato dos scripts do lote de deploy (`server/sql/lote/`), sem banco: cada
/// escrita roda numa transação pelo wrapper de escrita, para no primeiro erro,
/// conta antes e depois e nunca apaga em cascata; a leitura roda numa transação
/// só de leitura. O comportamento de cada um contra um PostgreSQL descartável
/// está nos testes `lote_*_db_live_test.dart`.
void main() {
  const readOnlyScripts = {'d85_5a_legacy_ruling_poststatus_archive.sql'};
  const writeScripts = {
    'binder_drop_uq_binder_user_card_cond_foil_list.sql',
    'd85_1_deck_description_generate_prompt.sql',
    'd85_2_orphan_public_deck_reports.sql',
    'd85_3_activation_event_legacy_metadata.sql',
    'd85_4_three_checks_not_valid_validate.sql',
    'd85_5b_drop_legacy_ruling_poststatus.sql',
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
    expect(files.keys, unorderedEquals({...readOnlyScripts, ...writeScripts}));
  });

  for (final name in writeScripts) {
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

  test('d85_4: cada CHECK nasce NOT VALID e só é validado numa segunda '
      'transação, depois de contar zero violações', () {
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
