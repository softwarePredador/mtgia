\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg025_one_ring_orims_battle_rules_20260622_152115;
CREATE TABLE manaloom_deploy_audit.pg025_one_ring_orims_battle_rules_20260622_152115 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg025_one_ring_orims_battle_rules_20260622_152115
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name IN ('the one ring', 'orim''s chant')
   OR lower(card_name) IN ('the one ring', 'orim''s chant');

DO $$
DECLARE
  v_one_ring_card_rows int;
  v_one_ring_hash_rows int;
  v_one_ring_exact_rows int;
  v_one_ring_legacy_rows int;
  v_orim_card_rows int;
  v_orim_hash_rows int;
  v_orim_exact_rows int;
  v_orim_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_one_ring_card_rows
  FROM cards
  WHERE lower(name) = 'the one ring';

  SELECT count(*) INTO v_one_ring_hash_rows
  FROM cards
  WHERE lower(name) = 'the one ring'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '31d30901b663f08a6862c5b76f174887';

  SELECT count(*) INTO v_one_ring_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'the one ring'
    AND logical_rule_key = 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
    AND effect_json->>'effect' = 'draw_engine'
    AND effect_json->>'burden' = 'true'
    AND effect_json->>'draw_on_enter' = 'false'
    AND effect_json->>'protection_from_everything_on_enter' = 'true'
    AND effect_json->>'activated_burden_draw' = 'true'
    AND effect_json->>'activation_requires_tap' = 'true'
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable');

  SELECT count(*) INTO v_one_ring_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'the one ring'
    AND logical_rule_key <> 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
    AND effect_json->>'effect' = 'draw_engine'
    AND (
      NOT (effect_json ? 'draw_on_enter')
      OR NOT (effect_json ? 'protection_from_everything_on_enter')
      OR NOT (effect_json ? 'activated_burden_draw')
    )
    AND execution_status IN ('auto', 'executable', 'review_only');

  SELECT count(*) INTO v_orim_card_rows
  FROM cards
  WHERE lower(name) = 'orim''s chant';

  SELECT count(*) INTO v_orim_hash_rows
  FROM cards
  WHERE lower(name) = 'orim''s chant'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '3eea7a9ed9e829743964806f5f56cf75';

  SELECT count(*) INTO v_orim_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'orim''s chant'
    AND logical_rule_key = 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
    AND effect_json->>'effect' = 'silence_spell'
    AND effect_json->>'instant' = 'true'
    AND effect_json->>'kicker_prevent_attacks' = 'true'
    AND effect_json->>'prevent_attacks_if_kicked' = 'true'
    AND effect_json->>'kicker_cost' = '{W}'
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable');

  SELECT count(*) INTO v_orim_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'orim''s chant'
    AND logical_rule_key <> 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
    AND effect_json->>'effect' IN ('silence_spell', 'silence_opponents')
    AND (
      NOT (effect_json ? 'kicker_prevent_attacks')
      OR NOT (effect_json ? 'prevent_attacks_if_kicked')
    )
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_one_ring_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG025 precondition failed: The One Ring card rows=% expected 1', v_one_ring_card_rows;
  END IF;
  IF v_one_ring_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG025 precondition failed: The One Ring oracle hash rows=% expected 1', v_one_ring_hash_rows;
  END IF;
  IF v_one_ring_exact_rows = 0 AND v_one_ring_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG025 precondition failed: The One Ring has no exact rule and no legacy draw_engine row to repair';
  END IF;
  IF v_orim_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG025 precondition failed: Orim''s Chant card rows=% expected 1', v_orim_card_rows;
  END IF;
  IF v_orim_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG025 precondition failed: Orim''s Chant oracle hash rows=% expected 1', v_orim_hash_rows;
  END IF;
  IF v_orim_exact_rows = 0 AND v_orim_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG025 precondition failed: Orim''s Chant has no exact rule and no legacy silence row to repair';
  END IF;
END $$;

WITH target_rules AS (
  SELECT *
  FROM (
    VALUES
      (
        'the one ring',
        'The One Ring',
        'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1',
        '31d30901b663f08a6862c5b76f174887',
        jsonb_build_object(
          'effect', 'draw_engine',
          'burden', true,
          'draw_on_enter', false,
          'protection_from_everything_on_enter', true,
          'activated_burden_draw', true,
          'activation_requires_tap', true,
          'battle_model_scope', 'the_one_ring_etb_protection_burden_draw_v1'
        ),
        jsonb_build_object(
          'category', 'draw',
          'effect', 'draw_engine'
        ),
        'PG-025: promoted The One Ring runtime-correct battle semantics. Oracle text grants protection from everything on cast/ETB until next turn, does not draw on ETB, loses life on upkeep for burden counters, and taps to add a burden counter then draw that many cards.'
      ),
      (
        'orim''s chant',
        'Orim''s Chant',
        'battle_rule_v1:2332a82b6395a065b6516702d3e326c7',
        '3eea7a9ed9e829743964806f5f56cf75',
        jsonb_build_object(
          'effect', 'silence_spell',
          'instant', true,
          'kicker_prevent_attacks', true,
          'kicker_cost', '{W}',
          'prevent_attacks_if_kicked', true,
          'battle_model_scope', 'orims_chant_kicker_attack_prevention_v1'
        ),
        jsonb_build_object(
          'category', 'protection',
          'effect', 'silence_spell',
          'timing', 'instant'
        ),
        'PG-025: promoted Orim''s Chant kicked combat-prevention semantics. Oracle text targets one player for spell lock this turn; if kicked, creatures cannot attack this turn.'
      )
  ) AS rules(
    normalized_name,
    card_name,
    logical_rule_key,
    oracle_hash,
    effect_json,
    deck_role_json,
    notes
  )
),
resolved_cards AS (
  SELECT
    tr.*,
    c.id
  FROM target_rules tr
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
  1.000,
  'verified',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg025',
  now(),
  now(),
  now(),
  now()
FROM resolved_cards
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

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    NULLIF(notes, ''),
    'PG-025 disabled legacy The One Ring draw_engine approximation after promoting ETB protection, no-ETB-draw, and activated burden draw rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg025',
  reviewed_at = now(),
  updated_at = now()
WHERE normalized_name = 'the one ring'
  AND logical_rule_key <> 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
  AND effect_json->>'effect' = 'draw_engine'
  AND (
    NOT (effect_json ? 'draw_on_enter')
    OR NOT (effect_json ? 'protection_from_everything_on_enter')
    OR NOT (effect_json ? 'activated_burden_draw')
  );

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    NULLIF(notes, ''),
    'PG-025 disabled legacy Orim''s Chant silence approximation after promoting kicker attack-prevention rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg025',
  reviewed_at = now(),
  updated_at = now()
WHERE normalized_name = 'orim''s chant'
  AND logical_rule_key <> 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
  AND effect_json->>'effect' IN ('silence_spell', 'silence_opponents')
  AND (
    NOT (effect_json ? 'kicker_prevent_attacks')
    OR NOT (effect_json ? 'prevent_attacks_if_kicked')
  );

DO $$
DECLARE
  v_one_ring_exact_rows int;
  v_one_ring_legacy_rows int;
  v_orim_exact_rows int;
  v_orim_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_one_ring_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'the one ring'
    AND logical_rule_key = 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
    AND effect_json->>'effect' = 'draw_engine'
    AND effect_json->>'burden' = 'true'
    AND effect_json->>'draw_on_enter' = 'false'
    AND effect_json->>'protection_from_everything_on_enter' = 'true'
    AND effect_json->>'activated_burden_draw' = 'true'
    AND effect_json->>'activation_requires_tap' = 'true'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_one_ring_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'the one ring'
    AND logical_rule_key <> 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
    AND effect_json->>'effect' = 'draw_engine'
    AND (
      NOT (effect_json ? 'draw_on_enter')
      OR NOT (effect_json ? 'protection_from_everything_on_enter')
      OR NOT (effect_json ? 'activated_burden_draw')
    )
    AND execution_status IN ('auto', 'executable', 'review_only');

  SELECT count(*) INTO v_orim_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'orim''s chant'
    AND logical_rule_key = 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
    AND effect_json->>'effect' = 'silence_spell'
    AND effect_json->>'instant' = 'true'
    AND effect_json->>'kicker_prevent_attacks' = 'true'
    AND effect_json->>'prevent_attacks_if_kicked' = 'true'
    AND effect_json->>'kicker_cost' = '{W}'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_orim_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'orim''s chant'
    AND logical_rule_key <> 'battle_rule_v1:2332a82b6395a065b6516702d3e326c7'
    AND effect_json->>'effect' IN ('silence_spell', 'silence_opponents')
    AND (
      NOT (effect_json ? 'kicker_prevent_attacks')
      OR NOT (effect_json ? 'prevent_attacks_if_kicked')
    )
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_one_ring_exact_rows <> 1 THEN
    RAISE EXCEPTION 'PG025 postcondition failed: The One Ring exact executable rule rows=% expected 1', v_one_ring_exact_rows;
  END IF;
  IF v_one_ring_legacy_rows <> 0 THEN
    RAISE EXCEPTION 'PG025 postcondition failed: The One Ring legacy executable draw_engine rows=% expected 0', v_one_ring_legacy_rows;
  END IF;
  IF v_orim_exact_rows <> 1 THEN
    RAISE EXCEPTION 'PG025 postcondition failed: Orim''s Chant exact executable rule rows=% expected 1', v_orim_exact_rows;
  END IF;
  IF v_orim_legacy_rows <> 0 THEN
    RAISE EXCEPTION 'PG025 postcondition failed: Orim''s Chant legacy executable silence rows=% expected 0', v_orim_legacy_rows;
  END IF;
END $$;

SELECT
  'pg025_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name IN ('the one ring', 'orim''s chant')
ORDER BY card_name, source, review_status, execution_status, logical_rule_key;

COMMIT;
