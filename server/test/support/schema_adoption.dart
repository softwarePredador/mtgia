import 'dart:convert';
import 'dart:io';

import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../../bin/migrate.dart' as migrate;
import 'migration_sql.dart';

/// BT-DB-004: o que as migrations 063 a 065 adotam vem da saída da auditoria
/// de schema BT-DB-001 (2026-09-23), lida pelos testes estático e de banco.
const auditOutputPath =
    '../docs/qa/execution/2026-09-23/BT-DB-001-auditoria-de-schema.saida.json';

/// Consulta só de leitura que a coordenação roda na produção (D-67).
const d67NullCountsPath = 'sql/readonly/d67_not_null_null_counts.sql';

/// A D-67 manda os seis `UNIQUE` que só a produção tinha virarem migration.
/// Este fica de fora, pendente de decisão do dono: não tem `language` e, na
/// produção, recusa a mesma carta em outro idioma, que a 049 (identidade
/// física da cópia, ADR 0008) permite e a rota `POST /binder` trata pelo
/// `ON CONFLICT` da identidade física.
const pendingBinderUniqueIndex = 'uq_binder_user_card_cond_foil_list';

/// Os índices do `server/database_indexes.sql`, aposentado pela D-48. A D-48
/// manda virar migration os que a produção tem; os outros saem com o arquivo.
const retiredDatabaseIndexesSql = {
  'idx_battle_sim_created',
  'idx_battle_sim_type',
  'idx_battle_simulations_deck_a',
  'idx_battle_simulations_deck_b',
  'idx_battle_simulations_winner',
  'idx_binder_marketplace_available_created',
  'idx_binder_user_list_name_filters',
  'idx_card_legalities_format_status',
  'idx_card_legalities_lookup',
  'idx_cards_colors',
  'idx_cards_lower_name',
  'idx_cards_name_trgm',
  'idx_cards_type_line_trgm',
  'idx_conversations_user_a_last',
  'idx_conversations_user_b_last',
  'idx_deck_cards_card_id',
  'idx_deck_cards_composite',
  'idx_deck_cards_deck_id',
  'idx_decks_format',
  'idx_decks_user_id',
  'idx_direct_messages_conversation_created',
  'idx_direct_messages_unread_by_conversation',
  'idx_meta_decks_format',
  'idx_meta_decks_name_trgm',
  'idx_notifications_user_created',
  'idx_notifications_user_unread_created',
  'idx_price_history_date_card_price',
  'idx_trade_history_offer_created',
  'idx_trade_items_offer_direction',
  'idx_trade_messages_offer_created',
  'idx_trade_offers_receiver_status_updated',
  'idx_trade_offers_receiver_updated',
  'idx_trade_offers_sender_status_updated',
  'idx_trade_offers_sender_updated',
  'idx_users_email',
  'idx_users_username',
};

Map<String, dynamic> loadSchemaAudit() =>
    jsonDecode(File(auditOutputPath).readAsStringSync())
        as Map<String, dynamic>;

/// Índice -> definição da produção (`CREATE ... INDEX ON public.t ...`, sem o
/// nome), só dos que existem só na produção em tabelas que os dois bancos têm.
Map<String, String> productionOnlyIndexes(Map<String, dynamic> audit) {
  final differences = audit['diferencas'] as Map;
  final extraTables = {
    for (final item in (differences['tabelas'] as Map)['sobrando'] as List)
      item is String ? item : (item as Map)['objeto'] as String,
  };
  return {
    for (final item in (differences['indices'] as Map)['sobrando'] as List)
      if (!extraTables.contains((item as Map)['alvo']['tabela']))
        (item['objeto'] as String).split('.').last:
            item['alvo']['definicao'] as String,
  };
}

/// A definição de uma view na auditoria: `VIEW: ` + `pg_get_viewdef(oid, true)`.
String auditedView(Map<String, dynamic> audit, String view, String side) {
  final views = (audit['diferencas'] as Map)['views'] as Map;
  final divergent = (views['divergente'] as List).cast<Map>().singleWhere(
    (item) => item['objeto'] == 'public.$view',
  );
  return divergent[side] as String;
}

/// Índice -> definição no formato da auditoria, de cada statement do `up`.
Map<String, String> adoptedIndexes(String version) {
  final statement = RegExp(
    r'^CREATE (UNIQUE )?INDEX IF NOT EXISTS (\w+) ON (\w+ USING .+)$',
  );
  final adopted = <String, String>{};
  for (final sql in splitPostgresStatements(migrationUp(version))) {
    final match = statement.firstMatch(sql);
    expect(match, isNotNull, reason: '$version: $sql');
    adopted[match!.group(2)!] =
        'CREATE ${match.group(1) ?? ''}INDEX ON public.${match.group(3)}';
  }
  return adopted;
}

/// Os statements da consulta D-67, sem as linhas de comentário.
List<String> d67Statements(String sql) =>
    splitPostgresStatements(sql)
        .map(
          (statement) =>
              statement
                  .split('\n')
                  .where((line) => !line.trimLeft().startsWith('--'))
                  .join('\n')
                  .trim(),
        )
        .where((statement) => statement.isNotEmpty)
        .toList();

/// Índices do `down`, na ordem.
List<String> droppedIndexes(String version) {
  final down = migrate.migrations.singleWhere((m) => m.version == version).down;
  return [
    for (final sql in splitPostgresStatements(down!))
      RegExp(r'^DROP INDEX IF EXISTS (\w+)$').firstMatch(sql)!.group(1)!,
  ];
}
