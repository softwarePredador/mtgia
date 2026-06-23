-- PG052 Valakut Awakening hash-only provenance apply.
-- Expected precheck:
--   deck_target_cards=1
--   target_rule_rows=3
--   active_curated_rows=1
--   trusted_missing_hash_rows=1
--   active_card_id_mismatch_same_oracle_rows=0
--   active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0
--   target_names_missing_rules=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg052_valakut_awakening_hash_only_20260623_012000 AS
WITH deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND c.name = 'Valakut Awakening // Valakut Stoneforge'
)
SELECT cbr.*
FROM card_battle_rules cbr
JOIN deck_target dt ON dt.normalized_name = cbr.normalized_name;

WITH deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.id AS deck_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND c.name = 'Valakut Awakening // Valakut Stoneforge'
)
UPDATE card_battle_rules cbr
SET
  card_id = dt.deck_card_id,
  oracle_hash = dt.target_oracle_hash,
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG052 2026-06-23: Hash-only provenance fix for the verified Valakut Awakening MDFC hand-filter rule. No executor/effect_json change.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status = 'auto'
  AND cbr.logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d';

COMMIT;
