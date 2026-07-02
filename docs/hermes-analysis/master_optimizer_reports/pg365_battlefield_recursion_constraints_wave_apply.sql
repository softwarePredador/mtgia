BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg365_battlefield_recursion_constraints_wave_20260702_08 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('othelm, sigardian outcast', 'ramosian revivalist', 'rise to glory', 'squirming emergence')
   OR normalized_name LIKE 'othelm, sigardian outcast // %'
   OR normalized_name LIKE 'ramosian revivalist // %'
   OR normalized_name LIKE 'rise to glory // %'
   OR normalized_name LIKE 'squirming emergence // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('othelm, sigardian outcast', 'Othelm, Sigardian Outcast', '892dac96b806675afaa11bc15c65e08c', 'battle_rule_v1:aeea4d9d5b81f866734a71f3d2e0450e', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OthelmSigardianOutcast translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ramosian revivalist', 'Ramosian Revivalist', 'ee63e43e30e9c420b425349ed602e643', 'battle_rule_v1:80246cb1bf856d9fbb94d600bd79b278', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":6,"graveyard_to_hand_activation_cost_mana":"{6}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"rebel_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RamosianRevivalist translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise to glory', 'Rise to Glory', '16043bda3ddbf4b4db3790524911ec02', 'battle_rule_v1:b59b25c2465e54f30f187c5095904a74', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1","battlefield_controller":"self","destination":"battlefield","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"},{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"aura_card","target_constraints":{"controller":"self","subtypes":["aura"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"}],"sorcery":true,"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseToGlory translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squirming emergence', 'Squirming Emergence', 'f098fbc9d600c3db40c9aecc256bded1', 'battle_rule_v1:4c3bbbeabd8eae3fbec132c57726c027', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle"],"controller":"self","exclude_card_types":["land"],"mana_value_max_source":"graveyard_permanent_count","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","target_mana_value_max_from_graveyard_permanent_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SquirmingEmergence translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('othelm, sigardian outcast', 'Othelm, Sigardian Outcast', '892dac96b806675afaa11bc15c65e08c', 'battle_rule_v1:aeea4d9d5b81f866734a71f3d2e0450e', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OthelmSigardianOutcast translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ramosian revivalist', 'Ramosian Revivalist', 'ee63e43e30e9c420b425349ed602e643', 'battle_rule_v1:80246cb1bf856d9fbb94d600bd79b278', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":6,"graveyard_to_hand_activation_cost_mana":"{6}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"rebel_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RamosianRevivalist translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise to glory', 'Rise to Glory', '16043bda3ddbf4b4db3790524911ec02', 'battle_rule_v1:b59b25c2465e54f30f187c5095904a74', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1","battlefield_controller":"self","destination":"battlefield","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"},{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"aura_card","target_constraints":{"controller":"self","subtypes":["aura"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"}],"sorcery":true,"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseToGlory translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squirming emergence', 'Squirming Emergence', 'f098fbc9d600c3db40c9aecc256bded1', 'battle_rule_v1:4c3bbbeabd8eae3fbec132c57726c027', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle"],"controller":"self","exclude_card_types":["land"],"mana_value_max_source":"graveyard_permanent_count","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","target_mana_value_max_from_graveyard_permanent_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SquirmingEmergence translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('othelm, sigardian outcast', 'Othelm, Sigardian Outcast', '892dac96b806675afaa11bc15c65e08c', 'battle_rule_v1:aeea4d9d5b81f866734a71f3d2e0450e', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_from_battlefield_this_turn":true,"graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","graveyard_from_battlefield_this_turn":true,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OthelmSigardianOutcast translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ramosian revivalist', 'Ramosian Revivalist', 'ee63e43e30e9c420b425349ed602e643', 'battle_rule_v1:80246cb1bf856d9fbb94d600bd79b278', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":false,"activation_cost_colors":[],"activation_cost_generic":6,"activation_cost_mana":"{6}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":6,"graveyard_to_hand_activation_cost_mana":"{6}","graveyard_to_hand_activation_requires_sacrifice":false,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_mana_value_max":5,"graveyard_to_hand_target":"rebel_permanent","graveyard_to_hand_target_count":1,"recursion_mana_value_max":5,"target":"rebel_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":5,"subtypes":["rebel"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"rebel_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RamosianRevivalist translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise to glory', 'Rise to Glory', '16043bda3ddbf4b4db3790524911ec02', 'battle_rule_v1:b59b25c2465e54f30f187c5095904a74', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1","battlefield_controller":"self","destination":"battlefield","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"},{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"aura_card","target_constraints":{"controller":"self","subtypes":["aura"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self"}],"sorcery":true,"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseToGlory translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('squirming emergence', 'Squirming Emergence', 'f098fbc9d600c3db40c9aecc256bded1', 'battle_rule_v1:4c3bbbeabd8eae3fbec132c57726c027', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle"],"controller":"self","exclude_card_types":["land"],"mana_value_max_source":"graveyard_permanent_count","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","target_mana_value_max_from_graveyard_permanent_count":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SquirmingEmergence translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
