\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517;
CREATE TABLE manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'blasphemous act'
   OR lower(card_name) = 'blasphemous act';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'blasphemous act';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'blasphemous act'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '826022a579db4551b45ad35e4cfab973';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'blasphemous act'
    AND logical_rule_key <> 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
    AND effect_json->>'effect' IN ('board_wipe', 'damage_wipe')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG029 precondition failed: Blasphemous Act card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG029 precondition failed: Blasphemous Act oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG029 precondition failed: no legacy Blasphemous Act wipe row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'blasphemous act'::text AS normalized_name,
    'Blasphemous Act'::text AS card_name,
    'battle_rule_v1:56271789d639ef390213dbc90059e4d2'::text AS logical_rule_key,
    '826022a579db4551b45ad35e4cfab973'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 9.0,
      'effect', 'damage_wipe',
      'damage', 13,
      'damage_scope', 'each_creature',
      'generic_cost_reduction_per_creature_on_battlefield', 1,
      'generic_cost_reduction_runtime', 'annotation_only',
      'battle_model_scope', 'blasphemous_act_damage_13_each_creature_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'wipe',
      'effect', 'damage_wipe',
      'subtype', 'damage_13_each_creature'
    ) AS deck_role_json,
    'PG-029: promoted Blasphemous Act as oracle-specific 13 damage to each creature. Runtime models the resolution as lethal damage to creatures with toughness <= 13, preserving indestructible and high-toughness survivors. The spell cost reduction is recorded as annotation_only metadata because this runtime slice does not yet implement dynamic generic cost reduction.'::text AS notes
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
  0.920,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg029',
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
    'PG-029 disabled this broad/shadow Blasphemous Act wipe row after promoting oracle-specific damage_wipe rule battle_rule_v1:56271789d639ef390213dbc90059e4d2.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'blasphemous act'
  AND logical_rule_key <> 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
  AND effect_json->>'effect' IN ('board_wipe', 'damage_wipe')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg029_blasphemous_act_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'blasphemous act'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
