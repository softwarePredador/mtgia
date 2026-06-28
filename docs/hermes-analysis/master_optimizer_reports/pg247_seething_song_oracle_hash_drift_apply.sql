BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg247_seething_song_oracle_hash_drift_20260628 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

WITH expected AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.normalized_name = 'seething song'
    AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.effect_json ->> 'effect' = 'ramp_ritual'
    AND r.effect_json ->> 'battle_model_scope' = 'single_shot_red_ritual_v1'
    AND md5(coalesce(c.oracle_text, '')) = 'ccd492289c6f1c14c8fb7a248d7bbf32'
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = expected.oracle_hash,
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG247 2026-06-28: restored Seething Song oracle_hash after current PG -> Hermes deck 6 audit exposed provenance drift. No executor, oracle, deck, or logical_rule_key change.'
    )
  FROM expected
  WHERE r.normalized_name = expected.normalized_name
    AND r.logical_rule_key = expected.logical_rule_key
    AND r.oracle_hash IS DISTINCT FROM expected.oracle_hash
  RETURNING r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows FROM updated;

COMMIT;
