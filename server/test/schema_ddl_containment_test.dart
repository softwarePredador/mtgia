import 'dart:io';

import 'package:test/test.dart';

/// BT-DB-004: o schema só muda por migration (`bin/migrate.dart`) e pelo gate
/// de schema. Este auditor varre todos os entrypoints que podem falar com o
/// PostgreSQL e falha em qualquer DDL persistente fora da lista abaixo.
///
/// Entram `server/bin`, `server/lib`, `server/routes`, `server/sql`,
/// `scripts` e os scripts Hermes que abrem conexão com o PostgreSQL. Fora do
/// alcance ficam: tabela TEMP (some no fim da sessão), linhas de comentário e
/// os scripts Hermes que só usam o SQLite do laboratório. Cada exceção diz por
/// que existe e quantos DDL tem: um DDL novo num arquivo da lista também falha.
void main() {
  final repo = Directory('..').absolute.path;

  const scannedDirectories = [
    'server/bin',
    'server/lib',
    'server/routes',
    'server/sql',
    'scripts',
    _hermesScripts,
  ];
  const extensions = {'.dart', '.py', '.sh', '.sql', '.ps1'};

  final ddl = RegExp(
    r'\b(?:CREATE\s+(?:OR\s+REPLACE\s+)?(?:UNIQUE\s+)?(?:MATERIALIZED\s+)?'
    r'(?:TABLE|INDEX|VIEW|TRIGGER|FUNCTION|PROCEDURE|EXTENSION|SCHEMA|SEQUENCE'
    r'|TYPE|RULE|POLICY|DOMAIN)\b'
    r'|ALTER\s+(?:TABLE|INDEX|VIEW|SEQUENCE|SCHEMA|TYPE|FUNCTION|DOMAIN'
    r'|MATERIALIZED\s+VIEW)\b'
    r'|DROP\s+(?:TABLE|INDEX|VIEW|TRIGGER|FUNCTION|PROCEDURE|EXTENSION|SCHEMA'
    r'|SEQUENCE|TYPE|DOMAIN|MATERIALIZED\s+VIEW)\b'
    r'|TRUNCATE\b)',
    caseSensitive: false,
  );
  final temporaryTable = RegExp(
    r'CREATE\s+(?:LOCAL\s+)?TEMP(?:ORARY)?\s+TABLE',
    caseSensitive: false,
  );
  final postgresClient = RegExp(
    r'psycopg2|psycopg\b|asyncpg|\bpsql\b|with_new_server_pg',
  );
  final commentLine = RegExp(r'^\s*(?:#|//|--|\*|/\*)');

  String code(String text) => text
      .split('\n')
      .map((line) => commentLine.hasMatch(line) ? '' : line)
      .join('\n');

  int ddlCount(String text) {
    final source = code(text);
    return ddl
        .allMatches(source)
        .where(
          (match) => temporaryTable.matchAsPrefix(source, match.start) == null,
        )
        .length;
  }

  Map<String, int> scan() {
    final found = <String, int>{};
    for (final directory in scannedDirectories) {
      final root = Directory('$repo/$directory');
      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path.substring(repo.length + 1);
        if (path.contains('/.dart_tool/') ||
            path.contains('/build/') ||
            path.contains('/__pycache__/') ||
            path.contains('/node_modules/')) {
          continue;
        }
        if (!extensions.any(path.endsWith)) continue;
        final text = entity.readAsStringSync();
        if (path.startsWith('$_hermesScripts/') &&
            (path.split('/').last.startsWith('test_') ||
                !postgresClient.hasMatch(text))) {
          continue;
        }
        final count = ddlCount(text);
        if (count > 0) found[path] = count;
      }
    }
    return found;
  }

  final found = scan();

  test('nenhum entrypoint executa DDL persistente fora da lista', () {
    final unexpected = {
      for (final MapEntry(key: path, value: count) in found.entries)
        if (!_allowed.containsKey(path)) path: count,
    };
    expect(
      unexpected,
      isEmpty,
      reason:
          'DDL fora de migration: mova para bin/migrate.dart ou troque por '
          'requireSchemaObjects (lib/schema_requirements.dart).',
    );
  });

  test('cada exceção existe, tem motivo e o número exato de DDL', () {
    for (final MapEntry(key: path, value: rule) in _allowed.entries) {
      final (expected, reason) = rule;
      expect(reason.trim(), isNotEmpty, reason: path);
      expect(
        found,
        contains(path),
        reason: '$path não tem mais DDL: tire da lista',
      );
      if (expected != null) {
        expect(found[path], expected, reason: path);
      }
      if (reason.startsWith('SQLite')) {
        expect(
          File('$repo/$path').readAsStringSync(),
          contains('sqlite3'),
          reason: path,
        );
      }
    }
  });

  test('sync_state tem um único DDL, no database_setup.sql', () {
    final createSyncState = RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?sync_state\s*\(',
      caseSensitive: false,
    );
    final owners = <String>[
      for (final path
          in [
            ...found.keys,
            'server/database_setup.sql',
            for (final directory in scannedDirectories)
              for (final entity in Directory(
                '$repo/$directory',
              ).listSync(recursive: true))
                if (entity is File &&
                    extensions.any(entity.path.endsWith) &&
                    !entity.path.contains('/.dart_tool/'))
                  entity.path.substring(repo.length + 1),
          ].toSet())
        if (createSyncState.hasMatch(
          code(File('$repo/$path').readAsStringSync()),
        ))
          path,
    ];
    expect(owners, ['server/database_setup.sql']);
  });

  test('os pacotes SQL arquivados são só os 47 da D-48', () {
    final archive = Directory('$repo/$_packageArchive');
    final withDdl = <String>{
      for (final entity in archive.listSync())
        if (entity is File &&
            entity.path.endsWith('.sql') &&
            ddlCount(entity.readAsStringSync()) > 0)
          entity.path.split('/').last,
    };
    expect(withDdl, _archivedPackages);
    expect(_archivedPackages, hasLength(47));
  });

  test('database_indexes.sql foi aposentado (D-48)', () {
    expect(File('$repo/server/database_indexes.sql').existsSync(), isFalse);
  });
}

const _hermesScripts = 'docs/hermes-analysis/manaloom-knowledge/scripts';
const _packageArchive = 'docs/hermes-analysis/master_optimizer_reports';

const _sqliteLab =
    'SQLite do laboratório Hermes (knowledge.db), não PostgreSQL';

/// Arquivo -> (número de DDL, ou nulo para qualquer número; motivo).
const _allowed = <String, (int?, String)>{
  'server/bin/migrate.dart': (
    null,
    'o runner de migrations: o único lugar em que o schema do PostgreSQL muda',
  ),
  'server/bin/migration_038_040_isolated_support.dart': (
    1,
    'ledger do ensaio isolado de upgrade das 038-040, num PostgreSQL descartável',
  ),
  'server/bin/sync_prices_mtgjson_fast.dart': (
    2,
    'DROP da tabela TEMP tmp_mtgjson_prices, que some no fim da sessão',
  ),
  'server/bin/sync_rules.dart': (
    1,
    'TRUNCATE de rules para trocar o conteúdo, na transação aprovada por '
        'MANALOOM_CONFIRM_POSTGRES_WRITES; não muda schema',
  ),
  'server/bin/extract_meta_insights.dart': (
    3,
    'TRUNCATE do --full, que exige MANALOOM_CONFIRM_POSTGRES_WRITES antes de '
        'abrir a conexão (D-48)',
  ),
  'server/bin/pull_learning_events.py': (3, _sqliteLab),
  'server/bin/manaloom_battle_rule_focused_evidence.py': (2, _sqliteLab),
  'server/bin/manaloom_battle_rule_promotion_gate.py': (2, _sqliteLab),
  'server/bin/manaloom_battle_rule_review_queue.py': (2, _sqliteLab),
  'server/bin/manaloom_card_data_gap_review.py': (2, _sqliteLab),
  'server/bin/manaloom_new_card_candidate_review.py': (11, _sqliteLab),
  'scripts/manaloom_local_ci.sh': (
    1,
    'SQLite de fixture do gate de contaminação legada (arquivo em RUN_DIR)',
  ),
  '$_hermesScripts/app_ai_knowledge_bridge_audit.py': (
    1,
    'texto procurado no código-fonte da view, não executado',
  ),
  '$_hermesScripts/sync_battle_card_rules_pg.py': (
    2,
    'SQLite do laboratório Hermes (tabela temporária); no PostgreSQL só '
        'confere o schema',
  ),
  '$_hermesScripts/sync_pg_card_metadata_to_hermes.py': (
    3,
    'SQLite do laboratório Hermes; do PostgreSQL só lê',
  ),
  '$_hermesScripts/wincon_pipeline.py': (1, _sqliteLab),
};

/// D-48: os pacotes `*_apply.sql` aplicados à mão ficam no arquivo de
/// evidência e não voltam a ser aplicados. Um pacote novo com DDL falha aqui.
const _archivedPackages = <String>{
  'global_commander_fixture_cleanup_20260715_apply.sql',
  'pg577_etb_library_tutor_creatures_package_apply.sql',
  'pg578_look_library_graveyard_new_server_package_apply.sql',
  'pg579_creature_enters_draw_new_server_package_apply.sql',
  'pg580_oracle_hash_integrity_backfill_new_server_apply.sql',
  'pg581_each_player_sacrifice_new_server_package_apply.sql',
  'pg582_exile_restricted_targets_new_server_apply.sql',
  'pg582_trusted_rule_oracle_hash_backfill_new_server_apply.sql',
  'pg583_primary_sentence_removal_targets_new_server_apply.sql',
  'pg583b_safe_primary_sentence_removal_targets_new_server_apply.sql',
  'pg584_activated_self_sac_destroy_artifact_enchantment_new_server_apply.sql',
  'pg584b_trusted_rule_oracle_hash_backfill_new_server_apply.sql',
  'pg585_attack_self_boost_new_server_package_apply.sql',
  'pg586_static_controlled_trample_new_server_package_apply.sql',
  'pg587_becomes_blocked_self_boost_new_server_package_apply.sql',
  'pg588_limited_activated_self_boost_new_server_package_apply.sql',
  'pg589_damage_each_opponent_new_server_package_apply.sql',
  'pg589b_trusted_oracle_hash_backfill_new_server_apply.sql',
  'pg590_creature_etb_library_pick_new_server_package_apply.sql',
  'pg591_bounce_target_variants_new_server_package_apply.sql',
  'pg592_multi_target_removal_new_server_package_apply.sql',
  'pg592b_trusted_oracle_hash_backfill_new_server_apply.sql',
  'pg593_multi_target_damage_new_server_package_apply.sql',
  'pg594_limited_times_color_choice_mana_new_server_package_apply.sql',
  'pg595_limited_times_any_color_mana_new_server_package_apply.sql',
  'pg596_any_color_mana_rock_alias_new_server_package_apply.sql',
  'pg596b_oracle_hash_backfill_new_server_apply.sql',
  'pg597_pay_life_mana_source_new_server_package_apply.sql',
  'pg598_dynamic_counter_unless_new_server_package_apply.sql',
  'pg599_runtime_closure_new_server_package_apply.sql',
  'pg599_static_count_pt_new_server_apply.sql',
  'pg646_oracle_identity_exceptions_new_server_apply.sql',
  'pg867_birgi_registry_alignment_new_server_package_apply.sql',
  'pg868_grinding_station_runtime_new_server_package_apply.sql',
  'pg869_product_deck_function_tags_new_server_package_apply.sql',
  'pg870_goblins_illegal_card_repair_20260715_apply.sql',
  'pg871_function_tag_false_positive_repair_20260715_apply.sql',
  'pg872_semantic_tag_false_positive_repair_20260715_apply.sql',
  'pg873_sacrifice_outlet_family_reconciliation_20260715_apply.sql',
  'pg874_ramp_family_reconciliation_20260716_apply.sql',
  'pg875_lander_rizzi_reconciliation_20260716_apply.sql',
  'pg876_ronin_ramp_reconciliation_20260716_apply.sql',
  'pg877_ramp_permission_false_positive_reconciliation_20260716_apply.sql',
  'pg878_lorehold_challenger_runtime_completion_20260716_apply.sql',
  'pg879_flashback_exact_runtime_and_cmc_20260716_apply.sql',
  'rule_competing_scope_cleanup_20260714_apply.sql',
  'validation_identity_residue_cleanup_20260714_apply.sql',
};
