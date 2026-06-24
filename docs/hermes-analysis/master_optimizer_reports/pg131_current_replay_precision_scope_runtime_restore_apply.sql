BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg131_current_replay_precision_scope_runtime_restore_202 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('wan shi tong, librarian', 'hullbreaker horror', 'teferi, time raveler');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('wan shi tong, librarian', 'Wan Shi Tong, Librarian', 'cec9147cf2498a1c06969597acfea508', 'battle_rule_v1:c18481f9ac5f3681e11384c838d732c9', '{"ability_kind":"triggered","battle_model_scope":"flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1","effect":"creature","etb_add_x_plus_one_counters":true,"etb_draw_half_x_rounded_down":true,"flash":true,"flying":true,"opponent_search_library_add_counter_and_draw":true,"power":1,"toughness":1,"vigilance":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WanShiTongLibrarian mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('hullbreaker horror', 'Hullbreaker Horror', '8339fa3591d36c5d0460156fbf96d8fe', 'battle_rule_v1:e27cba51b13efd4db7efaebf7878b572', '{"ability_kind":"triggered","battle_model_scope":"flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1","cant_be_countered":true,"cast_spell_trigger_bounce_nonland_permanent":true,"cast_spell_trigger_bounce_spell_you_dont_control":true,"effect":"creature","flash":true,"power":7,"toughness":8}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HullbreakerHorror mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('teferi, time raveler', 'Teferi, Time Raveler', '7c2d3586e1633bcaf4f26d7b01a6c266', 'battle_rule_v1:35ae547c02c12ce35e09945d4791f7ad', '{"ability_kind":"static","battle_model_scope":"opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1","effect":"planeswalker","minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw":1,"opponents_can_cast_only_as_sorcery":true,"plus_one_sorceries_have_flash_until_your_next_turn":true,"starting_loyalty":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TeferiTimeRaveler mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON lower(c.name) = p.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('wan shi tong, librarian', 'Wan Shi Tong, Librarian', 'cec9147cf2498a1c06969597acfea508', 'battle_rule_v1:c18481f9ac5f3681e11384c838d732c9', '{"ability_kind":"triggered","battle_model_scope":"flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1","effect":"creature","etb_add_x_plus_one_counters":true,"etb_draw_half_x_rounded_down":true,"flash":true,"flying":true,"opponent_search_library_add_counter_and_draw":true,"power":1,"toughness":1,"vigilance":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WanShiTongLibrarian mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('hullbreaker horror', 'Hullbreaker Horror', '8339fa3591d36c5d0460156fbf96d8fe', 'battle_rule_v1:e27cba51b13efd4db7efaebf7878b572', '{"ability_kind":"triggered","battle_model_scope":"flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1","cant_be_countered":true,"cast_spell_trigger_bounce_nonland_permanent":true,"cast_spell_trigger_bounce_spell_you_dont_control":true,"effect":"creature","flash":true,"power":7,"toughness":8}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HullbreakerHorror mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('teferi, time raveler', 'Teferi, Time Raveler', '7c2d3586e1633bcaf4f26d7b01a6c266', 'battle_rule_v1:35ae547c02c12ce35e09945d4791f7ad', '{"ability_kind":"static","battle_model_scope":"opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1","effect":"planeswalker","minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw":1,"opponents_can_cast_only_as_sorcery":true,"plus_one_sorceries_have_flash_until_your_next_turn":true,"starting_loyalty":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TeferiTimeRaveler mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('wan shi tong, librarian', 'Wan Shi Tong, Librarian', 'cec9147cf2498a1c06969597acfea508', 'battle_rule_v1:c18481f9ac5f3681e11384c838d732c9', '{"ability_kind":"triggered","battle_model_scope":"flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1","effect":"creature","etb_add_x_plus_one_counters":true,"etb_draw_half_x_rounded_down":true,"flash":true,"flying":true,"opponent_search_library_add_counter_and_draw":true,"power":1,"toughness":1,"vigilance":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WanShiTongLibrarian mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('hullbreaker horror', 'Hullbreaker Horror', '8339fa3591d36c5d0460156fbf96d8fe', 'battle_rule_v1:e27cba51b13efd4db7efaebf7878b572', '{"ability_kind":"triggered","battle_model_scope":"flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1","cant_be_countered":true,"cast_spell_trigger_bounce_nonland_permanent":true,"cast_spell_trigger_bounce_spell_you_dont_control":true,"effect":"creature","flash":true,"power":7,"toughness":8}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HullbreakerHorror mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('teferi, time raveler', 'Teferi, Time Raveler', '7c2d3586e1633bcaf4f26d7b01a6c266', 'battle_rule_v1:35ae547c02c12ce35e09945d4791f7ad', '{"ability_kind":"static","battle_model_scope":"opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1","effect":"planeswalker","minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw":1,"opponents_can_cast_only_as_sorcery":true,"plus_one_sorceries_have_flash_until_your_next_turn":true,"starting_loyalty":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TeferiTimeRaveler mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON lower(c.name) = p.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes
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
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
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
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
