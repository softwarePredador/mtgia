\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg035_lorehold_historian_battle_rule_20260622_204549;
CREATE TABLE manaloom_deploy_audit.pg035_lorehold_historian_battle_rule_20260622_204549 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg035_lorehold_historian_battle_rule_20260622_204549
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'lorehold, the historian'
   OR lower(card_name) = 'lorehold, the historian';

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
  WHERE lower(name) = 'lorehold, the historian';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'lorehold, the historian'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      'f1b6d4f38a533e56f0efb5a3f1547214';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'lorehold, the historian'
    AND logical_rule_key = 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = 'f1b6d4f38a533e56f0efb5a3f1547214';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'lorehold, the historian'
    AND logical_rule_key <> 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
    AND effect_json->>'effect' IN ('commander', 'draw_engine', 'passive')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 4 THEN
    RAISE EXCEPTION 'PG035 precondition failed: Lorehold card rows=% expected 4 printings', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG035 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG035 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG035 precondition failed: target Lorehold rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG035 precondition failed: no enabled Lorehold legacy/shadow rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'lorehold, the historian'::text AS normalized_name,
    'Lorehold, the Historian'::text AS card_name,
    'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'::text AS logical_rule_key,
    'f1b6d4f38a533e56f0efb5a3f1547214'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'passive',
      'battle_model_scope', 'lorehold_opponent_upkeep_miracle_v1',
      'cmc', 5.0,
      'is_commander', true,
      'flying', true,
      'haste', true,
      'grants_miracle_cost', 2,
      'opponent_upkeep_rummage', true
    ) AS effect_json,
    jsonb_build_object(
      'category', 'engine',
      'effect', 'miracle_engine',
      'battle_model_scope', 'lorehold_opponent_upkeep_miracle_v1'
    ) AS deck_role_json,
    'PG-035: promoted Lorehold, the Historian as oracle-specific miracle/rummage commander rule. Runtime models instants and sorceries in hand as miracle {2} during first-draw windows and models the opponent-upkeep discard-then-draw trigger; full Magic policy edges remain outside this battle approximation.'::text AS notes
),
resolved_card AS (
  SELECT tr.*, cbr.card_id AS id
  FROM target_rule tr
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = 'battle_rule_v1:91aa990f0d25b0aba2a1447bc1a47914'
  WHERE cbr.card_id IS NOT NULL
  UNION ALL
  SELECT tr.*, c.id
  FROM target_rule tr
  JOIN cards c
    ON lower(c.name) = tr.normalized_name
  WHERE NOT EXISTS (
    SELECT 1
    FROM card_battle_rules cbr
    WHERE cbr.normalized_name = tr.normalized_name
      AND cbr.logical_rule_key = 'battle_rule_v1:91aa990f0d25b0aba2a1447bc1a47914'
      AND cbr.card_id IS NOT NULL
  )
  ORDER BY id
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
  'codex_central_auditor_pg035',
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
    'PG-035 disabled this legacy/shadow Lorehold row after promoting oracle-specific miracle/rummage commander rule battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'lorehold, the historian'
  AND logical_rule_key <> 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
  AND effect_json->>'effect' IN ('commander', 'draw_engine', 'passive')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg035_lorehold_apply_result' AS check_name,
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
WHERE normalized_name = 'lorehold, the historian'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
