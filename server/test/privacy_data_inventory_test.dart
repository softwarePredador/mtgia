import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// BT-PRIV-003: o inventário de retenção
/// (`docs/privacy/data_retention_inventory.json`) tem de cobrir o schema real.
///
/// O schema vem de `project_logic_manifest.json#/database`, que o gerador de
/// project logic extrai de `server/database_setup.sql`, de
/// `server/bin/migrate.dart` e das constantes SQL do backend. O gate `tbls`
/// confere esse manifesto contra um PostgreSQL descartável migrado, e
/// `privacy_data_inventory_db_live_test.dart` confere o inventário direto no
/// `information_schema`. Uma tabela ou coluna nova sem classificação falha
/// aqui antes do commit.
void main() {
  final inventory = _readJson('../docs/privacy/data_retention_inventory.json');
  final manifest = _readJson('../project_logic_manifest.json');
  final database = manifest['database'] as Map<String, dynamic>;
  final schemaTables = <String, Set<String>>{
    for (final table in (database['tables'] as List).cast<Map>())
      table['name'] as String: {
        for (final column in (table['columns'] as List).cast<Map>())
          column['name'] as String,
      },
  };
  final schemaViews = (database['views'] as List).cast<String>().toSet();
  final relations = (database['relations'] as List).cast<Map>();

  final tables = (inventory['tables'] as Map).cast<String, Map>();
  final vocabulary = inventory['vocabulary'] as Map<String, dynamic>;
  final categories = (vocabulary['category'] as List).cast<String>().toSet();
  final subjectKinds =
      (vocabulary['subject_kind'] as List).cast<String>().toSet();
  final retentionClasses =
      (vocabulary['retention_class'] as List).cast<String>().toSet();
  final deletionModes =
      (vocabulary['deletion_mode'] as List).cast<String>().toSet();
  final columnExports =
      (vocabulary['column_export'] as Map).cast<String, String>().keys.toSet();
  final decisions = (inventory['decisions'] as Map).cast<String, String>();

  group('inventário de retenção x schema versionado', () {
    test('cada tabela do schema tem entrada e não há entrada órfã', () {
      final missing = schemaTables.keys.toSet().difference(tables.keys.toSet());
      final orphan = tables.keys.toSet().difference(schemaTables.keys.toSet());
      expect(missing, isEmpty, reason: 'tabelas sem classificação');
      expect(orphan, isEmpty, reason: 'entradas sem tabela no schema');
    });

    test('cada entrada usa o vocabulário e diz finalidade, dono, prazo, '
        'exportação e exclusão', () {
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        final reason = 'tabela $name';
        expect(categories, contains(entry['category']), reason: reason);
        expect(subjectKinds, contains(entry['subject_kind']), reason: reason);
        expect(entry['personal_data'], isA<bool>(), reason: reason);
        expect(_text(entry['purpose']), isNotEmpty, reason: reason);
        expect(_text(entry['owner']), isNotEmpty, reason: reason);

        final retention = entry['retention'] as Map;
        expect(retentionClasses, contains(retention['class']), reason: reason);
        expect(_text(retention['period']), isNotEmpty, reason: reason);

        final deletion = entry['deletion'] as Map;
        expect(deletionModes, contains(deletion['mode']), reason: reason);

        final export = entry['export'] as Map;
        final section = export['section'];
        if (section == null) {
          expect(
            _text(export['reason']),
            isNotEmpty,
            reason: '$reason fora da exportação precisa dizer por quê',
          );
        }
        if (entry['personal_data'] == false) {
          expect(section, isNull, reason: reason);
        }
      }
    });

    test('tabela com dado de conta tem vínculo com o titular e prazo que '
        'não é de catálogo', () {
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        if (entry['subject_kind'] != 'account_holder') continue;
        expect(entry['personal_data'], isTrue, reason: name);
        expect(_text(entry['subject_link']), isNotEmpty, reason: name);
        expect(
          (entry['retention'] as Map)['class'],
          isNot('not_personal'),
          reason: name,
        );
        expect(
          (entry['deletion'] as Map)['mode'],
          isNot('not_personal'),
          reason: name,
        );
      }
    });

    test('tabela exportada classifica exatamente as colunas do schema', () {
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        final section = (entry['export'] as Map)['section'];
        if (section == null) {
          expect(entry.containsKey('columns'), isFalse, reason: name);
          continue;
        }
        final columns = (entry['columns'] as Map).cast<String, String>();
        final declared = columns.keys.toSet();
        final real = schemaTables[name]!;
        expect(
          real.difference(declared),
          isEmpty,
          reason: 'colunas de $name sem classificação',
        );
        expect(
          declared.difference(real),
          isEmpty,
          reason: 'colunas de $name que não existem no schema',
        );
        for (final MapEntry(key: column, value: disposition)
            in columns.entries) {
          expect(columnExports, contains(disposition), reason: '$name.$column');
        }
      }
    });

    test('segredos, hashes e fingerprints nunca são exportados', () {
      final forbidden = RegExp(
        r'^password_hash$|token|fingerprint|(^|_)hash(_|$)|signature'
        r'|^idempotency_key$|^lease_|^cache_key$|^request_key$',
      );
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        final columns = (entry['columns'] as Map?)?.cast<String, String>();
        if (columns == null) continue;
        for (final MapEntry(key: column, value: disposition)
            in columns.entries) {
          if (!forbidden.hasMatch(column)) continue;
          expect(
            disposition,
            startsWith('omit_'),
            reason: '$name.$column não pode sair na exportação',
          );
        }
      }
    });

    test('seções de exportação não se repetem', () {
      final sections = <String>[
        for (final entry in tables.values)
          if ((entry['export'] as Map)['section'] case final String section)
            section,
      ];
      expect(sections.toSet().length, sections.length);
    });

    test(
      'views do schema estão no inventário e apontam para tabelas reais',
      () {
        final views = (inventory['views'] as Map).cast<String, Map>();
        expect(views.keys.toSet(), schemaViews);
        for (final MapEntry(key: name, value: view) in views.entries) {
          for (final base in (view['base_tables'] as List).cast<String>()) {
            expect(schemaTables, contains(base), reason: 'view $name');
          }
        }
      },
    );

    test('tabelas só da produção continuam fora das migrations', () {
      final productionOnly =
          (inventory['production_only_tables'] as Map).cast<String, Map>();
      expect(productionOnly, isNotEmpty);
      for (final name in productionOnly.keys) {
        expect(
          schemaTables.containsKey(name),
          isFalse,
          reason:
              '$name ganhou migration: mova-a para "tables" e classifique '
              'as colunas',
        );
      }
    });

    test('colunas só da produção continuam fora das migrations', () {
      final productionOnly =
          (inventory['production_only_columns'] as Map).cast<String, Map>();
      expect(productionOnly, contains('ml_prompt_feedback.user_rating'));
      for (final MapEntry(key: target, value: entry)
          in productionOnly.entries) {
        final [table, column] = target.split('.');
        expect(schemaTables, contains(table), reason: target);
        expect(
          schemaTables[table],
          isNot(contains(column)),
          reason: '$target ganhou migration: classifique a coluna na tabela',
        );
        expect(entry['personal_data'], isA<bool>(), reason: target);
        expect(_text(entry['note']), isNotEmpty, reason: target);
      }
    });

    test('cascata aponta para um pai que a exclusão apaga', () {
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        if ((entry['deletion'] as Map)['mode'] != 'cascade') continue;
        final parents = {
          for (final relation in relations)
            if (relation['from_table'] == name) relation['to_table'] as String,
        };
        final deletedParents = parents.where(
          (parent) => const {
            'delete',
            'cascade',
          }.contains((tables[parent]!['deletion'] as Map)['mode']),
        );
        expect(deletedParents, isNotEmpty, reason: name);
      }
    });
  });

  group('inventário x decisões do dono', () {
    test('toda decisão citada existe no registro do inventário', () {
      final cited = <String>{
        for (final entry in tables.values)
          if ((entry['retention'] as Map)['decision'] case final String id) id,
        for (final artifact
            in (inventory['artifacts'] as Map).values.cast<Map>())
          ...(artifact['decisions'] as List).cast<String>(),
        for (final rule in (inventory['decided_retention'] as List).cast<Map>())
          rule['decision'] as String,
      };
      expect(decisions.keys.toSet(), containsAll(cited));
    });

    test('os prazos que o dono já decidiu estão registrados', () {
      final rules = (inventory['decided_retention'] as List).cast<Map>();
      String ruleFor(String decision, String fragment) =>
          rules
              .where(
                (rule) =>
                    rule['decision'] == decision &&
                    _text(rule['rule']).contains(fragment),
              )
              .map((rule) => _text(rule['rule']))
              .single;

      expect(ruleFor('D-23', '24 h'), contains('cache'));
      expect(ruleFor('D-29', '30 dias'), contains('prompt'));
      expect(ruleFor('D-30', '30 dias'), contains('lixeira'));
      expect(ruleFor('D-32', '24 h'), contains('jobs de IA'));
      expect(ruleFor('D-23', 'rotação'), contains('backup'));
    });

    test('cada prazo decidido aponta para tabela, coluna ou artefato real', () {
      final artifacts = (inventory['artifacts'] as Map).keys.toSet();
      for (final rule in (inventory['decided_retention'] as List).cast<Map>()) {
        expect(_text(rule['status']), isNotEmpty, reason: '${rule['rule']}');
        for (final target in (rule['applies_to'] as List).cast<String>()) {
          if (target.startsWith('artifact:')) {
            expect(artifacts, contains(target.substring('artifact:'.length)));
            continue;
          }
          final [table, ...column] = target.split('.');
          expect(schemaTables, contains(table), reason: target);
          if (column.isNotEmpty) {
            expect(
              schemaTables[table],
              contains(column.single),
              reason: target,
            );
          }
        }
      }
    });
  });

  group('inventário x serviço de exclusão', () {
    final service =
        File('lib/user_data_privacy_service.dart').readAsStringSync();

    bool deletes(String table) =>
        RegExp('DELETE FROM\\s+$table\\b').hasMatch(service);
    bool updates(String table) =>
        RegExp('UPDATE\\s+$table\\b').hasMatch(service);

    test('o modo declarado bate com o que o serviço faz', () {
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        final mode = (entry['deletion'] as Map)['mode'];
        switch (mode) {
          case 'delete':
            expect(deletes(name), isTrue, reason: '$name declarada delete');
          case 'anonymize':
            expect(updates(name), isTrue, reason: '$name declarada anonymize');
            expect(deletes(name), isFalse, reason: name);
          case 'keep_legal':
            expect(deletes(name), isFalse, reason: name);
          case 'gap':
            expect(
              deletes(name) || updates(name),
              isFalse,
              reason:
                  '$name é tratada pelo serviço: atualize o inventário '
                  '(deletion.mode)',
            );
        }
      }
    });
  });
}

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _text(Object? value) => value is String ? value.trim() : '';
