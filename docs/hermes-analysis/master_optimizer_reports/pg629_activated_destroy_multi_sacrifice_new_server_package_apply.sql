BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg629_activated_destroy_multi_sacrifice_20260707_180019 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('earthblighter', 'keldon arsonist', 'krark-clan engineers', 'sandstone deadfall')
   OR normalized_name LIKE 'earthblighter // %'
   OR normalized_name LIKE 'keldon arsonist // %'
   OR normalized_name LIKE 'krark-clan engineers // %'
   OR normalized_name LIKE 'sandstone deadfall // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('earthblighter', 'Earthblighter', 'a609a168f73ac8403e9a5bb434e4dd87', 'battle_rule_v1:5a02d463ae3227ecdfa5e79a1dc61f02', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Earthblighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon arsonist', 'Keldon Arsonist', '90a229a35b52b4ff9de4f8c2cf326ad3', 'battle_rule_v1:5fc918ece0734a39ee3c3c769dcf2e90', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonArsonist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krark-clan engineers', 'Krark-Clan Engineers', '2f1cda4d8f42234f9842aa5a97f228cf', 'battle_rule_v1:30271844421547419ce80f41ac149976', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrarkClanEngineers translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sandstone deadfall', 'Sandstone Deadfall', '802dab23ebd4e4fff2c2917fff7cdc24', 'battle_rule_v1:fe81aae4282d4895faf30755ec9f8989', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"artifact","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SandstoneDeadfall translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('earthblighter', 'Earthblighter', 'a609a168f73ac8403e9a5bb434e4dd87', 'battle_rule_v1:5a02d463ae3227ecdfa5e79a1dc61f02', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Earthblighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon arsonist', 'Keldon Arsonist', '90a229a35b52b4ff9de4f8c2cf326ad3', 'battle_rule_v1:5fc918ece0734a39ee3c3c769dcf2e90', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonArsonist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krark-clan engineers', 'Krark-Clan Engineers', '2f1cda4d8f42234f9842aa5a97f228cf', 'battle_rule_v1:30271844421547419ce80f41ac149976', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrarkClanEngineers translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sandstone deadfall', 'Sandstone Deadfall', '802dab23ebd4e4fff2c2917fff7cdc24', 'battle_rule_v1:fe81aae4282d4895faf30755ec9f8989', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"artifact","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SandstoneDeadfall translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('earthblighter', 'Earthblighter', 'a609a168f73ac8403e9a5bb434e4dd87', 'battle_rule_v1:5a02d463ae3227ecdfa5e79a1dc61f02', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Earthblighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon arsonist', 'Keldon Arsonist', '90a229a35b52b4ff9de4f8c2cf326ad3', 'battle_rule_v1:5fc918ece0734a39ee3c3c769dcf2e90', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonArsonist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krark-clan engineers', 'Krark-Clan Engineers', '2f1cda4d8f42234f9842aa5a97f228cf', 'battle_rule_v1:30271844421547419ce80f41ac149976', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrarkClanEngineers translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sandstone deadfall', 'Sandstone Deadfall', '802dab23ebd4e4fff2c2917fff7cdc24', 'battle_rule_v1:fe81aae4282d4895faf30755ec9f8989', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"artifact","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SandstoneDeadfall translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
