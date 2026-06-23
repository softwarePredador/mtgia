-- PG058 Deck 6 L3B simple red rituals apply.
-- Expected precheck:
--   deck_target_cards=2
--   target_rule_rows=5
--   target_runtime_rows=2
--   generated_review_only_rows=2
--   curated_shadow_rows_to_disable=1
--   trusted_missing_hash_rows=3
--   trusted_without_scope_rows=2
--   target_runtime_rows_without_produces=1
--   active_card_id_mismatch_same_oracle_rows=0
--   active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0
--   target_names_missing_rules=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg058_deck6_l3b_simple_red_rituals_20260623_020031 AS
WITH target_names(name) AS (
  VALUES
    ('Rite of Flame'),
    ('Seething Song')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT cbr.*
FROM card_battle_rules cbr
JOIN deck_target dt ON dt.normalized_name = cbr.normalized_name;

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg058_deck6_l3b_simple_red_rituals_20260623_020031;

  IF v_backup_rows <> 5 THEN
    RAISE EXCEPTION 'PG058 precondition failed: backup rows=% expected 5', v_backup_rows;
  END IF;
END $$;

WITH target_metadata(
  name,
  target_logical_rule_key,
  produces,
  mana_produced,
  battle_model_scope,
  oracle_runtime_scope,
  instant_flag,
  sorcery_flag,
  graveyard_named_copy_scaling_status,
  singleton_commander_baseline
) AS (
  VALUES
    (
      'Rite of Flame',
      'battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518',
      'R',
      2,
      'rite_of_flame_singleton_baseline_red_ritual_v1',
      'single_shot_red_ritual_runtime_graveyard_copy_scaling_annotation_only',
      NULL::boolean,
      true,
      'annotation_only',
      true
    ),
    (
      'Seething Song',
      'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7',
      'R',
      5,
      'single_shot_red_ritual_v1',
      'single_shot_red_ritual_runtime_generic_pool_color_annotation',
      true,
      NULL::boolean,
      NULL::text,
      NULL::boolean
    )
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    tm.target_logical_rule_key,
    tm.produces,
    tm.mana_produced,
    tm.battle_model_scope,
    tm.oracle_runtime_scope,
    tm.instant_flag,
    tm.sorcery_flag,
    tm.graveyard_named_copy_scaling_status,
    tm.singleton_commander_baseline
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  card_id = dt.deck_card_id,
  oracle_hash = dt.target_oracle_hash,
  effect_json = jsonb_strip_nulls(
    coalesce(cbr.effect_json, '{}'::jsonb)
    || jsonb_build_object(
      'effect', 'ramp_ritual',
      'mana_produced', dt.mana_produced,
      'produces', dt.produces,
      'battle_model_scope', dt.battle_model_scope,
      'oracle_runtime_scope', dt.oracle_runtime_scope,
      'instant', dt.instant_flag,
      'sorcery', dt.sorcery_flag,
      'graveyard_named_copy_scaling_status', dt.graveyard_named_copy_scaling_status,
      'singleton_commander_baseline', dt.singleton_commander_baseline,
      'mana_color_status', 'abstracted_to_generic_pool_runtime',
      'pg058_l3b_simple_red_ritual_family', 'deck6_simple_red_rituals'
    )
  ),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG058 2026-06-23: Deck 6 L3B simple red ritual family. Added oracle_hash, produces/mana_produced, battle_model_scope, and explicit color/graveyard-scaling abstraction status. Rite of Flame uses singleton baseline; named-copy graveyard scaling remains annotation_only because the current executor does not dynamically count named copies across graveyards. No deck swap.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.logical_rule_key = dt.target_logical_rule_key
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status = 'auto';

WITH target_metadata(
  name,
  target_logical_rule_key
) AS (
  VALUES
    ('Rite of Flame', 'battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518'),
    ('Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    tm.target_logical_rule_key
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG058 2026-06-23: Disabled generated/legacy simple-red-ritual shadow after retaining one oracle-hashed trusted runtime rule for Deck 6 L3B.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND (
    (cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only')
    OR (
      cbr.source = 'curated'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status = 'auto'
      AND cbr.logical_rule_key IS DISTINCT FROM dt.target_logical_rule_key
    )
  );

COMMIT;
