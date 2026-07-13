BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg860_landfall_self_boost_new_server_lan_20260713_032448 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('akoum hellhound', 'canopy baloth', 'hedron rover', 'hedron scrabbler', 'scythe leopard', 'snapping gnarlid', 'steppe lynx', 'territorial baloth', 'valakut predator')
   OR normalized_name LIKE 'akoum hellhound // %'
   OR normalized_name LIKE 'canopy baloth // %'
   OR normalized_name LIKE 'hedron rover // %'
   OR normalized_name LIKE 'hedron scrabbler // %'
   OR normalized_name LIKE 'scythe leopard // %'
   OR normalized_name LIKE 'snapping gnarlid // %'
   OR normalized_name LIKE 'steppe lynx // %'
   OR normalized_name LIKE 'territorial baloth // %'
   OR normalized_name LIKE 'valakut predator // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('akoum hellhound', 'Akoum Hellhound', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumHellhound translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('canopy baloth', 'Canopy Baloth', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CanopyBaloth translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hedron rover', 'Hedron Rover', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HedronRover translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hedron scrabbler', 'Hedron Scrabbler', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HedronScrabbler translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scythe leopard', 'Scythe Leopard', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScytheLeopard translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('snapping gnarlid', 'Snapping Gnarlid', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SnappingGnarlid translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steppe lynx', 'Steppe Lynx', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteppeLynx translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('territorial baloth', 'Territorial Baloth', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerritorialBaloth translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('valakut predator', 'Valakut Predator', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ValakutPredator translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('akoum hellhound', 'Akoum Hellhound', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumHellhound translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('canopy baloth', 'Canopy Baloth', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CanopyBaloth translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hedron rover', 'Hedron Rover', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HedronRover translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hedron scrabbler', 'Hedron Scrabbler', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HedronScrabbler translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scythe leopard', 'Scythe Leopard', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScytheLeopard translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('snapping gnarlid', 'Snapping Gnarlid', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SnappingGnarlid translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steppe lynx', 'Steppe Lynx', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteppeLynx translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('territorial baloth', 'Territorial Baloth', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerritorialBaloth translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('valakut predator', 'Valakut Predator', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ValakutPredator translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('akoum hellhound', 'Akoum Hellhound', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumHellhound translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('canopy baloth', 'Canopy Baloth', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CanopyBaloth translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hedron rover', 'Hedron Rover', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HedronRover translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hedron scrabbler', 'Hedron Scrabbler', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HedronScrabbler translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scythe leopard', 'Scythe Leopard', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScytheLeopard translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('snapping gnarlid', 'Snapping Gnarlid', '4e5363696d0a4ba4059ea4866f51e313', 'battle_rule_v1:2ba4ee6bbeae52a5ffbd5e90b414a107', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SnappingGnarlid translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steppe lynx', 'Steppe Lynx', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteppeLynx translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('territorial baloth', 'Territorial Baloth', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerritorialBaloth translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('valakut predator', 'Valakut Predator', '7e252ede6bebc323ac6118190316941f', 'battle_rule_v1:345c1797fecda5bc321a8572fd8a48ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_landfall_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","landfall_self_boost":true,"power_boost":2,"power_delta":2,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":2,"toughness_delta":2,"trigger":"landfall","trigger_effect":"self_stat_modifier_until_eot","xmage_ability_class":"LandfallAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ValakutPredator translated into ManaLoom runtime scope xmage_creature_landfall_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
