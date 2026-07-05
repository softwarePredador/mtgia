BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg461_xmage_fixed_damage_scry_new_server_20260705_005558 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bolt of keranos', 'fateful end', 'jaya''s firenado', 'jaya''s greeting', 'lightning javelin', 'magma jet', 'piercing light', 'spark jolt')
   OR normalized_name LIKE 'bolt of keranos // %'
   OR normalized_name LIKE 'fateful end // %'
   OR normalized_name LIKE 'jaya''s firenado // %'
   OR normalized_name LIKE 'jaya''s greeting // %'
   OR normalized_name LIKE 'lightning javelin // %'
   OR normalized_name LIKE 'magma jet // %'
   OR normalized_name LIKE 'piercing light // %'
   OR normalized_name LIKE 'spark jolt // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bolt of keranos', 'Bolt of Keranos', 'f7af69e62d9a620a79080fb85154e8d8', 'battle_rule_v1:7d2dedb22a454159c2095cbba473e084', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoltOfKeranos translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fateful end', 'Fateful End', '2eb97b9c0d6d264dce7b737ec2f4fad6', 'battle_rule_v1:fe587a8b1df04e95a772dd857be9e371', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FatefulEnd translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaya''s firenado', 'Jaya''s Firenado', '8465819e1591b106d235dadc338128c2', 'battle_rule_v1:3814e41d16c39da041348eff6f70096c', '{"_composite_rule_components":[{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":5,"effect":"direct_damage","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":5,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JayasFirenado translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaya''s greeting', 'Jaya''s Greeting', '1a63ca68d489150ea2be076b19d67ffd', 'battle_rule_v1:3e7f8466c340b24cf825ac06728d2206', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JayasGreeting translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning javelin', 'Lightning Javelin', 'ec319fd220944f2493d6c593182916e6', 'battle_rule_v1:7d2dedb22a454159c2095cbba473e084', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningJavelin translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magma jet', 'Magma Jet', '990237079285041e7c058a05df99b249', 'battle_rule_v1:e9367b59ce30696374b6242096cded2b', '{"_composite_rule_components":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":2,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":2,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":2,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaJet translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piercing light', 'Piercing Light', '3f4b0135c35f3e85876456c4cf713436', 'battle_rule_v1:1b7aa3f0022f037d21c58521dc536a29', '{"_composite_rule_components":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":2,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":2,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiercingLight translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spark jolt', 'Spark Jolt', '436527c601bf60a1aa885109c529800e', 'battle_rule_v1:0b58ff6a856f01f94b39265138acc9ad', '{"_composite_rule_components":[{"amount":1,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":1,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":1,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":1,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkJolt translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bolt of keranos', 'Bolt of Keranos', 'f7af69e62d9a620a79080fb85154e8d8', 'battle_rule_v1:7d2dedb22a454159c2095cbba473e084', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoltOfKeranos translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fateful end', 'Fateful End', '2eb97b9c0d6d264dce7b737ec2f4fad6', 'battle_rule_v1:fe587a8b1df04e95a772dd857be9e371', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FatefulEnd translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaya''s firenado', 'Jaya''s Firenado', '8465819e1591b106d235dadc338128c2', 'battle_rule_v1:3814e41d16c39da041348eff6f70096c', '{"_composite_rule_components":[{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":5,"effect":"direct_damage","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":5,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JayasFirenado translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaya''s greeting', 'Jaya''s Greeting', '1a63ca68d489150ea2be076b19d67ffd', 'battle_rule_v1:3e7f8466c340b24cf825ac06728d2206', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JayasGreeting translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning javelin', 'Lightning Javelin', 'ec319fd220944f2493d6c593182916e6', 'battle_rule_v1:7d2dedb22a454159c2095cbba473e084', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningJavelin translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magma jet', 'Magma Jet', '990237079285041e7c058a05df99b249', 'battle_rule_v1:e9367b59ce30696374b6242096cded2b', '{"_composite_rule_components":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":2,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":2,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":2,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaJet translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piercing light', 'Piercing Light', '3f4b0135c35f3e85876456c4cf713436', 'battle_rule_v1:1b7aa3f0022f037d21c58521dc536a29', '{"_composite_rule_components":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":2,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":2,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiercingLight translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spark jolt', 'Spark Jolt', '436527c601bf60a1aa885109c529800e', 'battle_rule_v1:0b58ff6a856f01f94b39265138acc9ad', '{"_composite_rule_components":[{"amount":1,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":1,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":1,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":1,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkJolt translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bolt of keranos', 'Bolt of Keranos', 'f7af69e62d9a620a79080fb85154e8d8', 'battle_rule_v1:7d2dedb22a454159c2095cbba473e084', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoltOfKeranos translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fateful end', 'Fateful End', '2eb97b9c0d6d264dce7b737ec2f4fad6', 'battle_rule_v1:fe587a8b1df04e95a772dd857be9e371', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FatefulEnd translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaya''s firenado', 'Jaya''s Firenado', '8465819e1591b106d235dadc338128c2', 'battle_rule_v1:3814e41d16c39da041348eff6f70096c', '{"_composite_rule_components":[{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":5,"effect":"direct_damage","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":5,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JayasFirenado translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaya''s greeting', 'Jaya''s Greeting', '1a63ca68d489150ea2be076b19d67ffd', 'battle_rule_v1:3e7f8466c340b24cf825ac06728d2206', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JayasGreeting translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning javelin', 'Lightning Javelin', 'ec319fd220944f2493d6c593182916e6', 'battle_rule_v1:7d2dedb22a454159c2095cbba473e084', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":3,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningJavelin translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magma jet', 'Magma Jet', '990237079285041e7c058a05df99b249', 'battle_rule_v1:e9367b59ce30696374b6242096cded2b', '{"_composite_rule_components":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":2,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":2,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":2,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaJet translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piercing light', 'Piercing Light', '3f4b0135c35f3e85876456c4cf713436', 'battle_rule_v1:1b7aa3f0022f037d21c58521dc536a29', '{"_composite_rule_components":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":2,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":2,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiercingLight translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spark jolt', 'Spark Jolt', '436527c601bf60a1aa885109c529800e', 'battle_rule_v1:0b58ff6a856f01f94b39265138acc9ad', '{"_composite_rule_components":[{"amount":1,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":1,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"amount":1,"battle_model_scope":"xmage_fixed_damage_target_and_scry_spell_v1","damage":1,"effect":"composite_resolution","instant":true,"resolution_order":"damage_then_scry","scry_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkJolt translated into ManaLoom runtime scope xmage_fixed_damage_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
