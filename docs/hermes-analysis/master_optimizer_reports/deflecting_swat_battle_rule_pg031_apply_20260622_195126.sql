\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg031_deflecting_swat_battle_rule_20260622_195126;
CREATE TABLE manaloom_deploy_audit.pg031_deflecting_swat_battle_rule_20260622_195126 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg031_deflecting_swat_battle_rule_20260622_195126
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'deflecting swat'
   OR lower(card_name) = 'deflecting swat';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'deflecting swat';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'deflecting swat'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      'a34c89817f87f32bedfb3d66a5bdc672';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'deflecting swat'
    AND logical_rule_key <> 'battle_rule_v1:bac48343654a53205d790a8268bd2631'
    AND effect_json->>'effect' IN ('redirect_removal', 'draw_cards')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG031 precondition failed: Deflecting Swat card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG031 precondition failed: Deflecting Swat oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG031 precondition failed: no enabled Deflecting Swat redirect/shadow row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'deflecting swat'::text AS normalized_name,
    'Deflecting Swat'::text AS card_name,
    'battle_rule_v1:bac48343654a53205d790a8268bd2631'::text AS logical_rule_key,
    'a34c89817f87f32bedfb3d66a5bdc672'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'redirect_removal',
      'instant', true,
      'battle_model_scope', 'deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1',
      'target_scope', 'target_spell_or_ability',
      'runtime_scope', 'single_target_targeted_removal_spell',
      'ability_targets_runtime', 'annotation_only',
      'chooses_new_targets', true,
      'free_if_control_commander', true,
      'alternative_cost', '{0}',
      'alternative_cost_condition', 'control_commander'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'protection',
      'effect', 'redirect_removal',
      'timing', 'instant',
      'battle_model_scope', 'deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1'
    ) AS deck_role_json,
    'PG-031: promoted Deflecting Swat as oracle-specific target-redirection rule. Runtime models free casting when its controller controls a commander and redirects a single-target targeted removal spell. The broader spell-or-ability target space is retained as annotation_only metadata because the current stack runtime does not yet model activated/triggered ability target redirection.'::text AS notes
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
  0.930,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg031',
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
    'PG-031 disabled this broad/shadow Deflecting Swat row after promoting oracle-specific redirect rule battle_rule_v1:bac48343654a53205d790a8268bd2631.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'deflecting swat'
  AND logical_rule_key <> 'battle_rule_v1:bac48343654a53205d790a8268bd2631'
  AND effect_json->>'effect' IN ('redirect_removal', 'draw_cards')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg031_deflecting_swat_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'deflecting swat'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
