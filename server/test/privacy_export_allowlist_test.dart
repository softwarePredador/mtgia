import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../lib/privacy/privacy_export_allowlist.dart';
import '../lib/privacy/privacy_export_pseudonymizer.dart';

/// BT-PRIV-001 (D-22): a exportação só leva as colunas que o inventário do
/// BT-PRIV-003 (`docs/privacy/data_retention_inventory.json`) marca para
/// sair, troca IDs de outras pessoas por pseudônimos e tira hashes,
/// fingerprints e chaves internas de qualquer profundidade do JSON.
void main() {
  final inventory =
      jsonDecode(
            File(
              '../docs/privacy/data_retention_inventory.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final tables = (inventory['tables'] as Map).cast<String, Map>();
  final sectionsByTable = {
    for (final section in privacyExportSections) section.table: section,
  };

  const fieldFor = {
    'include': PrivacyExportField.include,
    'include_if_subject_authored': PrivacyExportField.includeIfSubjectAuthored,
    'person_ref': PrivacyExportField.personRef,
    'deck_ref': PrivacyExportField.deckRef,
    'entity_ref': PrivacyExportField.entityRef,
  };

  group('allowlist da exportação x inventário', () {
    test('cada tabela exportada no inventário tem uma seção, e só elas', () {
      final exported = {
        for (final MapEntry(key: name, value: entry) in tables.entries)
          if ((entry['export'] as Map)['section'] != null) name,
      };
      expect(sectionsByTable.keys.toSet(), exported);
      expect(
        privacyExportSections.length,
        sectionsByTable.length,
        reason: 'tabela com duas seções',
      );
    });

    test('caminho e colunas de cada seção batem com o inventário', () {
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        final path = (entry['export'] as Map)['section'];
        if (path == null) continue;
        final section = sectionsByTable[name]!;
        expect(section.path, path, reason: name);
        final expected = {
          for (final MapEntry(key: column, value: disposition)
              in (entry['columns'] as Map).cast<String, String>().entries)
            if (!disposition.startsWith('omit_')) column: fieldFor[disposition],
        };
        expect(section.fields, expected, reason: 'colunas de $name');
      }
    });

    test('coluna condicionada ao autor aponta para coluna real', () {
      for (final section in privacyExportSections) {
        final conditional = section.fields.values.contains(
          PrivacyExportField.includeIfSubjectAuthored,
        );
        if (!conditional) {
          expect(section.authorColumn, isNull, reason: section.path);
          continue;
        }
        final columns = (tables[section.table]!['columns'] as Map).keys;
        expect(columns, contains(section.authorColumn), reason: section.path);
      }
    });

    test('a conta é a primeira seção consultada', () {
      expect(privacyExportSections.first.path, privacyExportAccountPath);
      expect(privacyExportSections.first.single, isTrue);
    });

    test('o SQL de cada seção só lê as colunas da allowlist', () {
      final pair = RegExp(r"'([a-z_]+)', ");
      for (final section in privacyExportSections) {
        final sql = privacyExportSectionSql(section);
        expect(sql, isNot(contains('to_jsonb')), reason: section.path);
        expect(sql, isNot(contains('row_to_json')), reason: section.path);
        expect(sql, isNot(contains('.*')), reason: section.path);
        final select = sql.substring(0, sql.indexOf(' FROM '));
        final keys = {for (final match in pair.allMatches(select)) match[1]!};
        final expected = {
          ...section.fields.keys,
          if (section.cardIdentity) ...{
            privacyExportCardIdentityKey,
            'name',
            'scryfall_id',
            'oracle_id',
            'set_code',
            'collector_number',
          },
        };
        expect(keys, expected, reason: section.path);
        for (final column in section.fields.keys) {
          expect(
            select,
            contains('${section.alias}.$column'),
            reason: '${section.path}.$column',
          );
        }
      }
    });

    test('o serviço não exporta linha inteira nem monta seção fora da '
        'allowlist', () {
      final service =
          File('lib/user_data_privacy_service.dart').readAsStringSync();
      expect(service, isNot(contains('to_jsonb(')));
      expect(service, isNot(contains('row_to_json(')));
      expect(service, contains('privacyExportSections'));
      expect(service, contains('privacyExportSectionSql(section)'));
      expect(service, contains('pseudonymizer.scrub('));
      expect(service, contains('AccessMode.readOnly'));
    });

    test('as chaves proibidas espelham o inventário', () {
      final policy =
          (inventory['export_policy'] as Map)['nested_forbidden_keys'] as Map;
      expect(
        privacyExportForbiddenKeys,
        (policy['exact'] as List).cast<String>().toSet(),
      );
      expect(
        privacyExportForbiddenKeySuffixes.toSet(),
        (policy['suffixes'] as List).cast<String>().toSet(),
      );
    });

    test('o arquivo declara o formato e o que ficou de fora', () {
      expect(privacyExportSchemaVersion, 2);
      expect(
        privacyExportPortability['omitted_secrets'],
        containsAll(['password_hash', 'jwt', 'fcm_token']),
      );
      expect(privacyExportPortability['pseudonymization'], isA<String>());
    });
  });

  group('pseudônimos da exportação', () {
    const subject = 'aaaaaaaa-0000-4000-8000-000000000001';
    const otherPerson = 'bbbbbbbb-0000-4000-8000-000000000002';
    const ownDeck = 'cccccccc-0000-4000-8000-000000000003';
    const otherDeck = 'dddddddd-0000-4000-8000-000000000004';
    const sharedTrade = 'eeeeeeee-0000-4000-8000-000000000005';

    PrivacyExportPseudonymizer pseudonymizer() => PrivacyExportPseudonymizer(
      subjectUserId: subject,
      ownDeckIds: const [ownDeck],
      sharedEntityIds: const [sharedTrade],
    );

    test(
      'o titular e os decks dele ficam; os de terceiros viram pseudônimo',
      () {
        final p = pseudonymizer();
        expect(p.person(subject), subject);
        expect(p.deck(ownDeck), ownDeck);
        expect(p.entity(sharedTrade), sharedTrade);
        final person = p.person(otherPerson)! as String;
        final deck = p.deck(otherDeck)! as String;
        expect(person, startsWith('pessoa-'));
        expect(deck, startsWith('deck-'));
        expect(person, isNot(contains(otherPerson)));
        expect(p.person(null), isNull);
      },
    );

    test('a mesma pessoa tem o mesmo pseudônimo no arquivo inteiro', () {
      final p = pseudonymizer();
      final first = p.person(otherPerson);
      expect(p.person(otherPerson.toUpperCase()), first);
      expect(p.entity(otherPerson), first);
    });

    test('cada exportação usa outra chave: pseudônimos não se ligam entre '
        'arquivos', () {
      expect(
        pseudonymizer().person(otherPerson),
        isNot(pseudonymizer().person(otherPerson)),
      );
    });

    test('scrub tira chaves proibidas em qualquer profundidade', () {
      final p = pseudonymizer();
      final scrubbed =
          p.scrub({
                'result': {
                  'prompt': 'meu prompt',
                  'cache': {'hit': false, 'cache_key': 'ck'},
                  'items': [
                    {'deck_b_hash': 'h', 'request_fingerprint': 'f', 'ok': 1},
                  ],
                },
                'lease_token': 't',
                'idempotency_key': 'k',
              })!
              as Map<String, dynamic>;
      expect(scrubbed, {
        'result': {
          'prompt': 'meu prompt',
          'cache': {'hit': false},
          'items': [
            {'ok': 1},
          ],
        },
      });
    });

    test('scrub troca IDs de terceiros dentro de textos e JSON aninhado', () {
      final p = pseudonymizer();
      final deck = p.deck(otherDeck)! as String;
      final scrubbed =
          p.scrub({
                'game_log': {
                  'deck_b': {'id': otherDeck},
                  'events': ['vence $otherDeck', 'meu deck $ownDeck'],
                },
              })!
              as Map<String, dynamic>;
      final text = jsonEncode(scrubbed);
      expect(text, isNot(contains(otherDeck)));
      expect(text, contains(deck));
      expect(text, contains(ownDeck));
    });
  });
}
