BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg556_dynamic_life_gain_new_server_dynam_20260706_065301 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('blessed reversal', 'bountiful harvest', 'festival of trokin', 'fruition', 'gerrard''s wisdom', 'invigorating falls', 'joyous respite', 'landbind ritual', 'peach garden oath', 'presence of the wise', 'toil to renown', 'wandering stream')
   OR normalized_name LIKE 'blessed reversal // %'
   OR normalized_name LIKE 'bountiful harvest // %'
   OR normalized_name LIKE 'festival of trokin // %'
   OR normalized_name LIKE 'fruition // %'
   OR normalized_name LIKE 'gerrard''s wisdom // %'
   OR normalized_name LIKE 'invigorating falls // %'
   OR normalized_name LIKE 'joyous respite // %'
   OR normalized_name LIKE 'landbind ritual // %'
   OR normalized_name LIKE 'peach garden oath // %'
   OR normalized_name LIKE 'presence of the wise // %'
   OR normalized_name LIKE 'toil to renown // %'
   OR normalized_name LIKE 'wandering stream // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blessed reversal', 'Blessed Reversal', '823a9c3aa2094d20b96fd4ccb747bbb5', 'battle_rule_v1:a30d89079274b0aeb350157489c02bee', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_combat_state":"attacking","battlefield_count_scope":"opponents_battlefield","effect":"life_total_change","instant":true,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":3,"sorcery":false,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlessedReversal translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bountiful harvest', 'Bountiful Harvest', '80024b4cf516a43e6d18839cf03860e6', 'battle_rule_v1:f609e13e36e1e99fd47c17fe7ea088d2', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BountifulHarvest translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festival of trokin', 'Festival of Trokin', 'c854e6479f1427e2b5d0c823a7244f19', 'battle_rule_v1:898aa76651becdc5799867dd5c4a71b7', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestivalOfTrokin translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fruition', 'Fruition', '1d7d5ee9cf5d1d8f0868d99d5f795919', 'battle_rule_v1:4be0feca617880d6fd5d2b94dd07eee4', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"all_battlefields","battlefield_count_subtypes":["forest"],"effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fruition translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gerrard''s wisdom', 'Gerrard''s Wisdom', '2f3b5a81795c702888749982471cc0b0', 'battle_rule_v1:0dc75e25a69cb2c92abdc1358e2ce3b5', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"controller_hand_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GerrardsWisdom translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invigorating falls', 'Invigorating Falls', 'ade29be2af80d9a21039a33b8d862a31', 'battle_rule_v1:8cc8c8b01bba9fe02e7c3a27f2b387ee', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvigoratingFalls translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joyous respite', 'Joyous Respite', '80024b4cf516a43e6d18839cf03860e6', 'battle_rule_v1:f609e13e36e1e99fd47c17fe7ea088d2', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JoyousRespite translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('landbind ritual', 'Landbind Ritual', 'd84556b6708d3cf7331b93ece9875ae6', 'battle_rule_v1:9e929643503771dc1bec7ee764f4e2c3', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["plains"],"effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LandbindRitual translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('peach garden oath', 'Peach Garden Oath', 'c854e6479f1427e2b5d0c823a7244f19', 'battle_rule_v1:898aa76651becdc5799867dd5c4a71b7', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PeachGardenOath translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('presence of the wise', 'Presence of the Wise', '2f3b5a81795c702888749982471cc0b0', 'battle_rule_v1:0dc75e25a69cb2c92abdc1358e2ce3b5', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"controller_hand_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PresenceOfTheWise translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('toil to renown', 'Toil to Renown', '4521866f2c0302b96432f72194b560b8', 'battle_rule_v1:7cde60c98e70c669b462ea5874e17232', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact","creature","land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_tapped_state":"tapped","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToilToRenown translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wandering stream', 'Wandering Stream', 'fb473dc7cf9f74523c04b406b6d36a8e', 'battle_rule_v1:2672dfc54371d68650a2f9ea851b5990', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"domain_basic_land_types","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WanderingStream translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('blessed reversal', 'Blessed Reversal', '823a9c3aa2094d20b96fd4ccb747bbb5', 'battle_rule_v1:a30d89079274b0aeb350157489c02bee', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_combat_state":"attacking","battlefield_count_scope":"opponents_battlefield","effect":"life_total_change","instant":true,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":3,"sorcery":false,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlessedReversal translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bountiful harvest', 'Bountiful Harvest', '80024b4cf516a43e6d18839cf03860e6', 'battle_rule_v1:f609e13e36e1e99fd47c17fe7ea088d2', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BountifulHarvest translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festival of trokin', 'Festival of Trokin', 'c854e6479f1427e2b5d0c823a7244f19', 'battle_rule_v1:898aa76651becdc5799867dd5c4a71b7', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestivalOfTrokin translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fruition', 'Fruition', '1d7d5ee9cf5d1d8f0868d99d5f795919', 'battle_rule_v1:4be0feca617880d6fd5d2b94dd07eee4', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"all_battlefields","battlefield_count_subtypes":["forest"],"effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fruition translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gerrard''s wisdom', 'Gerrard''s Wisdom', '2f3b5a81795c702888749982471cc0b0', 'battle_rule_v1:0dc75e25a69cb2c92abdc1358e2ce3b5', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"controller_hand_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GerrardsWisdom translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invigorating falls', 'Invigorating Falls', 'ade29be2af80d9a21039a33b8d862a31', 'battle_rule_v1:8cc8c8b01bba9fe02e7c3a27f2b387ee', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvigoratingFalls translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joyous respite', 'Joyous Respite', '80024b4cf516a43e6d18839cf03860e6', 'battle_rule_v1:f609e13e36e1e99fd47c17fe7ea088d2', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JoyousRespite translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('landbind ritual', 'Landbind Ritual', 'd84556b6708d3cf7331b93ece9875ae6', 'battle_rule_v1:9e929643503771dc1bec7ee764f4e2c3', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["plains"],"effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LandbindRitual translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('peach garden oath', 'Peach Garden Oath', 'c854e6479f1427e2b5d0c823a7244f19', 'battle_rule_v1:898aa76651becdc5799867dd5c4a71b7', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PeachGardenOath translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('presence of the wise', 'Presence of the Wise', '2f3b5a81795c702888749982471cc0b0', 'battle_rule_v1:0dc75e25a69cb2c92abdc1358e2ce3b5', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"controller_hand_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PresenceOfTheWise translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('toil to renown', 'Toil to Renown', '4521866f2c0302b96432f72194b560b8', 'battle_rule_v1:7cde60c98e70c669b462ea5874e17232', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact","creature","land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_tapped_state":"tapped","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToilToRenown translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wandering stream', 'Wandering Stream', 'fb473dc7cf9f74523c04b406b6d36a8e', 'battle_rule_v1:2672dfc54371d68650a2f9ea851b5990', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"domain_basic_land_types","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WanderingStream translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('blessed reversal', 'Blessed Reversal', '823a9c3aa2094d20b96fd4ccb747bbb5', 'battle_rule_v1:a30d89079274b0aeb350157489c02bee', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_combat_state":"attacking","battlefield_count_scope":"opponents_battlefield","effect":"life_total_change","instant":true,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":3,"sorcery":false,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlessedReversal translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bountiful harvest', 'Bountiful Harvest', '80024b4cf516a43e6d18839cf03860e6', 'battle_rule_v1:f609e13e36e1e99fd47c17fe7ea088d2', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BountifulHarvest translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festival of trokin', 'Festival of Trokin', 'c854e6479f1427e2b5d0c823a7244f19', 'battle_rule_v1:898aa76651becdc5799867dd5c4a71b7', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestivalOfTrokin translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fruition', 'Fruition', '1d7d5ee9cf5d1d8f0868d99d5f795919', 'battle_rule_v1:4be0feca617880d6fd5d2b94dd07eee4', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"all_battlefields","battlefield_count_subtypes":["forest"],"effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fruition translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gerrard''s wisdom', 'Gerrard''s Wisdom', '2f3b5a81795c702888749982471cc0b0', 'battle_rule_v1:0dc75e25a69cb2c92abdc1358e2ce3b5', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"controller_hand_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GerrardsWisdom translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invigorating falls', 'Invigorating Falls', 'ade29be2af80d9a21039a33b8d862a31', 'battle_rule_v1:8cc8c8b01bba9fe02e7c3a27f2b387ee', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"life_gain_amount_source":"graveyard_card_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvigoratingFalls translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joyous respite', 'Joyous Respite', '80024b4cf516a43e6d18839cf03860e6', 'battle_rule_v1:f609e13e36e1e99fd47c17fe7ea088d2', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JoyousRespite translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('landbind ritual', 'Landbind Ritual', 'd84556b6708d3cf7331b93ece9875ae6', 'battle_rule_v1:9e929643503771dc1bec7ee764f4e2c3', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["plains"],"effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LandbindRitual translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('peach garden oath', 'Peach Garden Oath', 'c854e6479f1427e2b5d0c823a7244f19', 'battle_rule_v1:898aa76651becdc5799867dd5c4a71b7', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PeachGardenOath translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('presence of the wise', 'Presence of the Wise', '2f3b5a81795c702888749982471cc0b0', 'battle_rule_v1:0dc75e25a69cb2c92abdc1358e2ce3b5', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"controller_hand_count","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PresenceOfTheWise translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('toil to renown', 'Toil to Renown', '4521866f2c0302b96432f72194b560b8', 'battle_rule_v1:7cde60c98e70c669b462ea5874e17232', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact","creature","land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_tapped_state":"tapped","effect":"life_total_change","instant":false,"life_gain_amount_source":"battlefield_permanent_count","life_gain_base_amount":0,"life_gain_per_count":1,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToilToRenown translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wandering stream', 'Wandering Stream', 'fb473dc7cf9f74523c04b406b6d36a8e', 'battle_rule_v1:2672dfc54371d68650a2f9ea851b5990', '{"battle_model_scope":"xmage_dynamic_controller_gain_life_spell_v1","effect":"life_total_change","instant":false,"life_gain_amount_source":"domain_basic_land_types","life_gain_base_amount":0,"life_gain_per_count":2,"sorcery":true,"target":"self","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_total_change","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WanderingStream translated into ManaLoom runtime scope xmage_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
