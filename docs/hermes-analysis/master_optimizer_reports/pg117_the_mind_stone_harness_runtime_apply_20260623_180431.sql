BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg117_the_mind_stone_harness_runtime_20260623_180431 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'the mind stone';

DO $$
DECLARE
  v_matched_rows integer;
BEGIN
  SELECT count(c.id)
    INTO v_matched_rows
  FROM public.cards c
  WHERE lower(c.name) = 'the mind stone'
    AND md5(coalesce(c.oracle_text, '')) = '17bda9d167ae2799376387d03be5681f';

  IF v_matched_rows <> 1 THEN
    RAISE EXCEPTION 'PG117 abort: expected exactly one Oracle-hash-matched The Mind Stone card row, got %', v_matched_rows;
  END IF;
END $$;

WITH target_card AS (
  SELECT id, name
  FROM public.cards
  WHERE lower(name) = 'the mind stone'
    AND md5(coalesce(oracle_text, '')) = '17bda9d167ae2799376387d03be5681f'
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    'the mind stone',
    tc.id,
    tc.name,
    '{
      "battle_model_scope":"legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1",
      "cmc":2.0,
      "effect":"ramp_permanent",
      "harness_activation_cost":"{5}{W}",
      "harness_activation_requires_tap":true,
      "harnessed_blink_target_scope":"other_nonland_permanent_you_control",
      "harnessed_end_step_blink":true,
      "indestructible":true,
      "mana_produced":1,
      "produces":"W"
    }'::jsonb,
    '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_rock_with_harnessed_blink","timing":"persistent"}'::jsonb,
    'curated',
    0.95,
    'verified',
    2,
    '17bda9d167ae2799376387d03be5681f',
    'PG117: Oracle/XMage-backed The Mind Stone runtime. Models a white indestructible mana rock that can be harnessed for a repeatable end-step blink on another nonland permanent you control.',
    'codex-pg117',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53',
    'auto'
  FROM target_card tc
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows
FROM upserted;

COMMIT;
