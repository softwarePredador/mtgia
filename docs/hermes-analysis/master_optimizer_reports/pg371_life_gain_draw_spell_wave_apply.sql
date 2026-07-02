BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg371_life_gain_draw_spell_wave_20260702_104450 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dosan''s oldest chant', 'resupply', 'revitalize', 'reviving dose', 'ritual of rejuvenation')
   OR normalized_name LIKE 'dosan''s oldest chant // %'
   OR normalized_name LIKE 'resupply // %'
   OR normalized_name LIKE 'revitalize // %'
   OR normalized_name LIKE 'reviving dose // %'
   OR normalized_name LIKE 'ritual of rejuvenation // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dosan''s oldest chant', 'Dosan''s Oldest Chant', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:845cf002f1ea5f405217669601cd4aff', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"life_gain_amount":6,"sorcery":true,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DosansOldestChant translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resupply', 'Resupply', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:48e6975a5607f029b81b95b3e5c06041', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":6,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Resupply translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revitalize', 'Revitalize', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revitalize translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reviving dose', 'Reviving Dose', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevivingDose translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ritual of rejuvenation', 'Ritual of Rejuvenation', '550480e66f0402692883f60b05c7f038', 'battle_rule_v1:c5be6b33be518357ce817f1ab3f2dedd', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":4,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":4,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RitualOfRejuvenation translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dosan''s oldest chant', 'Dosan''s Oldest Chant', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:845cf002f1ea5f405217669601cd4aff', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"life_gain_amount":6,"sorcery":true,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DosansOldestChant translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resupply', 'Resupply', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:48e6975a5607f029b81b95b3e5c06041', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":6,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Resupply translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revitalize', 'Revitalize', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revitalize translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reviving dose', 'Reviving Dose', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevivingDose translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ritual of rejuvenation', 'Ritual of Rejuvenation', '550480e66f0402692883f60b05c7f038', 'battle_rule_v1:c5be6b33be518357ce817f1ab3f2dedd', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":4,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":4,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RitualOfRejuvenation translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dosan''s oldest chant', 'Dosan''s Oldest Chant', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:845cf002f1ea5f405217669601cd4aff', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"life_gain_amount":6,"sorcery":true,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DosansOldestChant translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resupply', 'Resupply', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:48e6975a5607f029b81b95b3e5c06041', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":6,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Resupply translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revitalize', 'Revitalize', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revitalize translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reviving dose', 'Reviving Dose', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevivingDose translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ritual of rejuvenation', 'Ritual of Rejuvenation', '550480e66f0402692883f60b05c7f038', 'battle_rule_v1:c5be6b33be518357ce817f1ab3f2dedd', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":4,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":4,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RitualOfRejuvenation translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    p.notes,
    p.shadow_handling
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
