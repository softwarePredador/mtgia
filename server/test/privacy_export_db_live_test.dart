@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/privacy/privacy_export_allowlist.dart';
import '../lib/privacy/privacy_export_pseudonymizer.dart';
import '../lib/user_data_privacy_service.dart';
import 'support/privacy_db_fixture.dart';

/// BT-PRIV-001 (D-22) em PostgreSQL descartável: a exportação de A, com
/// dado de A, B e C em todas as tabelas exportadas, sai completa, só com as
/// colunas da allowlist, sem hash nem fingerprint, sem ID cru nem texto de
/// outra pessoa, e sem gravar nada.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = privacyDbTestsEnabled();
  final skipReason = enabled ? null : privacyDbSkipReason;
  final inventory =
      jsonDecode(
            File(
              '../docs/privacy/data_retention_inventory.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final allTables = (inventory['tables'] as Map).keys.cast<String>().toList();

  late Pool pool;
  late PrivacyDbFixture fixture;
  late Map<String, dynamic> exported;
  late String exportedText;
  late Map<String, int> countsBefore;
  late Map<String, int> countsAfter;

  setUpAll(() async {
    if (!enabled) return;
    pool = openPrivacyTestPool();
    fixture = await PrivacyDbFixture.seed(pool);
    countsBefore = await PrivacyDbFixture.rowCounts(pool, allTables);
    exported = await UserDataPrivacyService(pool).exportUserData(fixture.userA);
    countsAfter = await PrivacyDbFixture.rowCounts(pool, allTables);
    exportedText = jsonEncode(exported);
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  Object? at(String path) {
    Object? node = exported;
    for (final part in path.split('.')) {
      node = (node! as Map)[part];
    }
    return node;
  }

  List<Map<String, dynamic>> rowsAt(String path) =>
      (at(path)! as List).cast<Map<String, dynamic>>();

  test(
    'toda seção do inventário sai no arquivo com as linhas do titular',
    () {
      expect(exported['schema_version'], privacyExportSchemaVersion);
      for (final section in privacyExportSections) {
        final value = at(section.path);
        if (section.single) {
          expect(value, isA<Map>(), reason: section.path);
        } else {
          expect(value, isA<List>(), reason: section.path);
          expect(value as List, isNotEmpty, reason: section.path);
        }
      }
    },
    skip: skipReason,
  );

  test('cada linha só tem colunas da allowlist', () {
    for (final section in privacyExportSections) {
      final value = at(section.path);
      final rows = section.single ? [value! as Map] : (value! as List);
      final allowed = {
        ...section.fields.keys,
        if (section.cardIdentity) privacyExportCardIdentityKey,
      };
      for (final row in rows.cast<Map>()) {
        expect(
          allowed.containsAll(row.keys),
          isTrue,
          reason:
              '${section.path} saiu com '
              '${row.keys.toSet().difference(allowed)}',
        );
      }
    }
  }, skip: skipReason);

  test(
    'nenhum hash, fingerprint ou chave interna em qualquer profundidade',
    () {
      final offending = <String>[];
      void visit(Object? value, String path) {
        if (value is Map) {
          for (final MapEntry(:key, :value) in value.entries) {
            if (isPrivacyExportForbiddenKey(key.toString())) {
              offending.add('$path.$key');
            }
            visit(value, '$path.$key');
          }
        } else if (value is List) {
          for (final (index, item) in value.indexed) {
            visit(item, '$path[$index]');
          }
        }
      }

      visit(exported, r'$');
      expect(offending, isEmpty);
      for (final secret in [
        fixture.passwordHash,
        'fcm-que-nao-sai',
        'cache-key-${fixture.suffix}',
        'generate-request-key-${fixture.suffix}',
        PrivacyDbFixture.hex64('generate-fp'),
        PrivacyDbFixture.hex64('job-fp-A'),
        PrivacyDbFixture.hex64('deck-b-A'),
      ]) {
        expect(exportedText, isNot(contains(secret)), reason: secret);
      }
    },
    skip: skipReason,
  );

  test('nenhum ID cru de outra pessoa ou de deck de outra pessoa', () {
    for (final id in [
      fixture.userB,
      fixture.userC,
      fixture.deckB1Public,
      fixture.deckB2Private,
    ]) {
      expect(exportedText.toLowerCase(), isNot(contains(id.toLowerCase())));
    }
    expect(exportedText, contains(fixture.userA));
    expect(exportedText, contains(fixture.deckA1));
  }, skip: skipReason);

  test('nada escrito por outra pessoa sai no arquivo', () {
    for (final text in fixture.textsOfB) {
      expect(exportedText, isNot(contains(text)), reason: text);
    }
    expect(exportedText, contains('mensagem da proposta de A'));
    expect(exportedText, contains('oi de A'));
    expect(exportedText, contains('nota pos-jogo de A'));
  }, skip: skipReason);

  test(
    'a simulação que B rodou contra o deck público de A fica de fora; a de A '
    'sai com o deck de B pseudonimizado',
    () {
      final simulations = rowsAt('data.battle_simulations');
      expect(simulations.map((row) => row['id']), [fixture.simulationByA]);
      expect(exportedText, isNot(contains(fixture.simulationByB)));
      final simulation = simulations.single;
      expect(simulation['deck_a_id'], fixture.deckA1);
      final deckB = simulation['deck_b_id']! as String;
      expect(deckB, startsWith('deck-'));
      expect(jsonEncode(simulation['game_log']), contains(deckB));
      final attempts = rowsAt('data.battle_simulation_attempts');
      expect(attempts.map((row) => row['id']), [fixture.attemptByA]);
      expect(attempts.single['deck_b_id'], deckB);
    },
    skip: skipReason,
  );

  test('a mesma pessoa tem o mesmo pseudônimo em todas as seções', () {
    final follows = rowsAt('data.follows');
    final followed =
        follows.singleWhere(
          (row) => row['follower_id'] == fixture.userA,
        )['following_id'];
    expect(followed, startsWith('pessoa-'));
    final conversation = rowsAt('data.conversations').single;
    expect(
      {conversation['user_a_id'], conversation['user_b_id']},
      {fixture.userA, followed},
    );
    final trade = rowsAt(
      'data.trades',
    ).singleWhere((row) => row['id'] == fixture.tradeFromA);
    expect(trade['receiver_id'], followed);
    final follower = rowsAt(
      'data.notifications',
    ).singleWhere((row) => row['type'] == 'new_follower');
    expect(follower['reference_id'], followed);
    expect(follower.containsKey('title'), isFalse);
    final tradeNotice = rowsAt(
      'data.notifications',
    ).singleWhere((row) => row['type'] == 'trade_offer_received');
    expect(tradeNotice['reference_id'], fixture.tradeFromB);
  }, skip: skipReason);

  test('mensagem da proposta sai só quando o titular a escreveu', () {
    final trades = {for (final row in rowsAt('data.trades')) row['id']: row};
    expect(
      trades[fixture.tradeFromA]!['message'],
      'mensagem da proposta de A ${fixture.suffix}',
    );
    expect(trades[fixture.tradeFromB]!['message'], isNull);
  }, skip: skipReason);

  test('a conta sai com o registro de consentimento e sem segredos', () {
    final account = exported['account'] as Map<String, dynamic>;
    expect(account['id'], fixture.userA);
    expect(account['terms_version'], 'termos-v1');
    expect(account['privacy_version'], 'privacidade-v1');
    expect(account.containsKey('password_hash'), isFalse);
    expect(account.containsKey('fcm_token'), isFalse);
    expect(account.containsKey('auth_version'), isFalse);
    final binder = rowsAt('data.binder_items').single;
    expect(binder.containsKey('card_id'), isFalse);
    expect(
      (binder[privacyExportCardIdentityKey] as Map)['name'],
      startsWith('Carta de teste de privacidade'),
    );
  }, skip: skipReason);

  test('a exportação não grava nada no banco', () {
    expect(countsAfter, countsBefore);
  }, skip: skipReason);

  test('outra exportação troca os pseudônimos', () async {
    final again = await UserDataPrivacyService(
      pool,
    ).exportUserData(fixture.userA);
    String followedIn(Map<String, dynamic> export) =>
        ((export['data'] as Map)['follows'] as List).cast<Map>().singleWhere(
              (row) => row['follower_id'] == fixture.userA,
            )['following_id']
            as String;
    expect(followedIn(again), isNot(followedIn(exported)));
  }, skip: skipReason);
}
