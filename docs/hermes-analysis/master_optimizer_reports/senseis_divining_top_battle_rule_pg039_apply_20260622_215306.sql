\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg039_senseis_top_battle_rule_20260622_215306;
CREATE TABLE manaloom_deploy_audit.pg039_senseis_top_battle_rule_20260622_215306 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg039_senseis_top_battle_rule_20260622_215306
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'sensei''s divining top'
   OR lower(card_name) = 'sensei''s divining top';

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
  WHERE lower(name) = 'sensei''s divining top';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'sensei''s divining top'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      'f2c5ac0f52963cd710470adc25cc6d7c';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'sensei''s divining top'
    AND logical_rule_key = 'battle_rule_v1:70c8478871f352b46cee1af296117951'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = 'f2c5ac0f52963cd710470adc25cc6d7c';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'sensei''s divining top'
    AND logical_rule_key <> 'battle_rule_v1:70c8478871f352b46cee1af296117951'
    AND effect_json->>'effect' IN ('topdeck_manipulation', 'draw_cards')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG039 precondition failed: Sensei Top card rows=% expected 1', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG039 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG039 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG039 precondition failed: target Sensei Top rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG039 precondition failed: no enabled Sensei Top rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'sensei''s divining top'::text AS normalized_name,
    'Sensei''s Divining Top'::text AS card_name,
    'battle_rule_v1:70c8478871f352b46cee1af296117951'::text AS logical_rule_key,
    'f2c5ac0f52963cd710470adc25cc6d7c'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 1.0,
      'effect', 'topdeck_manipulation',
      'activation_cost_generic', 1,
      'peek_top_count', 3,
      'reorder_top', true,
      'reorder_top_status', 'lorehold_first_draw_planning_executor',
      'activated_draw_put_self_on_top', true,
      'draw_activation_requires_tap', true,
      'draw_activation_cost_generic', 0,
      'activated_draw_put_self_on_top_status',
        'lorehold_first_draw_miracle_window_executor',
      'generic_draw_activation_status', 'annotation_only',
      'battle_model_scope',
        'senseis_top_reorder_draw_lorehold_first_draw_miracle_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'draw',
      'effect', 'topdeck_manipulation'
    ) AS deck_role_json,
    'PG-039: promoted Sensei''s Divining Top as oracle-specific topdeck manipulation. Runtime executes the {1} top-three reorder line for Lorehold first-draw planning and the tap draw-put-self-on-top line only in the Lorehold first-draw miracle window. Generic activated draw policy remains annotation_only until modeled broadly.'::text AS notes
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
  0.900,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg039',
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
    'PG-039 disabled this stale/generic Sensei''s Divining Top row after promoting oracle-specific topdeck rule battle_rule_v1:70c8478871f352b46cee1af296117951.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'sensei''s divining top'
  AND logical_rule_key <> 'battle_rule_v1:70c8478871f352b46cee1af296117951'
  AND effect_json->>'effect' IN ('topdeck_manipulation', 'draw_cards')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg039_senseis_top_apply_result' AS check_name,
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
WHERE normalized_name = 'sensei''s divining top'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
