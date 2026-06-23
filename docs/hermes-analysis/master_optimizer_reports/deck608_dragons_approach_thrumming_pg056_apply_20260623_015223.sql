-- PG056 Deck 608 Dragon's Approach / Thrumming Stone apply.
-- Expected precheck:
--   target_cards=2
--   target_rule_rows=4
--   trusted_active_rows=1
--   trusted_missing_hash_rows=1
--   trusted_without_scope_rows=1
--   generated_review_only_rows=3
--   thrumming_trusted_active_rows=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg056_deck608_dragons_approach_thrumming_20260623_015223 AS
WITH target_names(name) AS (
  VALUES
    ('Dragon''s Approach'),
    ('Thrumming Stone')
),
target_cards AS (
  SELECT lower(c.name) AS normalized_name
  FROM cards c
  JOIN target_names tn ON tn.name = c.name
)
SELECT cbr.*
FROM card_battle_rules cbr
JOIN target_cards tc ON tc.normalized_name = cbr.normalized_name;

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg056_deck608_dragons_approach_thrumming_20260623_015223;

  IF v_backup_rows <> 4 THEN
    RAISE EXCEPTION 'PG056 precondition failed: backup rows=% expected 4', v_backup_rows;
  END IF;
END $$;

WITH target_cards AS (
  SELECT
    c.id AS card_id,
    lower(c.name) AS normalized_name,
    c.name,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM cards c
  WHERE c.name IN ('Dragon''s Approach', 'Thrumming Stone')
)
UPDATE card_battle_rules cbr
SET
  card_id = tc.card_id,
  oracle_hash = tc.target_oracle_hash,
  source = 'curated',
  review_status = 'verified',
  execution_status = 'auto',
  confidence = 1.0,
  effect_json = jsonb_strip_nulls(
    CASE
      WHEN tc.name = 'Dragon''s Approach' THEN jsonb_build_object(
        'effect', 'dragons_approach',
        'damage', 3,
        'battle_model_scope', 'fixed_damage_graveyard_dragon_tutor_ripple_v1',
        'oracle_runtime_scope', 'fixed_each_opponent_damage_optional_graveyard_cost_dragon_library_to_battlefield',
        'graveyard_cost_named_copies', 5,
        'dragon_tutor_destination', 'battlefield',
        'copy_limit_exception', true,
        'ripple_interop_status', 'same_name_ripple_runtime',
        'pg056_deck608_dragon_package', 'dragon_approach'
      )
      WHEN tc.name = 'Thrumming Stone' THEN jsonb_build_object(
        'cmc', 5.0,
        'effect', 'ripple_engine',
        'battle_model_scope', 'static_spell_ripple_4_same_name_runtime_v1',
        'oracle_runtime_scope', 'controller_spells_gain_ripple_4_runtime_same_name_free_cast',
        'ripple_count', 4,
        'ripple_applies_to', 'spells_you_cast',
        'ripple_resolution_model', 'reveal_top_four_cast_same_name_bottom_rest',
        'pg056_deck608_dragon_package', 'thrumming_stone'
      )
      ELSE coalesce(cbr.effect_json, '{}'::jsonb)
    END
  ),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG056 2026-06-23: Deck 608 Dragon package. Oracle-reviewed runtime model for Dragon''s Approach fixed damage/graveyard-cost Dragon tutor and Thrumming Stone ripple 4 same-name free-cast support. No deck swap.'
  ),
  reviewed_by = 'codex',
  reviewed_at = now(),
  updated_at = now()
FROM target_cards tc
WHERE cbr.normalized_name = tc.normalized_name
  AND (
    (tc.name = 'Dragon''s Approach'
      AND cbr.source = 'curated'
      AND cbr.logical_rule_key = 'battle_rule_v1:78d365e6550e295f9cbfa4f92245f864')
    OR
    (tc.name = 'Thrumming Stone'
      AND cbr.logical_rule_key = 'battle_rule_v1:aab9a1ed1e17a7a4d3446562be30775f')
  );

WITH target_cards AS (
  SELECT lower(c.name) AS normalized_name, c.name
  FROM cards c
  WHERE c.name IN ('Dragon''s Approach', 'Thrumming Stone')
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG056 2026-06-23: Disabled generated review-only/shadow row after retaining one oracle-hashed curated runtime rule for the Deck 608 Dragon package.'
  ),
  updated_at = now()
FROM target_cards tc
WHERE cbr.normalized_name = tc.normalized_name
  AND cbr.source = 'generated'
  AND cbr.review_status = 'needs_review'
  AND cbr.execution_status = 'review_only'
  AND cbr.logical_rule_key IN (
    'battle_rule_v1:2efa4dbd568d11da821ee0284a0f0dae',
    'battle_rule_v1:aab9a1ed1e17a7a4d3446562be30775f',
    'battle_rule_v1:ed12791327f86f031a26f28af61ab9b2'
  );

COMMIT;
