BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg171_draw_engines_and_land_tutors_20260624_121147 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('mystic remora', 'rhystic study', 'crop rotation', 'elvish reclaimer')
   OR normalized_name LIKE 'mystic remora // %'
   OR normalized_name LIKE 'rhystic study // %'
   OR normalized_name LIKE 'crop rotation // %'
   OR normalized_name LIKE 'elvish reclaimer // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('mystic remora', 'Mystic Remora', '05eb27f7618511c39512cf5a6d93231d', 'battle_rule_v1:91908863a3c983e6d30a2ff99cf41fdb', '{"ability_kind":"triggered","battle_model_scope":"opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1","cumulative_upkeep_generic":1,"draw_on_enter":false,"effect":"draw_engine","tax":4,"trigger":"opponent_noncreature_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticRemora mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rhystic study', 'Rhystic Study', 'f745d1b0ae8acc8c593efb5b3e36ae97', 'battle_rule_v1:79b27c9590580c68ac39779ee48644e9', '{"ability_kind":"triggered","battle_model_scope":"opponent_spell_pay_one_or_draw_engine_v1","draw_on_enter":false,"effect":"draw_engine","tax":1,"trigger":"opponent_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RhysticStudy mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crop rotation', 'Crop Rotation', '67869230ccb8b4499893e14915ca8b14', 'battle_rule_v1:bdce68609ebf3349f35a5e81b6bb2e22', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_land_for_any_land_to_battlefield_untapped_v1","effect":"land_ramp","instant":true,"land_count":1,"land_enters_tapped":false,"lands_to_battlefield":1,"requires_sacrifice_land":true,"tutor_target":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CropRotation mapped to family land_ramp; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish reclaimer', 'Elvish Reclaimer', 'dfd0be9a38fadd0931f1c0f6f06aba74', 'battle_rule_v1:a702be88d777164eaa496746ae78bae2', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1","effect":"creature","land_count":1,"land_enters_tapped":true,"land_tutor_activated":true,"lands_to_battlefield":1,"plus_two_two_if_three_lands_in_your_graveyard":true,"power":1,"requires_sacrifice_land":true,"toughness":2,"tutor_target":"land"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishReclaimer mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
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
    ('mystic remora', 'Mystic Remora', '05eb27f7618511c39512cf5a6d93231d', 'battle_rule_v1:91908863a3c983e6d30a2ff99cf41fdb', '{"ability_kind":"triggered","battle_model_scope":"opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1","cumulative_upkeep_generic":1,"draw_on_enter":false,"effect":"draw_engine","tax":4,"trigger":"opponent_noncreature_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticRemora mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rhystic study', 'Rhystic Study', 'f745d1b0ae8acc8c593efb5b3e36ae97', 'battle_rule_v1:79b27c9590580c68ac39779ee48644e9', '{"ability_kind":"triggered","battle_model_scope":"opponent_spell_pay_one_or_draw_engine_v1","draw_on_enter":false,"effect":"draw_engine","tax":1,"trigger":"opponent_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RhysticStudy mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crop rotation', 'Crop Rotation', '67869230ccb8b4499893e14915ca8b14', 'battle_rule_v1:bdce68609ebf3349f35a5e81b6bb2e22', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_land_for_any_land_to_battlefield_untapped_v1","effect":"land_ramp","instant":true,"land_count":1,"land_enters_tapped":false,"lands_to_battlefield":1,"requires_sacrifice_land":true,"tutor_target":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CropRotation mapped to family land_ramp; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish reclaimer', 'Elvish Reclaimer', 'dfd0be9a38fadd0931f1c0f6f06aba74', 'battle_rule_v1:a702be88d777164eaa496746ae78bae2', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1","effect":"creature","land_count":1,"land_enters_tapped":true,"land_tutor_activated":true,"lands_to_battlefield":1,"plus_two_two_if_three_lands_in_your_graveyard":true,"power":1,"requires_sacrifice_land":true,"toughness":2,"tutor_target":"land"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishReclaimer mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('mystic remora', 'Mystic Remora', '05eb27f7618511c39512cf5a6d93231d', 'battle_rule_v1:91908863a3c983e6d30a2ff99cf41fdb', '{"ability_kind":"triggered","battle_model_scope":"opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1","cumulative_upkeep_generic":1,"draw_on_enter":false,"effect":"draw_engine","tax":4,"trigger":"opponent_noncreature_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticRemora mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rhystic study', 'Rhystic Study', 'f745d1b0ae8acc8c593efb5b3e36ae97', 'battle_rule_v1:79b27c9590580c68ac39779ee48644e9', '{"ability_kind":"triggered","battle_model_scope":"opponent_spell_pay_one_or_draw_engine_v1","draw_on_enter":false,"effect":"draw_engine","tax":1,"trigger":"opponent_spell"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RhysticStudy mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crop rotation', 'Crop Rotation', '67869230ccb8b4499893e14915ca8b14', 'battle_rule_v1:bdce68609ebf3349f35a5e81b6bb2e22', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_land_for_any_land_to_battlefield_untapped_v1","effect":"land_ramp","instant":true,"land_count":1,"land_enters_tapped":false,"lands_to_battlefield":1,"requires_sacrifice_land":true,"tutor_target":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CropRotation mapped to family land_ramp; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish reclaimer', 'Elvish Reclaimer', 'dfd0be9a38fadd0931f1c0f6f06aba74', 'battle_rule_v1:a702be88d777164eaa496746ae78bae2', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1","effect":"creature","land_count":1,"land_enters_tapped":true,"land_tutor_activated":true,"lands_to_battlefield":1,"plus_two_two_if_three_lands_in_your_graveyard":true,"power":1,"requires_sacrifice_land":true,"toughness":2,"tutor_target":"land"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishReclaimer mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
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
