\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg037_path_to_exile_battle_rule_20260622_212057;
CREATE TABLE manaloom_deploy_audit.pg037_path_to_exile_battle_rule_20260622_212057 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg037_path_to_exile_battle_rule_20260622_212057
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'path to exile'
   OR lower(card_name) = 'path to exile';

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
  WHERE lower(name) = 'path to exile';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'path to exile'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '861c960a37be744e45f13200349e2532';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'path to exile'
    AND logical_rule_key = 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = '861c960a37be744e45f13200349e2532';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'path to exile'
    AND logical_rule_key <> 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
    AND effect_json->>'effect' = 'remove_creature'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG037 precondition failed: Path to Exile card rows=% expected 1', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG037 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG037 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG037 precondition failed: target Path to Exile rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG037 precondition failed: no enabled Path to Exile removal rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'path to exile'::text AS normalized_name,
    'Path to Exile'::text AS card_name,
    'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'::text AS logical_rule_key,
    '861c960a37be744e45f13200349e2532'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 1.0,
      'effect', 'remove_creature',
      'target', 'creature',
      'instant', true,
      'destination', 'exile',
      'exile_target', true,
      'target_controller_basic_land_tapped', true,
      'basic_land_compensation_status', 'annotation_only',
      'battle_model_scope',
        'path_to_exile_creature_exile_basic_land_compensation_annotation_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'removal',
      'effect', 'remove_creature',
      'target', 'creature',
      'timing', 'instant'
    ) AS deck_role_json,
    'PG-037: promoted Path to Exile as oracle-specific instant creature exile removal. Runtime now executes destination=exile and emits rule provenance on removal_resolved; the target-controller basic-land search/tapped battlefield rider remains annotation_only and is not a dynamic search/shuffle executor.'::text AS notes
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
  0.940,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg037',
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
    'PG-037 disabled this generic/stale Path to Exile removal row after promoting oracle-specific exile rule battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'path to exile'
  AND logical_rule_key <> 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
  AND effect_json->>'effect' = 'remove_creature'
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg037_path_to_exile_apply_result' AS check_name,
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
WHERE normalized_name = 'path to exile'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
