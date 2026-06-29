BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg250_repercussion_passive_runtime_correction_20260629_145402 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'repercussion'
   OR normalized_name LIKE 'repercussion // %';

WITH deprecated AS (
  UPDATE public.card_battle_rules
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(notes, ''), 'PG250: disabled immediate direct_damage Repercussion row after runtime proof showed the enchantment must be a passive global trigger.')
  WHERE (normalized_name = 'repercussion' OR normalized_name LIKE 'repercussion // %')
    AND logical_rule_key <> 'battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017'
    AND (review_status <> 'deprecated' OR execution_status <> 'disabled')
  RETURNING *
),
target_card AS (
  SELECT id, name
  FROM public.cards
  WHERE (
         lower(name) = 'repercussion'
         OR split_part(lower(name), ' // ', 1) = 'repercussion'
       )
    AND md5(coalesce(oracle_text, '')) = '8e1ed4f8063ab89dd8906878a6232862'
  ORDER BY name
  LIMIT 1
),
upserted AS (
  INSERT INTO public.card_battle_rules (
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
    'repercussion',
    'battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017',
    id,
    name,
    '{
      "ability_kind": "triggered_static_enchantment",
      "battle_model_scope": "creature_damage_controller_reflect_global_v1",
      "damage_amount_source": "damage_dealt_to_creature",
      "effect": "passive",
      "global_creature_damage_reflect_to_controller": true,
      "trigger": "creature_dealt_damage",
      "trigger_effect": "damage_creature_controller"
    }'::jsonb,
    '{
      "category": "burn_engine",
      "effect": "damage_reflection",
      "subtype": "creature_damage_controller_reflect",
      "timing": "triggered"
    }'::jsonb,
    'curated',
    0.94,
    'verified',
    'auto',
    2,
    '8e1ed4f8063ab89dd8906878a6232862',
    'PG250: Repercussion is a passive global enchantment trigger, not an immediate direct damage spell. Runtime proof uses creature_damage_controller_reflect_global_v1.',
    'codex-pg250',
    now(),
    now(),
    now(),
    now()
  FROM target_card
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
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
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at
  RETURNING *
)
SELECT
  (SELECT count(*) FROM deprecated) AS deprecated_rows,
  (SELECT count(*) FROM upserted) AS upserted_rows;

COMMIT;
