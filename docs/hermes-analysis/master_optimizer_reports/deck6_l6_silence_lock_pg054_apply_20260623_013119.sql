-- PG054 Deck 6 L6 silence-lock family apply.
-- Expected precheck:
--   deck_target_cards=2
--   target_rule_rows=5
--   active_curated_rows=3
--   trusted_missing_hash_rows=3
--   generated_review_only_rows=2
--   silence_legacy_active_rows=1
--   target_active_runtime_rows=2
--   active_card_id_mismatch_same_oracle_rows=0
--   active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0
--   target_names_missing_rules=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg054_deck6_l6_silence_lock_20260623_013119 AS
WITH target_names(name) AS (
  VALUES
    ('Grand Abolisher'),
    ('Silence')
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

WITH deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND c.name IN ('Grand Abolisher', 'Silence')
)
UPDATE card_battle_rules cbr
SET
  card_id = dt.deck_card_id,
  oracle_hash = dt.target_oracle_hash,
  effect_json = jsonb_strip_nulls(
    coalesce(cbr.effect_json, '{}'::jsonb)
    || CASE
      WHEN dt.name = 'Silence' THEN jsonb_build_object(
        'cmc', 1.0,
        'effect', 'silence_spell',
        'instant', true,
        'battle_model_scope', 'silence_until_eot_v1',
        'oracle_runtime_scope', 'opponent_spell_cast_lock_until_eot_runtime',
        'pg054_l6_silence_family', 'deck6_silence_lock'
      )
      WHEN dt.name = 'Grand Abolisher' THEN jsonb_build_object(
        'effect', 'silence_opponents',
        'battle_model_scope', 'static_opponent_spell_lock_activated_ability_lock_annotation_v1',
        'oracle_runtime_scope', 'opponent_spell_cast_lock_runtime_activated_ability_lock_annotation_only',
        'timing_scope', 'during_controller_turn',
        'activated_ability_lock_status', 'annotation_only',
        'pg054_l6_silence_family', 'deck6_silence_lock'
      )
      ELSE '{}'::jsonb
    END
  ),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG054 2026-06-23: Deck 6 L6 silence-lock family. Added oracle_hash and battle_model_scope to the trusted runtime rule. Grand Abolisher activated-ability lock remains annotation_only; spell-cast lock is the current runtime model. No deck swap.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status = 'auto'
  AND cbr.logical_rule_key IN (
    'battle_rule_v1:74b210b77b004a677906e0216d44e445',
    'battle_rule_v1:4df98360e4467568504b19219c8ba5d0'
  );

WITH target_names(name) AS (
  VALUES
    ('Grand Abolisher'),
    ('Silence')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name, c.name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG054 2026-06-23: Disabled silence-lock legacy/shadow row after retaining an oracle-hashed trusted runtime rule for Deck 6 L6 silence-lock family.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND (
    (cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only')
    OR (
      dt.name = 'Silence'
      AND cbr.source = 'curated'
      AND cbr.logical_rule_key = 'battle_rule_v1:d3367950588008088c6a73c604765da0'
      AND cbr.execution_status = 'auto'
    )
  );

COMMIT;
