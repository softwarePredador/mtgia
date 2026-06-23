BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg102_creative_technique_top_nonland_free_cast_20260623_130933 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'creative technique';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'creative technique'
    AND md5(coalesce(oracle_text, '')) = '98c26337370ce75f10e3e529a94b8ef3';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG102 abort: expected exactly one Creative Technique card row with current Oracle hash, found %', v_card_rows;
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
      'PG102: deprecated stale generated draw_cards shadow after Oracle-backed Creative Technique demonstrate/top-nonland free-cast rule was promoted.'
    )
  WHERE r.normalized_name = 'creative technique'
    AND r.logical_rule_key <> 'battle_rule_v1:fcb6b63cf730c83aa99760cc53bf3dd9'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'creative technique'
    AND md5(coalesce(oracle_text, '')) = '98c26337370ce75f10e3e529a94b8ef3'
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
    'creative technique',
    target_card.id,
    target_card.name,
    '{"battle_model_scope":"shuffle_reveal_top_nonland_exile_free_cast_with_demonstrate_v1","demonstrate":true,"demonstrate_choice_model":"choose_lowest_visible_threat_opponent","demonstrate_copy_model":"controller_copy_and_chosen_opponent_copy","effect":"exile_top_nonland_free_cast","revealed_card_cast_without_paying_mana":true,"shuffle_before_reveal":true,"sorcery":true,"top_reveal_until":"nonland"}'::jsonb,
    '{"category":"engine","effect":"exile_top_nonland_free_cast","role":"demonstrate_top_nonland_free_cast","timing":"sorcery"}'::jsonb,
    'curated',
    0.97,
    'verified',
    2,
    target_card.oracle_hash,
    'PG102: Oracle-backed Creative Technique battle rule. Runtime shuffles, reveals until nonland, exiles the nonland card, casts it from exile without paying mana, and models demonstrate as a controller copy plus a chosen lowest-visible-threat opponent copy.',
    'codex-pg102',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:fcb6b63cf730c83aa99760cc53bf3dd9',
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
