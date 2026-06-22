\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200;
CREATE TABLE manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) = 'arcane epiphany';

INSERT INTO manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200
  (section, key, payload)
SELECT
  'card_function_tags',
  card_id::text || '|' || tag || '|' || source,
  to_jsonb(cft.*)
FROM card_function_tags cft
WHERE lower(card_name) = 'arcane epiphany';

DO $$
DECLARE
  v_card_rows int;
  v_hash text;
BEGIN
  SELECT count(*), max(md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')))
  INTO v_card_rows, v_hash
  FROM cards
  WHERE lower(name) = 'arcane epiphany';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG017 precondition failed: Arcane Epiphany card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash <> 'cb627ae013ba784db3519c005897520b' THEN
    RAISE EXCEPTION 'PG017 precondition failed: oracle_hash=% expected cb627ae013ba784db3519c005897520b', v_hash;
  END IF;
END $$;

WITH card AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'arcane epiphany'
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
  'arcane epiphany',
  'battle_rule_v1:3e12c38dd6d41a47079fbdefee08b3bd',
  id,
  name,
  jsonb_build_object(
    'effect', 'draw_cards',
    'draw_count', 3,
    'cmc', 5.0,
    'battle_model_scope', 'arcane_epiphany_draw_three_cost_reduction_unmodeled_v1'
  ),
  jsonb_build_object(
    'category', 'draw',
    'effect', 'draw_cards',
    'subtype', 'instant_draw_three'
  ),
  'curated',
  0.94,
  'verified',
  'auto',
  1,
  'cb627ae013ba784db3519c005897520b',
  'PG-017: oracle-verified draw three rule. Wizard cost reduction is documented but not modeled in this runtime pass.',
  'codex_central_auditor_pg017',
  now(),
  now(),
  now(),
  now()
FROM card
ON CONFLICT (normalized_name, logical_rule_key)
DO UPDATE SET
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

WITH card AS (
  SELECT id, name
  FROM cards
  WHERE lower(name) = 'arcane epiphany'
)
INSERT INTO card_function_tags (
  card_id,
  card_name,
  tag,
  confidence,
  source,
  evidence,
  updated_at
)
SELECT
  id,
  name,
  'draw',
  0.94,
  'card_battle_rules_v1',
  'PG-017 curated draw_cards battle rule battle_rule_v1:3e12c38dd6d41a47079fbdefee08b3bd',
  now()
FROM card
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = now();

DO $$
DECLARE
  v_curated int;
  v_tag int;
BEGIN
  SELECT count(*) INTO v_curated
  FROM card_battle_rules
  WHERE normalized_name = 'arcane epiphany'
    AND logical_rule_key = 'battle_rule_v1:3e12c38dd6d41a47079fbdefee08b3bd'
    AND effect_json->>'effect' = 'draw_cards'
    AND effect_json->>'draw_count' = '3'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_tag
  FROM card_function_tags
  WHERE lower(card_name) = 'arcane epiphany'
    AND tag = 'draw'
    AND source = 'card_battle_rules_v1';

  IF v_curated <> 1 THEN
    RAISE EXCEPTION 'PG017 apply failed: curated executable rows=% expected 1', v_curated;
  END IF;
  IF v_tag <> 1 THEN
    RAISE EXCEPTION 'PG017 apply failed: draw function tags=% expected 1', v_tag;
  END IF;
END $$;

COMMIT;
