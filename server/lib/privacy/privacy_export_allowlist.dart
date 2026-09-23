/// Allowlist da exportação de dados da conta (BT-PRIV-001, D-22).
///
/// Espelha, coluna a coluna, as tabelas exportadas de
/// `docs/privacy/data_retention_inventory.json` (BT-PRIV-003). Coluna que
/// não está aqui não sai na exportação; coluna nova no schema não entra
/// sozinha. `server/test/privacy_export_allowlist_test.dart` falha se este
/// arquivo e o inventário divergirem.
library;

import 'dart:math' as math;

/// Como cada coluna sai no arquivo exportado.
enum PrivacyExportField {
  /// Sai como está.
  include,

  /// Sai só quando o titular é o autor da linha (`authorColumn`).
  includeIfSubjectAuthored,

  /// UUID de pessoa: mantido se for o titular, pseudônimo se for outra.
  personRef,

  /// UUID de deck: mantido se for do titular, pseudônimo se for de outra
  /// pessoa.
  deckRef,

  /// Referência genérica: mantida se for do titular ou de uma troca ou
  /// conversa de que ele participa; pseudônimo nos demais casos.
  entityRef,
}

class PrivacyExportSection {
  const PrivacyExportSection({
    required this.path,
    required this.table,
    required this.alias,
    required this.where,
    required this.fields,
    this.joins = '',
    this.orderBy,
    this.single = false,
    this.cardIdentity = false,
    this.authorColumn,
  });

  /// Caminho no arquivo exportado, igual ao `export.section` do inventário.
  final String path;
  final String table;
  final String alias;

  /// Filtro do titular; usa o parâmetro `@userId`.
  final String where;
  final Map<String, PrivacyExportField> fields;
  final String joins;
  final String? orderBy;

  /// A seção é um objeto (ou nulo), não uma lista.
  final bool single;

  /// Acrescenta `card_identity` (nome, scryfall_id, oracle_id, set e número)
  /// no lugar do UUID interno do catálogo.
  final bool cardIdentity;
  final String? authorColumn;
}

/// Chave derivada que as seções com `cardIdentity` acrescentam.
const privacyExportCardIdentityKey = 'card_identity';

/// Versão do formato do arquivo. A 2 é a primeira com allowlist e
/// pseudônimos (D-22).
const privacyExportSchemaVersion = 2;

/// Seção da conta; é a primeira consultada, e sem ela a exportação para.
const privacyExportAccountPath = 'account';

/// O que o arquivo declara sobre si mesmo.
const privacyExportPortability = <String, Object>{
  'format': 'application/json',
  'scope': 'dados fornecidos pela conta ou diretamente ligados a ela',
  'storage': 'gerado sob demanda; o servidor não guarda cópia',
  'pseudonymization':
      'IDs de outras pessoas e de decks de outras pessoas aparecem como '
      'pseudônimos (pessoa-, deck-, ref-) que só valem dentro deste arquivo',
  'omitted_secrets': [
    'password_hash',
    'jwt',
    'fcm_token',
    'server_credentials',
    'authentication_token_hashes',
    'hashes_and_fingerprints',
    'cache_and_idempotency_keys',
    'internal_operational_state',
    'internal_catalog_ids',
    'messages_authored_by_other_users',
    'notification_titles_and_bodies',
    'moderator_identities',
  ],
};

/// Seções na ordem em que saem no arquivo.
const privacyExportSections = <PrivacyExportSection>[
  PrivacyExportSection(
    path: 'account',
    table: 'users',
    alias: 'account_row',
    where:
        'account_row.id = CAST(@userId AS uuid) AND account_row.deleted_at IS NULL',
    single: true,
    fields: {
      'avatar_url': PrivacyExportField.include,
      'binder_visibility': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'display_name': PrivacyExportField.include,
      'email': PrivacyExportField.include,
      'email_verified_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'location_city': PrivacyExportField.include,
      'location_state': PrivacyExportField.include,
      'location_visibility': PrivacyExportField.include,
      'message_visibility': PrivacyExportField.include,
      'password_changed_at': PrivacyExportField.include,
      'privacy_accepted_at': PrivacyExportField.include,
      'privacy_version': PrivacyExportField.include,
      'profile_visibility': PrivacyExportField.include,
      'terms_accepted_at': PrivacyExportField.include,
      'terms_version': PrivacyExportField.include,
      'trade_notes': PrivacyExportField.include,
      'trade_notes_visibility': PrivacyExportField.include,
      'trade_visibility': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'username': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.plan',
    table: 'user_plans',
    alias: 'user_plan',
    where: 'user_plan.user_id = CAST(@userId AS uuid)',
    orderBy: 'user_plan.updated_at DESC',
    single: true,
    fields: {
      'plan_name': PrivacyExportField.include,
      'renews_at': PrivacyExportField.include,
      'started_at': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.decks',
    table: 'decks',
    alias: 'deck',
    where: 'deck.user_id = CAST(@userId AS uuid)',
    orderBy: 'deck.created_at, deck.id',
    fields: {
      'archetype': PrivacyExportField.include,
      'bracket': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deleted_at': PrivacyExportField.include,
      'description': PrivacyExportField.include,
      'format': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'is_public': PrivacyExportField.include,
      'name': PrivacyExportField.include,
      'pricing_currency': PrivacyExportField.include,
      'pricing_missing_cards': PrivacyExportField.include,
      'pricing_source': PrivacyExportField.include,
      'pricing_total': PrivacyExportField.include,
      'pricing_updated_at': PrivacyExportField.include,
      'strengths': PrivacyExportField.include,
      'synergy_score': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
      'validation_reasons': PrivacyExportField.include,
      'validation_state': PrivacyExportField.include,
      'validation_updated_at': PrivacyExportField.include,
      'weaknesses': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.deck_cards',
    table: 'deck_cards',
    alias: 'deck_card',
    joins: 'JOIN decks deck ON deck.id = deck_card.deck_id',
    where: 'deck.user_id = CAST(@userId AS uuid)',
    orderBy: 'deck_card.deck_id, deck_card.id',
    cardIdentity: true,
    fields: {
      'condition': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'id': PrivacyExportField.include,
      'is_commander': PrivacyExportField.include,
      'quantity': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.deck_learning_events',
    table: 'deck_learning_events',
    alias: 'learning_event',
    where:
        'learning_event.deck_id IN (SELECT own_deck.id FROM decks own_deck WHERE own_deck.user_id = CAST(@userId AS uuid))',
    orderBy: 'learning_event.created_at, learning_event.id',
    fields: {
      'card_count': PrivacyExportField.include,
      'commander_name': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'event_data': PrivacyExportField.include,
      'format': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'source': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.deck_matchups',
    table: 'deck_matchups',
    alias: 'deck_matchup',
    where:
        'deck_matchup.deck_id IN (SELECT own_deck.id FROM decks own_deck WHERE own_deck.user_id = CAST(@userId AS uuid))',
    orderBy: 'deck_matchup.updated_at, deck_matchup.id',
    fields: {
      'deck_id': PrivacyExportField.deckRef,
      'id': PrivacyExportField.include,
      'notes': PrivacyExportField.include,
      'opponent_deck_id': PrivacyExportField.deckRef,
      'updated_at': PrivacyExportField.include,
      'win_rate': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.deck_weakness_reports',
    table: 'deck_weakness_reports',
    alias: 'weakness_report',
    where:
        'weakness_report.deck_id IN (SELECT own_deck.id FROM decks own_deck WHERE own_deck.user_id = CAST(@userId AS uuid))',
    orderBy: 'weakness_report.created_at, weakness_report.id',
    fields: {
      'addressed': PrivacyExportField.include,
      'auto_detected': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'description': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'recommendations': PrivacyExportField.include,
      'severity': PrivacyExportField.include,
      'weakness_type': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.battle_simulations',
    table: 'battle_simulations',
    alias: 'simulation',
    where:
        'simulation.deck_a_id IN (SELECT own_deck.id FROM decks own_deck WHERE own_deck.user_id = CAST(@userId AS uuid)) OR simulation.id IN (SELECT own_attempt.replay_id FROM battle_simulation_attempts own_attempt WHERE own_attempt.user_id = CAST(@userId AS uuid) AND own_attempt.replay_id IS NOT NULL)',
    orderBy: 'simulation.created_at, simulation.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'deck_a_id': PrivacyExportField.deckRef,
      'deck_b_id': PrivacyExportField.deckRef,
      'game_log': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'metrics': PrivacyExportField.include,
      'simulation_type': PrivacyExportField.include,
      'turns_played': PrivacyExportField.include,
      'winner_deck_id': PrivacyExportField.deckRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.battle_simulation_attempts',
    table: 'battle_simulation_attempts',
    alias: 'attempt',
    where: 'attempt.user_id = CAST(@userId AS uuid)',
    orderBy: 'attempt.started_at, attempt.id',
    fields: {
      'deck_a_id': PrivacyExportField.deckRef,
      'deck_b_id': PrivacyExportField.deckRef,
      'engine': PrivacyExportField.include,
      'engine_build': PrivacyExportField.include,
      'engine_commit': PrivacyExportField.include,
      'engine_version': PrivacyExportField.include,
      'error_code': PrivacyExportField.include,
      'events_truncated': PrivacyExportField.include,
      'finished_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'outcome': PrivacyExportField.include,
      'outcome_reason': PrivacyExportField.include,
      'provenance': PrivacyExportField.include,
      'replay_id': PrivacyExportField.include,
      'request_schema_version': PrivacyExportField.include,
      'simulation_type': PrivacyExportField.include,
      'snapshots_truncated': PrivacyExportField.include,
      'started_at': PrivacyExportField.include,
      'test_objective': PrivacyExportField.include,
      'timeout_ms': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.battle_jobs',
    table: 'battle_jobs',
    alias: 'battle_job',
    where: 'battle_job.user_id = CAST(@userId AS uuid)',
    orderBy: 'battle_job.created_at, battle_job.id',
    fields: {
      'attempt_id': PrivacyExportField.include,
      'cancel_requested_at': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_a_id': PrivacyExportField.deckRef,
      'deck_b_id': PrivacyExportField.deckRef,
      'engine': PrivacyExportField.include,
      'engine_build': PrivacyExportField.include,
      'engine_commit': PrivacyExportField.include,
      'engine_version': PrivacyExportField.include,
      'error_code': PrivacyExportField.include,
      'finished_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'progress_current': PrivacyExportField.include,
      'progress_total': PrivacyExportField.include,
      'replay_id': PrivacyExportField.include,
      'request_schema_version': PrivacyExportField.include,
      'requested_engine': PrivacyExportField.include,
      'schema_version': PrivacyExportField.include,
      'stage': PrivacyExportField.include,
      'started_at': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'terminal_reason': PrivacyExportField.include,
      'timeout_ms': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.battle_live_records',
    table: 'battle_job_live_records',
    alias: 'live_record',
    joins: 'JOIN battle_jobs battle_job ON battle_job.id = live_record.job_id',
    where:
        'battle_job.user_id = CAST(@userId AS uuid) AND live_record.public_visible',
    orderBy: 'live_record.job_id, live_record.sequence',
    fields: {
      'content_truncated': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'job_id': PrivacyExportField.include,
      'kind': PrivacyExportField.include,
      'payload': PrivacyExportField.include,
      'record_id': PrivacyExportField.include,
      'sequence': PrivacyExportField.include,
      'source_truncated': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.interactive_battle_sessions',
    table: 'interactive_battle_sessions',
    alias: 'battle_session',
    where: 'battle_session.user_id = CAST(@userId AS uuid)',
    orderBy: 'battle_session.created_at, battle_session.id',
    fields: {
      'active_prompt': PrivacyExportField.include,
      'attempt_id': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_a_id': PrivacyExportField.deckRef,
      'deck_b_id': PrivacyExportField.deckRef,
      'engine': PrivacyExportField.include,
      'engine_build': PrivacyExportField.include,
      'engine_commit': PrivacyExportField.include,
      'engine_version': PrivacyExportField.include,
      'error_code': PrivacyExportField.include,
      'expires_at': PrivacyExportField.include,
      'finished_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'last_activity_at': PrivacyExportField.include,
      'private_state': PrivacyExportField.include,
      'prompt_deadline_at': PrivacyExportField.include,
      'replay_id': PrivacyExportField.include,
      'request_schema_version': PrivacyExportField.include,
      'schema_version': PrivacyExportField.include,
      'started_at': PrivacyExportField.include,
      'state_version': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'terminal_reason': PrivacyExportField.include,
      'ttl_seconds': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.interactive_battle_records',
    table: 'interactive_battle_records',
    alias: 'interactive_record',
    joins:
        'JOIN interactive_battle_sessions battle_session ON battle_session.id = interactive_record.session_id',
    where:
        "battle_session.user_id = CAST(@userId AS uuid) AND interactive_record.visibility IN ('private_user', 'public_replay_ref')",
    orderBy: 'interactive_record.session_id, interactive_record.sequence',
    fields: {
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'option_id': PrivacyExportField.include,
      'payload': PrivacyExportField.include,
      'prompt_id': PrivacyExportField.include,
      'record_kind': PrivacyExportField.include,
      'schema_version': PrivacyExportField.include,
      'sequence': PrivacyExportField.include,
      'session_id': PrivacyExportField.include,
      'state_version': PrivacyExportField.include,
      'visibility': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.battle_replay_annotations',
    table: 'battle_replay_annotations',
    alias: 'annotation',
    where: 'annotation.user_id = CAST(@userId AS uuid)',
    orderBy: 'annotation.created_at, annotation.id',
    fields: {
      'attempt_id': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'event_ref': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'kind': PrivacyExportField.include,
      'payload': PrivacyExportField.include,
      'replay_id': PrivacyExportField.include,
      'snapshot_ref': PrivacyExportField.include,
      'subject_deck_id': PrivacyExportField.deckRef,
      'subject_deck_key': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.binder_items',
    table: 'user_binder_items',
    alias: 'binder_item',
    where: 'binder_item.user_id = CAST(@userId AS uuid)',
    orderBy: 'binder_item.created_at, binder_item.id',
    cardIdentity: true,
    fields: {
      'condition': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'currency': PrivacyExportField.include,
      'for_sale': PrivacyExportField.include,
      'for_trade': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'is_foil': PrivacyExportField.include,
      'language': PrivacyExportField.include,
      'list_type': PrivacyExportField.include,
      'notes': PrivacyExportField.include,
      'price': PrivacyExportField.include,
      'quantity': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.post_game_notes',
    table: 'post_game_notes',
    alias: 'post_game_note',
    where: 'post_game_note.user_id = CAST(@userId AS uuid)',
    orderBy: 'post_game_note.created_at, post_game_note.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'deck_version_at': PrivacyExportField.include,
      'deleted_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'issues': PrivacyExportField.include,
      'notes': PrivacyExportField.include,
      'performed_well': PrivacyExportField.include,
      'play_session_id': PrivacyExportField.include,
      'result': PrivacyExportField.include,
      'revision': PrivacyExportField.include,
      'session_ended_at': PrivacyExportField.include,
      'session_started_at': PrivacyExportField.include,
      'table_level': PrivacyExportField.include,
      'underperformed': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.shared_deck_reports',
    table: 'shared_deck_reports',
    alias: 'shared_report',
    where: 'shared_report.user_id = CAST(@userId AS uuid)',
    orderBy: 'shared_report.created_at, shared_report.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'description': PrivacyExportField.include,
      'expires_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'is_public': PrivacyExportField.include,
      'payload': PrivacyExportField.include,
      'title': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.comments',
    table: 'deck_comments',
    alias: 'deck_comment',
    where: 'deck_comment.user_id = CAST(@userId AS uuid)',
    orderBy: 'deck_comment.created_at, deck_comment.id',
    fields: {
      'body': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'id': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.follows',
    table: 'user_follows',
    alias: 'user_follow',
    where:
        'user_follow.follower_id = CAST(@userId AS uuid) OR user_follow.following_id = CAST(@userId AS uuid)',
    orderBy: 'user_follow.created_at, user_follow.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'follower_id': PrivacyExportField.personRef,
      'following_id': PrivacyExportField.personRef,
      'id': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.blocks',
    table: 'user_blocks',
    alias: 'user_block',
    where: 'user_block.blocker_id = CAST(@userId AS uuid)',
    orderBy: 'user_block.created_at, user_block.blocked_id',
    fields: {
      'blocked_id': PrivacyExportField.personRef,
      'blocker_id': PrivacyExportField.personRef,
      'created_at': PrivacyExportField.include,
      'reason': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.block_events',
    table: 'user_block_events',
    alias: 'block_event',
    where: 'block_event.actor_user_id = CAST(@userId AS uuid)',
    orderBy: 'block_event.created_at, block_event.id',
    fields: {
      'action': PrivacyExportField.include,
      'actor_user_id': PrivacyExportField.personRef,
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'reason': PrivacyExportField.include,
      'target_user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.activation_events',
    table: 'activation_funnel_events',
    alias: 'activation_event',
    where: 'activation_event.user_id = CAST(@userId AS uuid)',
    orderBy: 'activation_event.created_at, activation_event.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'event_name': PrivacyExportField.include,
      'format': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'metadata': PrivacyExportField.include,
      'source': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.optimization_events',
    table: 'deck_optimization_events',
    alias: 'optimization_event',
    where: 'optimization_event.user_id = CAST(@userId AS uuid)',
    orderBy: 'optimization_event.created_at, optimization_event.id',
    fields: {
      'additions': PrivacyExportField.include,
      'after_snapshot': PrivacyExportField.include,
      'archetype': PrivacyExportField.include,
      'battle_message': PrivacyExportField.include,
      'battle_status': PrivacyExportField.include,
      'before_snapshot': PrivacyExportField.include,
      'bracket': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'event_type': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'intensity': PrivacyExportField.include,
      'mode': PrivacyExportField.include,
      'recommendation_context': PrivacyExportField.include,
      'removals': PrivacyExportField.include,
      'report_payload': PrivacyExportField.include,
      'selected_change_count': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
      'validation_status': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_preferences',
    table: 'ai_user_preferences',
    alias: 'ai_preference',
    where: 'ai_preference.user_id = CAST(@userId AS uuid)',
    orderBy: 'ai_preference.updated_at DESC',
    single: true,
    fields: {
      'budget_tier': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'keep_theme_default': PrivacyExportField.include,
      'playstyle': PrivacyExportField.include,
      'preferred_archetype': PrivacyExportField.include,
      'preferred_bracket': PrivacyExportField.include,
      'preferred_colors': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_activity.logs',
    table: 'ai_logs',
    alias: 'ai_log',
    where: 'ai_log.user_id = CAST(@userId AS uuid)',
    orderBy: 'ai_log.created_at, ai_log.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'endpoint': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'model': PrivacyExportField.include,
      'prompt_summary': PrivacyExportField.include,
      'response_summary': PrivacyExportField.include,
      'success': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_activity.feedback',
    table: 'ml_prompt_feedback',
    alias: 'prompt_feedback',
    where: 'prompt_feedback.user_id = CAST(@userId AS uuid)',
    orderBy: 'prompt_feedback.created_at, prompt_feedback.id',
    fields: {
      'archetype': PrivacyExportField.include,
      'cards_accepted': PrivacyExportField.include,
      'cards_rejected': PrivacyExportField.include,
      'commander_name': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'effectiveness_score': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'user_comment': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_activity.fallback_telemetry',
    table: 'ai_optimize_fallback_telemetry',
    alias: 'fallback_telemetry',
    where: 'fallback_telemetry.user_id = CAST(@userId AS uuid)',
    orderBy: 'fallback_telemetry.created_at, fallback_telemetry.id',
    fields: {
      'applied': PrivacyExportField.include,
      'candidate_count': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'id': PrivacyExportField.include,
      'mode': PrivacyExportField.include,
      'no_candidate': PrivacyExportField.include,
      'no_replacement': PrivacyExportField.include,
      'pair_count': PrivacyExportField.include,
      'recognized_format': PrivacyExportField.include,
      'replacement_count': PrivacyExportField.include,
      'triggered': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_activity.optimize_cache',
    table: 'ai_optimize_cache',
    alias: 'optimize_cache',
    where: 'optimize_cache.user_id = CAST(@userId AS uuid)',
    orderBy: 'optimize_cache.created_at, optimize_cache.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'expires_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'payload': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_activity.generate_jobs',
    table: 'ai_generate_jobs',
    alias: 'generate_job',
    where: 'generate_job.user_id = CAST(@userId AS uuid)',
    orderBy: 'generate_job.created_at, generate_job.id',
    fields: {
      'cancelled_at': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'format': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'result': PrivacyExportField.include,
      'result_status_code': PrivacyExportField.include,
      'stage': PrivacyExportField.include,
      'stage_number': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'total_stages': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.ai_activity.optimize_jobs',
    table: 'ai_optimize_jobs',
    alias: 'optimize_job',
    where: 'optimize_job.user_id = CAST(@userId AS uuid)',
    orderBy: 'optimize_job.created_at, optimize_job.id',
    fields: {
      'archetype': PrivacyExportField.include,
      'cancelled_at': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'deck_id': PrivacyExportField.deckRef,
      'id': PrivacyExportField.include,
      'quality_error': PrivacyExportField.include,
      'result': PrivacyExportField.include,
      'stage': PrivacyExportField.include,
      'stage_number': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'total_stages': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.trades',
    table: 'trade_offers',
    alias: 'trade_offer',
    where:
        'trade_offer.sender_id = CAST(@userId AS uuid) OR trade_offer.receiver_id = CAST(@userId AS uuid)',
    orderBy: 'trade_offer.created_at, trade_offer.id',
    authorColumn: 'sender_id',
    fields: {
      'created_at': PrivacyExportField.include,
      'delivery_method': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'message': PrivacyExportField.includeIfSubjectAuthored,
      'payment_amount': PrivacyExportField.include,
      'payment_currency': PrivacyExportField.include,
      'payment_method': PrivacyExportField.include,
      'receiver_id': PrivacyExportField.personRef,
      'sender_id': PrivacyExportField.personRef,
      'status': PrivacyExportField.include,
      'tracking_code': PrivacyExportField.include,
      'type': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.trade_items',
    table: 'trade_items',
    alias: 'trade_item',
    where: 'trade_item.owner_id = CAST(@userId AS uuid)',
    orderBy: 'trade_item.trade_offer_id, trade_item.id',
    fields: {
      'agreed_price': PrivacyExportField.include,
      'binder_item_id': PrivacyExportField.include,
      'direction': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'item_snapshot': PrivacyExportField.include,
      'owner_id': PrivacyExportField.personRef,
      'quantity': PrivacyExportField.include,
      'snapshot_captured_at': PrivacyExportField.include,
      'snapshot_schema_version': PrivacyExportField.include,
      'snapshot_status': PrivacyExportField.include,
      'trade_offer_id': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.trade_messages',
    table: 'trade_messages',
    alias: 'trade_message',
    where: 'trade_message.sender_id = CAST(@userId AS uuid)',
    orderBy: 'trade_message.created_at, trade_message.id',
    fields: {
      'attachment_type': PrivacyExportField.include,
      'attachment_url': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'message': PrivacyExportField.include,
      'moderation_status': PrivacyExportField.include,
      'sender_id': PrivacyExportField.personRef,
      'trade_offer_id': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.trade_status_history',
    table: 'trade_status_history',
    alias: 'status_change',
    where: 'status_change.changed_by = CAST(@userId AS uuid)',
    orderBy: 'status_change.created_at, status_change.id',
    fields: {
      'changed_by': PrivacyExportField.personRef,
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'new_status': PrivacyExportField.include,
      'notes': PrivacyExportField.include,
      'old_status': PrivacyExportField.include,
      'trade_offer_id': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.conversations',
    table: 'conversations',
    alias: 'conversation',
    where:
        'conversation.user_a_id = CAST(@userId AS uuid) OR conversation.user_b_id = CAST(@userId AS uuid)',
    orderBy: 'conversation.created_at, conversation.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'last_message_at': PrivacyExportField.include,
      'user_a_id': PrivacyExportField.personRef,
      'user_b_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.direct_messages_sent',
    table: 'direct_messages',
    alias: 'direct_message',
    where: 'direct_message.sender_id = CAST(@userId AS uuid)',
    orderBy: 'direct_message.created_at, direct_message.id',
    fields: {
      'conversation_id': PrivacyExportField.include,
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'message': PrivacyExportField.include,
      'moderation_status': PrivacyExportField.include,
      'read_at': PrivacyExportField.include,
      'sender_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.notifications',
    table: 'notifications',
    alias: 'notification',
    where: 'notification.user_id = CAST(@userId AS uuid)',
    orderBy: 'notification.created_at, notification.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'read_at': PrivacyExportField.include,
      'reference_id': PrivacyExportField.entityRef,
      'type': PrivacyExportField.include,
      'user_id': PrivacyExportField.personRef,
    },
  ),
  PrivacyExportSection(
    path: 'data.content_reports',
    table: 'content_reports',
    alias: 'content_report',
    where: 'content_report.reporter_user_id = CAST(@userId AS uuid)',
    orderBy: 'content_report.created_at, content_report.id',
    fields: {
      'created_at': PrivacyExportField.include,
      'details': PrivacyExportField.include,
      'evidence': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'reason': PrivacyExportField.include,
      'reporter_user_id': PrivacyExportField.personRef,
      'resolution': PrivacyExportField.include,
      'resolution_action': PrivacyExportField.include,
      'reviewed_at': PrivacyExportField.include,
      'status': PrivacyExportField.include,
      'target_id': PrivacyExportField.entityRef,
      'target_type': PrivacyExportField.include,
      'updated_at': PrivacyExportField.include,
    },
  ),
  PrivacyExportSection(
    path: 'data.content_report_appeals',
    table: 'content_report_appeals',
    alias: 'report_appeal',
    where: 'report_appeal.appellant_user_id = CAST(@userId AS uuid)',
    orderBy: 'report_appeal.created_at, report_appeal.id',
    fields: {
      'appellant_user_id': PrivacyExportField.personRef,
      'created_at': PrivacyExportField.include,
      'id': PrivacyExportField.include,
      'reason': PrivacyExportField.include,
      'report_id': PrivacyExportField.include,
      'resolution': PrivacyExportField.include,
      'reviewed_at': PrivacyExportField.include,
      'status': PrivacyExportField.include,
    },
  ),
];

const _maxPairsPerObject = 40;

/// SQL da seção: `jsonb_build_object` só com as colunas da allowlist. Em
/// grupos de até 40 pares, abaixo do limite de 100 argumentos do
/// PostgreSQL, unidos por `||`.
String privacyExportSectionSql(PrivacyExportSection section) {
  final alias = section.alias;
  final pairs = <String>[
    for (final MapEntry(key: column, value: field) in section.fields.entries)
      "'$column', ${_columnExpression(section, column, field)}",
    if (section.cardIdentity)
      "'$privacyExportCardIdentityKey', jsonb_build_object("
          "'name', export_card.name, "
          "'scryfall_id', export_card.scryfall_id, "
          "'oracle_id', export_card.oracle_id, "
          "'set_code', export_card.set_code, "
          "'collector_number', export_card.collector_number)",
  ];
  final objects = <String>[
    for (var start = 0; start < pairs.length; start += _maxPairsPerObject)
      'jsonb_build_object('
          '${pairs.sublist(start, math.min(start + _maxPairsPerObject, pairs.length)).join(', ')}'
          ')',
  ];
  final buffer =
      StringBuffer()
        ..write('SELECT ${objects.join(' || ')} ')
        ..write('FROM ${section.table} $alias');
  if (section.joins.isNotEmpty) buffer.write(' ${section.joins}');
  if (section.cardIdentity) {
    buffer.write(' JOIN cards export_card ON export_card.id = $alias.card_id');
  }
  buffer.write(' WHERE ${section.where}');
  if (section.orderBy != null) buffer.write(' ORDER BY ${section.orderBy}');
  if (section.single) buffer.write(' LIMIT 1');
  return buffer.toString();
}

String _columnExpression(
  PrivacyExportSection section,
  String column,
  PrivacyExportField field,
) {
  final alias = section.alias;
  if (field != PrivacyExportField.includeIfSubjectAuthored) {
    return '$alias.$column';
  }
  final author = section.authorColumn;
  if (author == null) {
    throw StateError('Seção ${section.path} sem authorColumn para $column.');
  }
  return 'CASE WHEN $alias.$author = CAST(@userId AS uuid) '
      'THEN $alias.$column END';
}
