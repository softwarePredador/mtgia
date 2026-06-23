\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg032_flawless_maneuver_battle_rule_20260622_200215;
CREATE TABLE manaloom_deploy_audit.pg032_flawless_maneuver_battle_rule_20260622_200215 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg032_flawless_maneuver_battle_rule_20260622_200215
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'flawless maneuver'
   OR lower(card_name) = 'flawless maneuver';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'flawless maneuver';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'flawless maneuver'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      'fa955216fa827bf75c5b79dcbdb4b97e';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'flawless maneuver'
    AND logical_rule_key <> 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'
    AND effect_json->>'effect' = 'indestructible'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG032 precondition failed: Flawless Maneuver card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG032 precondition failed: Flawless Maneuver oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG032 precondition failed: no enabled Flawless Maneuver indestructible/shadow row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'flawless maneuver'::text AS normalized_name,
    'Flawless Maneuver'::text AS card_name,
    'battle_rule_v1:73622071c1ad89267708f914a0729bf2'::text AS logical_rule_key,
    'fa955216fa827bf75c5b79dcbdb4b97e'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'indestructible',
      'instant', true,
      'battle_model_scope', 'flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1',
      'target_scope', 'creatures_you_control',
      'duration', 'until_end_of_turn',
      'free_if_control_commander', true,
      'alternative_cost', '{0}',
      'alternative_cost_condition', 'control_commander'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'protection',
      'effect', 'indestructible',
      'timing', 'instant',
      'battle_model_scope', 'flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1'
    ) AS deck_role_json,
    'PG-032: promoted Flawless Maneuver as oracle-specific protection rule. Runtime models free casting when its controller controls a commander and grants indestructible to creatures that player controls until end of turn.'::text AS notes
),
resolved_card AS (
  SELECT tr.*, c.id
  FROM target_rule tr
  JOIN cards c ON lower(c.name) = tr.normalized_name
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
  'codex_central_auditor_pg032',
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
    'PG-032 disabled this broad/shadow Flawless Maneuver row after promoting oracle-specific protection rule battle_rule_v1:73622071c1ad89267708f914a0729bf2.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'flawless maneuver'
  AND logical_rule_key <> 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'
  AND effect_json->>'effect' = 'indestructible'
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg032_flawless_maneuver_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'flawless maneuver'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
