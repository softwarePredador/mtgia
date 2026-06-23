BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg098_call_forth_tempest_dynamic_damage_20260623_120031 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'call forth the tempest';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'call forth the tempest'
    AND md5(coalesce(oracle_text, '')) = '5e76c466448cabbfd764e746566b41c1';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG098 abort: expected exactly one Call Forth the Tempest card row with current Oracle hash, found %', v_card_rows;
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
      'PG098: deprecated stale Call Forth the Tempest shadow after Oracle-backed dynamic opponent-creature damage rule was promoted.'
    )
  WHERE r.normalized_name = 'call forth the tempest'
    AND r.logical_rule_key <> 'battle_rule_v1:f1b2e00fe7ffd5fcdf4d0ab90bdd9739'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'call forth the tempest'
    AND md5(coalesce(oracle_text, '')) = '5e76c466448cabbfd764e746566b41c1'
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
    'call forth the tempest',
    target_card.id,
    target_card.name,
    '{"battle_model_scope":"cascade_cascade_other_spells_mana_value_opponent_creature_damage_v1","cascade_execution_status":"annotation_only_no_cascade_executor","cascade_instances":2,"current_spell_included_in_mana_value_ledger":true,"damage_amount_source":"other_spells_cast_mana_value_this_turn","damage_scope":"opponent_creatures","effect":"damage_wipe"}'::jsonb,
    '{"category":"wipe","role":"dynamic_damage_wipe","subtype":"cascade_mana_value_scaled_opponent_creature_damage"}'::jsonb,
    'curated',
    0.97,
    'verified',
    2,
    target_card.oracle_hash,
    'PG098: Oracle-backed Call Forth the Tempest battle rule. Runtime executes opponent-creature-only dynamic damage from other spells cast this turn; cascade is recorded as annotation-only until a full cascade executor exists.',
    'codex-pg098',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:f1b2e00fe7ffd5fcdf4d0ab90bdd9739',
    'auto'
  FROM target_card
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
