\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg040_swords_to_plowshares_battle_rule_20260622_221254;
CREATE TABLE manaloom_deploy_audit.pg040_swords_to_plowshares_battle_rule_20260622_221254 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg040_swords_to_plowshares_battle_rule_20260622_221254
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'swords to plowshares'
   OR lower(card_name) = 'swords to plowshares';

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
  WHERE lower(name) = 'swords to plowshares';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'swords to plowshares'
    AND md5(coalesce(oracle_text, '')) = '702f566e95dd477f5cf5a551e41e9df8';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'swords to plowshares'
    AND logical_rule_key = 'battle_rule_v1:379008f3f03f94258292123453e3041c'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = '702f566e95dd477f5cf5a551e41e9df8';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'swords to plowshares'
    AND logical_rule_key <> 'battle_rule_v1:379008f3f03f94258292123453e3041c'
    AND effect_json->>'effect' = 'remove_creature'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG040 precondition failed: Swords card rows=% expected 1', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG040 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG040 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG040 precondition failed: target Swords rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG040 precondition failed: no enabled Swords rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'swords to plowshares'::text AS normalized_name,
    'Swords to Plowshares'::text AS card_name,
    'battle_rule_v1:379008f3f03f94258292123453e3041c'::text AS logical_rule_key,
    '702f566e95dd477f5cf5a551e41e9df8'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 1.0,
      'effect', 'remove_creature',
      'instant', true,
      'target', 'creature',
      'destination', 'exile',
      'exile_target', true,
      'target_controller_life_gain_equal_target_power', true,
      'life_gain_status', 'dynamic_target_power_executor',
      'battle_model_scope',
        'swords_to_plowshares_creature_exile_life_equal_power_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'removal',
      'effect', 'remove_creature',
      'target', 'creature',
      'timing', 'instant'
    ) AS deck_role_json,
    'PG-040: promoted Swords to Plowshares as oracle-specific creature exile. Runtime executes exile destination and target-controller life gain equal to the exiled creature power.'::text AS notes
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
  'codex_central_auditor_pg040',
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
    'PG-040 disabled this stale/generic Swords to Plowshares row after promoting oracle-specific exile plus dynamic life-gain rule battle_rule_v1:379008f3f03f94258292123453e3041c.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'swords to plowshares'
  AND logical_rule_key <> 'battle_rule_v1:379008f3f03f94258292123453e3041c'
  AND effect_json->>'effect' = 'remove_creature'
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg040_swords_to_plowshares_apply_result' AS check_name,
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
WHERE normalized_name = 'swords to plowshares'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
