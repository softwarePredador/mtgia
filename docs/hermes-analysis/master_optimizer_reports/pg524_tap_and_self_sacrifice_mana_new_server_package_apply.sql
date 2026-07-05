BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.xmage_pg524_tap_and_self_sacrifice_mana_20260705_190617 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('eye of ramos', 'heart of ramos', 'horn of ramos', 'skull of ramos', 'tooth of ramos')
   OR normalized_name LIKE 'eye of ramos // %'
   OR normalized_name LIKE 'heart of ramos // %'
   OR normalized_name LIKE 'horn of ramos // %'
   OR normalized_name LIKE 'skull of ramos // %'
   OR normalized_name LIKE 'tooth of ramos // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eye of ramos', 'Eye of Ramos', '6f652cb7ac056ddfc5e4213753f0df80', 'battle_rule_v1:cebb0acee193419e9fdc9340f293e607', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["U"],"produces":"U","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["U"],"sacrifice_produces":"U","xmage_ability_classes":["BlueManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlueManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('heart of ramos', 'Heart of Ramos', '26b3e2b5a380b8d9998b1054fc500690', 'battle_rule_v1:e1af4e70352a8b7e668917359f2c020f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["R"],"sacrifice_produces":"R","xmage_ability_classes":["RedManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["RedManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horn of ramos', 'Horn of Ramos', '291e4d62cfb289ce58695ddaf27db585', 'battle_rule_v1:149688a3e0852130a77d37a899da3ede', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["G"],"produces":"G","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["G"],"sacrifice_produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["GreenManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HornOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skull of ramos', 'Skull of Ramos', 'f5afc49a19163867d1d6ed10a9bd7192', 'battle_rule_v1:9ea6c346cb56167508e401c63aac6e5f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["B"],"produces":"B","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["B"],"sacrifice_produces":"B","xmage_ability_classes":["BlackManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlackManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkullOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tooth of ramos', 'Tooth of Ramos', 'b24169ac0da54a32bade58cc60a0b2ef', 'battle_rule_v1:51cc15772f2a262e43a834ecc03b9c7d', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["W"],"produces":"W","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["W"],"sacrifice_produces":"W","xmage_ability_classes":["SimpleManaAbility","WhiteManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToothOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('eye of ramos', 'Eye of Ramos', '6f652cb7ac056ddfc5e4213753f0df80', 'battle_rule_v1:cebb0acee193419e9fdc9340f293e607', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["U"],"produces":"U","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["U"],"sacrifice_produces":"U","xmage_ability_classes":["BlueManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlueManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('heart of ramos', 'Heart of Ramos', '26b3e2b5a380b8d9998b1054fc500690', 'battle_rule_v1:e1af4e70352a8b7e668917359f2c020f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["R"],"sacrifice_produces":"R","xmage_ability_classes":["RedManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["RedManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horn of ramos', 'Horn of Ramos', '291e4d62cfb289ce58695ddaf27db585', 'battle_rule_v1:149688a3e0852130a77d37a899da3ede', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["G"],"produces":"G","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["G"],"sacrifice_produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["GreenManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HornOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skull of ramos', 'Skull of Ramos', 'f5afc49a19163867d1d6ed10a9bd7192', 'battle_rule_v1:9ea6c346cb56167508e401c63aac6e5f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["B"],"produces":"B","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["B"],"sacrifice_produces":"B","xmage_ability_classes":["BlackManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlackManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkullOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tooth of ramos', 'Tooth of Ramos', 'b24169ac0da54a32bade58cc60a0b2ef', 'battle_rule_v1:51cc15772f2a262e43a834ecc03b9c7d', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["W"],"produces":"W","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["W"],"sacrifice_produces":"W","xmage_ability_classes":["SimpleManaAbility","WhiteManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToothOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('eye of ramos', 'Eye of Ramos', '6f652cb7ac056ddfc5e4213753f0df80', 'battle_rule_v1:cebb0acee193419e9fdc9340f293e607', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["U"],"produces":"U","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["U"],"sacrifice_produces":"U","xmage_ability_classes":["BlueManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlueManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('heart of ramos', 'Heart of Ramos', '26b3e2b5a380b8d9998b1054fc500690', 'battle_rule_v1:e1af4e70352a8b7e668917359f2c020f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["R"],"sacrifice_produces":"R","xmage_ability_classes":["RedManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["RedManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horn of ramos', 'Horn of Ramos', '291e4d62cfb289ce58695ddaf27db585', 'battle_rule_v1:149688a3e0852130a77d37a899da3ede', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["G"],"produces":"G","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["G"],"sacrifice_produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["GreenManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HornOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skull of ramos', 'Skull of Ramos', 'f5afc49a19163867d1d6ed10a9bd7192', 'battle_rule_v1:9ea6c346cb56167508e401c63aac6e5f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["B"],"produces":"B","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["B"],"sacrifice_produces":"B","xmage_ability_classes":["BlackManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlackManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkullOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tooth of ramos', 'Tooth of Ramos', 'b24169ac0da54a32bade58cc60a0b2ef', 'battle_rule_v1:51cc15772f2a262e43a834ecc03b9c7d', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["W"],"produces":"W","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["W"],"sacrifice_produces":"W","xmage_ability_classes":["SimpleManaAbility","WhiteManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToothOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
