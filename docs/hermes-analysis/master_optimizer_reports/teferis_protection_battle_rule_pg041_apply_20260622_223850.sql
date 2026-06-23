\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg041_teferis_protection_battle_rule_20260622_223850;
CREATE TABLE manaloom_deploy_audit.pg041_teferis_protection_battle_rule_20260622_223850 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg041_teferis_protection_battle_rule_20260622_223850
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'teferi''s protection'
   OR lower(card_name) = 'teferi''s protection';

DO $$
DECLARE
  v_card_rows int;
  v_distinct_oracle_ids int;
  v_hash_rows int;
  v_exact_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*), count(DISTINCT oracle_id)
    INTO v_card_rows, v_distinct_oracle_ids
  FROM cards
  WHERE lower(name) = 'teferi''s protection';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'teferi''s protection'
    AND md5(coalesce(oracle_text, '')) = 'bdc0faecf4420dc6162c7e72e98cc0eb';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'teferi''s protection'
    AND logical_rule_key = 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = 'bdc0faecf4420dc6162c7e72e98cc0eb';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'teferi''s protection'
    AND logical_rule_key <> 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'
    AND effect_json->>'effect' = 'phase_out'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG041 precondition failed: Teferi card rows=% expected 1', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG041 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG041 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG041 precondition failed: target Teferi rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG041 precondition failed: no enabled Teferi phase_out rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'teferi''s protection'::text AS normalized_name,
    'Teferi''s Protection'::text AS card_name,
    'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'::text AS logical_rule_key,
    'bdc0faecf4420dc6162c7e72e98cc0eb'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 3.0,
      'effect', 'phase_out',
      'instant', true,
      'duration', 'until_your_next_turn',
      'life_total_cant_change', true,
      'protection_from_everything', true,
      'phase_out_all_permanents_you_control', true,
      'phase_out_includes_lands', true,
      'exiles_self', true,
      'battle_model_scope',
        'teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'protection',
      'effect', 'phase_out',
      'scope', 'teferis_protection',
      'timing', 'instant'
    ) AS deck_role_json,
    'PG-041: promoted Teferi''s Protection as oracle-specific protection. Runtime executes life-total lock, protection from everything, all-permanent phase out including lands, and self-exile on resolution.'::text AS notes
),
resolved_card AS (
  SELECT tr.*, c.id
  FROM target_rule tr
  JOIN cards c
    ON lower(c.name) = tr.normalized_name
  ORDER BY c.id
  LIMIT 1
)
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
  normalized_name,
  logical_rule_key,
  id,
  card_name,
  effect_json,
  deck_role_json,
  'curated',
  0.950,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg041',
  now(),
  now(),
  now(),
  now()
FROM resolved_card
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
  updated_at = now(),
  last_seen_at = now();

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    ' ',
    nullif(notes, ''),
    'PG-041 disabled this stale/generic Teferi''s Protection row after promoting oracle-specific phase out, life lock, protection, and self-exile rule battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'teferi''s protection'
  AND logical_rule_key <> 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'
  AND effect_json->>'effect' = 'phase_out'
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg041_teferis_protection_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'teferi''s protection'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
