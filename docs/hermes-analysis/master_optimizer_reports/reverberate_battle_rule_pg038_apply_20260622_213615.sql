\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg038_reverberate_battle_rule_20260622_213615;
CREATE TABLE manaloom_deploy_audit.pg038_reverberate_battle_rule_20260622_213615 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg038_reverberate_battle_rule_20260622_213615
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'reverberate'
   OR lower(card_name) = 'reverberate';

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
  WHERE lower(name) = 'reverberate';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'reverberate'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      'cbae05dee4261e3ed5412fd5f3591c17';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'reverberate'
    AND logical_rule_key = 'battle_rule_v1:0269136edf067f696c8576740b720e14'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = 'cbae05dee4261e3ed5412fd5f3591c17';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'reverberate'
    AND logical_rule_key <> 'battle_rule_v1:0269136edf067f696c8576740b720e14'
    AND effect_json->>'effect' = 'copy_spell'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG038 precondition failed: Reverberate card rows=% expected 1', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG038 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG038 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG038 precondition failed: target Reverberate rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG038 precondition failed: no enabled Reverberate copy rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'reverberate'::text AS normalized_name,
    'Reverberate'::text AS card_name,
    'battle_rule_v1:0269136edf067f696c8576740b720e14'::text AS logical_rule_key,
    'cbae05dee4261e3ed5412fd5f3591c17'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 2.0,
      'effect', 'copy_spell',
      'target', 'instant_or_sorcery_on_stack',
      'instant', true,
      'copy_is_not_cast', true,
      'may_choose_new_targets', true,
      'choose_new_targets_status', 'annotation_only',
      'battle_model_scope',
        'reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'engine',
      'effect', 'copy_spell',
      'target', 'instant_or_sorcery_on_stack',
      'timing', 'instant'
    ) AS deck_role_json,
    'PG-038: promoted Reverberate as oracle-specific instant/sorcery stack-copy response. Runtime copies a legal instant or sorcery spell on the stack as a non-cast copy and resolves it through the normal stack path; optional new-target selection remains annotation_only until generic retargeting is modeled.'::text AS notes
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
  0.920,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg038',
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
    'PG-038 disabled this generic/stale Reverberate copy_spell row after promoting oracle-specific stack-copy rule battle_rule_v1:0269136edf067f696c8576740b720e14.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'reverberate'
  AND logical_rule_key <> 'battle_rule_v1:0269136edf067f696c8576740b720e14'
  AND effect_json->>'effect' = 'copy_spell'
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg038_reverberate_apply_result' AS check_name,
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
WHERE normalized_name = 'reverberate'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
