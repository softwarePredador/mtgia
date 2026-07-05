BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg473_xmage_permanent_simple_activated_self_boost_until_ AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('foxfire oak', 'frostburn weird', 'loch korrigan', 'parapet watchers')
   OR normalized_name LIKE 'foxfire oak // %'
   OR normalized_name LIKE 'frostburn weird // %'
   OR normalized_name LIKE 'loch korrigan // %'
   OR normalized_name LIKE 'parapet watchers // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('foxfire oak', 'Foxfire Oak', 'f92e4e4511fd16e75e835a1f22dbdb96', 'battle_rule_v1:ced93a57e24cd5ee4b9cac99c146e48f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoxfireOak translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frostburn weird', 'Frostburn Weird', '6631bcede98207ccff056d973ceebfbb', 'battle_rule_v1:bfb84f4b62429cb2c15f03c22f13c634', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrostburnWeird translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loch korrigan', 'Loch Korrigan', '06d2b27101f16017ea92aec1554a69c9', 'battle_rule_v1:0910f17fa438b6dd99c27d522d289385', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LochKorrigan translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('parapet watchers', 'Parapet Watchers', 'c4393a49dad4b6f0b5b699c2f21396a5', 'battle_rule_v1:d91c066b4f00ed65ba374802194ff1c8', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ParapetWatchers translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('foxfire oak', 'Foxfire Oak', 'f92e4e4511fd16e75e835a1f22dbdb96', 'battle_rule_v1:ced93a57e24cd5ee4b9cac99c146e48f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoxfireOak translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frostburn weird', 'Frostburn Weird', '6631bcede98207ccff056d973ceebfbb', 'battle_rule_v1:bfb84f4b62429cb2c15f03c22f13c634', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrostburnWeird translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loch korrigan', 'Loch Korrigan', '06d2b27101f16017ea92aec1554a69c9', 'battle_rule_v1:0910f17fa438b6dd99c27d522d289385', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LochKorrigan translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('parapet watchers', 'Parapet Watchers', 'c4393a49dad4b6f0b5b699c2f21396a5', 'battle_rule_v1:d91c066b4f00ed65ba374802194ff1c8', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ParapetWatchers translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('foxfire oak', 'Foxfire Oak', 'f92e4e4511fd16e75e835a1f22dbdb96', 'battle_rule_v1:ced93a57e24cd5ee4b9cac99c146e48f', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["R/G","R/G","R/G"],"activation_cost_generic":0,"activation_cost_mana":"{R/G}{R/G}{R/G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":3,"power_delta":3,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":0,"toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoxfireOak translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frostburn weird', 'Frostburn Weird', '6631bcede98207ccff056d973ceebfbb', 'battle_rule_v1:bfb84f4b62429cb2c15f03c22f13c634', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/R"],"activation_cost_generic":0,"activation_cost_mana":"{U/R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":-1,"toughness_delta":-1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrostburnWeird translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loch korrigan', 'Loch Korrigan', '06d2b27101f16017ea92aec1554a69c9', 'battle_rule_v1:0910f17fa438b6dd99c27d522d289385', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["U/B"],"activation_cost_generic":0,"activation_cost_mana":"{U/B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":1,"power_delta":1,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LochKorrigan translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('parapet watchers', 'Parapet Watchers', 'c4393a49dad4b6f0b5b699c2f21396a5', 'battle_rule_v1:d91c066b4f00ed65ba374802194ff1c8', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","activated_effect":"self_stat_modifier_until_eot","activation_cost_colors":["W/U"],"activation_cost_generic":0,"activation_cost_mana":"{W/U}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_boost_until_eot_v1","duration":"until_end_of_turn","effect":"creature","power_boost":0,"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_boost":1,"toughness_delta":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ParapetWatchers translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_boost_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
