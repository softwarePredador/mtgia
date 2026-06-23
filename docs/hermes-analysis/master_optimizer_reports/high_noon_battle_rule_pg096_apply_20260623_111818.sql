BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg096_high_noon_battle_rule_20260623_111818;

CREATE TABLE manaloom_deploy_audit.pg096_high_noon_battle_rule_20260623_111818 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'high noon';

INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
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
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
)
SELECT
  'high noon',
  'battle_rule_v1:fca6c4be65cae378901514ff6c8417d1',
  c.id,
  c.name,
  jsonb_build_object(
    'effect', 'passive',
    'cmc', 2,
    'ability_kind', 'static',
    'static_spell_limit_per_turn', 1,
    'spell_limit_scope', 'each_player',
    'spell_limit_status', 'annotation_only_no_static_spell_limit_executor',
    'activated_cost', '{4}{R}, Sacrifice this enchantment',
    'activated_damage_amount', 5,
    'activated_damage_target', 'any',
    'activated_damage_status', 'annotation_only_no_activation_executor',
    'sacrifice_self_activation_status', 'annotation_only',
    'battle_model_scope', 'high_noon_one_spell_per_turn_static_activated_five_damage_annotation_v1',
    'oracle_runtime_scope', 'one_spell_per_turn_static_runtime_annotation_activated_five_damage_annotation'
  ),
  jsonb_build_object(
    'effect', 'passive',
    'category', 'protection',
    'role', 'rule_of_law_static',
    'timing', 'permanent'
  ),
  'curated',
  1.000,
  'verified',
  'auto',
  2,
  'dfec584c3cfdf4eb34b8a1e1d4f7da3a',
  'PG096: replaces false remove_creature semantics with Oracle-specific High Noon passive rule. One-spell-per-turn static ability and activated five-damage sacrifice mode are annotation-only until dedicated executors exist.',
  'auditor_central_pg096',
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM cards c
WHERE lower(c.name) = 'high noon'
ORDER BY c.id
LIMIT 1
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP;

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG096 disabled: High Noon oracle is a static one-spell-per-turn enchantment plus activated 5 damage, not targeted creature removal.'
  ),
  reviewed_by = 'auditor_central_pg096',
  reviewed_at = CURRENT_TIMESTAMP,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP
WHERE normalized_name = 'high noon'
  AND logical_rule_key <> 'battle_rule_v1:fca6c4be65cae378901514ff6c8417d1'
  AND effect_json->>'effect' = 'remove_creature';

COMMIT;
