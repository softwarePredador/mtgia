WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bestial menace', 'Bestial Menace', '776667960e301f39134e382444e0d528', 'battle_rule_v1:7bd0274870194298d04700a6cfdd764e', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Snake creature token","token_name":"Snake Token","token_power":1,"token_subtype":"Snake","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SnakeToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"3/3 green Elephant creature token","token_name":"Elephant Token","token_power":3,"token_subtype":"Elephant","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElephantToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["SnakeToken","WolfToken","ElephantToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BestialMenace translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forbidden friendship', 'Forbidden Friendship', '153c16e01b9313ee675ec174b8232ed6', 'battle_rule_v1:d389d66da23728fa4e8d296036357ec2', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["R"],"token_count":1,"token_description":"1/1 red Dinosaur creature token with haste","token_haste":true,"token_keywords":["haste"],"token_name":"Dinosaur Token","token_power":1,"token_subtype":"Dinosaur","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DinosaurHasteToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Human Soldier creature token","token_name":"Human Soldier Token","token_power":1,"token_subtype":"Human Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":2,"token_total_count":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["DinosaurHasteToken","HumanSoldierToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenFriendship translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mascot exhibition', 'Mascot Exhibition', 'ade5d3577a9263f1ce4504a5f6adf502', 'battle_rule_v1:e3cb683bd2371654f0aa9d57b630e774', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","B"],"token_count":1,"token_description":"2/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":2,"token_subtype":"Inkling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InklingToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["U","R"],"token_count":1,"token_description":"4/4 blue and red Elemental creature token","token_name":"Elemental Token","token_power":4,"token_subtype":"Elemental","token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Elemental44Token"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["InklingToken","Spirit32Token","Elemental44Token"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MascotExhibition translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
