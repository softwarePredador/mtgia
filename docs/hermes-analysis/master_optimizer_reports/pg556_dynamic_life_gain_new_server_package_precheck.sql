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
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
