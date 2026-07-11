WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('evangel of heliod', 'Evangel of Heliod', '036d326bf50a3bec9d7791ca318f2c02', 'battle_rule_v1:5369f43f4ebb4611b222d350848442c4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Soldier Token","etb_token_power":1,"etb_token_subtype":"Soldier","etb_token_toughness":1,"token_description":"1/1 white Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvangelOfHeliod translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fresh meat', 'Fresh Meat', 'b73bc66f5f1e43b16dadcd2da02c98d0', 'battle_rule_v1:ebc6caabca122273fd394e5d17899537', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"creatures_you_control_died_this_turn","token_description":"3/3 green Beast creature token","token_name":"Beast Token","token_power":3,"token_subtype":"Beast","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BeastToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FreshMeat translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hallowed spiritkeeper', 'Hallowed Spiritkeeper', '2c142ea165a6ce04487793441c32a16d', 'battle_rule_v1:1dc1ebcc43d6cda70b2c4d02dbefdaa3', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["W"],"dies_token_count_source":"controller_graveyard_creature_count","dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Spirit Token","dies_token_power":1,"dies_token_subtype":"Spirit","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["vigilance"],"token_description":"1/1 white Spirit creature token with flying","trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HallowedSpiritkeeper translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revenge of the rats', 'Revenge of the Rats', 'b3a75311467c5352222fdfc6fca7b7bd', 'battle_rule_v1:ee9db175779e49a7daab32685760e37e', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{2}{B}{B}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/1 black Rat creature token","token_name":"Rat Token","token_power":1,"token_subtype":"Rat","token_tapped":true,"token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevengeOfTheRats translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reverent hoplite', 'Reverent Hoplite', '8c8ea6c2ea65a8008a2a4c8e06f0179f', 'battle_rule_v1:7a522d8512326cec2db9f21d2bd12d96', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Human Soldier Token","etb_token_power":1,"etb_token_subtype":"Human Soldier","etb_token_toughness":1,"token_description":"1/1 white Human Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReverentHoplite translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider spawning', 'Spider Spawning', 'd911b47c05e2ec72164f7b2c48162627', 'battle_rule_v1:4b857a2f074969cdb85c7eabacb7c73d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{6}{B}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/2 green Spider creature token with reach","token_keywords":["reach"],"token_name":"Spider Token","token_power":1,"token_subtype":"Spider","token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiderToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderSpawning translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('underworld hermit', 'Underworld Hermit', '227054dbd6d2beac83b76e5457631d1f', 'battle_rule_v1:29c842654d32c86516e76abd5048a396', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["G"],"etb_token_count_source":"devotion_to_black","etb_token_name":"Squirrel Token","etb_token_power":1,"etb_token_subtype":"Squirrel","etb_token_toughness":1,"token_description":"1/1 green Squirrel creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SquirrelToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnderworldHermit translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
