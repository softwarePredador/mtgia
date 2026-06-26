-- Molecule Man local runtime rule package.
-- Scope: local SQLite/Hermes validation only in this turn; PostgreSQL not applied.
-- Runtime intent: nonland cards in controller hand have miracle {0}.

INSERT INTO battle_card_rules (
  normalized_name,
  logical_rule_key,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  created_at,
  updated_at,
  last_seen_at
) VALUES (
  'molecule man',
  'battle_rule_v1:752f8cfd0a44d1889ffdb40610847374',
  'Molecule Man',
  json_object(
    'ability_kind', 'static',
    'battle_model_scope', 'nonland_hand_miracle_zero_static_v1',
    'effect', 'passive',
    'grants_miracle_cost', 0,
    'grants_miracle_nonland', json('true'),
    'grants_miracle_card_scope', 'nonland',
    'is_creature_permanent', json('true'),
    'oracle_runtime_scope', 'nonland_cards_in_controller_hand_have_miracle_zero'
  ),
  json_object(
    'category', 'topdeck_miracle_setup',
    'strategy_role', 'miracle_zero_engine',
    'commander_fit', 'core_ceiling_piece'
  ),
  'local_runtime_patch_20260626',
  0.96,
  'verified',
  'auto',
  1,
  '35e82bd52776c455745138b048ccc116',
  'Manual runtime model: Molecule Man grants miracle {0} to nonland cards in controller hand; no opponent-upkeep rummage.',
  datetime('now'),
  datetime('now'),
  datetime('now')
)
ON CONFLICT(normalized_name, logical_rule_key) DO UPDATE SET
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  execution_status = excluded.execution_status,
  rule_version = excluded.rule_version,
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at;
