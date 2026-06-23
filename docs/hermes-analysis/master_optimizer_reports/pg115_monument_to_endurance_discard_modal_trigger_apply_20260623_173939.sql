BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg115_monument_to_endurance_discard_modal_trigger_20260623_173939 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'monument to endurance';

DO $$
DECLARE
  v_matched_rows integer;
BEGIN
  SELECT count(c.id)
    INTO v_matched_rows
  FROM public.cards c
  WHERE lower(c.name) = 'monument to endurance'
    AND md5(coalesce(c.oracle_text, '')) = 'a60dc736f7e86e15001c8c7e59ff23c4';

  IF v_matched_rows <> 1 THEN
    RAISE EXCEPTION 'PG115 abort: expected exactly one Oracle-hash-matched Monument to Endurance card row, got %', v_matched_rows;
  END IF;
END $$;

WITH deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG115: deprecated generic passive Monument row before Oracle/XMage-backed discard-modal trigger rule was promoted.'
    )
  WHERE r.normalized_name = 'monument to endurance'
    AND r.logical_rule_key <> 'battle_rule_v1:0ae531be7c36226d3f118c93feab3735'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name
  FROM public.cards
  WHERE lower(name) = 'monument to endurance'
    AND md5(coalesce(oracle_text, '')) = 'a60dc736f7e86e15001c8c7e59ff23c4'
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
    'monument to endurance',
    tc.id,
    tc.name,
    '{
      "ability_kind":"triggered",
      "battle_model_scope":"discard_trigger_choose_unpicked_mode_draw_treasure_life_loss_v1",
      "cmc":3.0,
      "effect":"discard_trigger_modal_draw_treasure_opponent_life_loss",
      "trigger_event":"discard",
      "turn_limited_unique_modes":true,
      "discard_trigger_modes":["draw_card","create_treasure","opponents_lose_3_life"]
    }'::jsonb,
    '{"category":"card_advantage","effect":"discard_trigger_modal_draw_treasure_opponent_life_loss","subtype":"discard_modal_value_engine","timing":"triggered"}'::jsonb,
    'curated',
    0.96,
    'verified',
    2,
    'a60dc736f7e86e15001c8c7e59ff23c4',
    'PG115: Oracle/XMage-backed Monument to Endurance rule. Runtime resolves a discard trigger that can draw one card, create one Treasure, and drain each opponent for 3 life, using each mode at most once per turn.',
    'codex-pg115',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:0ae531be7c36226d3f118c93feab3735',
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
