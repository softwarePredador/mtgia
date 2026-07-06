WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('triplicate titan', 'Triplicate Titan', '748500ed50946b0e051c59e82fb6f204', 'battle_rule_v1:65042d3af7a906fc248edf593ed498f5', '{"_composite_rule_components":[{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_count":1,"token_description":"3/3 colorless Golem artifact creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Golem Token","token_power":3,"token_subtype":"Golem","token_toughness":3,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GolemFlyingToken"},{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_count":1,"token_description":"3/3 colorless Golem artifact creature token with vigilance","token_keywords":["vigilance"],"token_name":"Golem Token","token_power":3,"token_subtype":"Golem","token_toughness":3,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GolemVigilanceToken"},{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_count":1,"token_description":"3/3 colorless Golem artifact creature token with trample","token_keywords":["trample"],"token_name":"Golem Token","token_power":3,"token_subtype":"Golem","token_toughness":3,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GolemTrampleToken"}],"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_trigger_effect":"token_maker","effect":"creature","flying":true,"keywords":["flying","trample","vigilance"],"token_component_count":3,"token_total_count":3,"trample":true,"trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["GolemFlyingToken","GolemVigilanceToken","GolemTrampleToken"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TriplicateTitan translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('trostani''s summoner', 'Trostani''s Summoner', '28ab52a54939a877dbfa059d057fb9ce', 'battle_rule_v1:4f9b05e8bcdb35281142ce7f97b330a2', '{"_composite_rule_components":[{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"trigger":"enters_battlefield","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"},{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"3/3 green Centaur creature token","token_name":"Centaur Token","token_power":3,"token_subtype":"Centaur","token_toughness":3,"trigger":"enters_battlefield","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"CentaurToken"},{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"4/4 green Rhino creature token with trample","token_keywords":["trample"],"token_name":"Rhino Token","token_power":4,"token_subtype":"Rhino","token_toughness":4,"trigger":"enters_battlefield","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RhinoToken"}],"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_trigger_effect":"token_maker","token_component_count":3,"token_total_count":3,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["KnightToken","CentaurToken","RhinoToken"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TrostanisSummoner translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wurmcoil engine', 'Wurmcoil Engine', '20dd9364033ef7f4db0bbe2d7effa383', 'battle_rule_v1:a4849985e57e30c0d9e6283e9a48cfb6', '{"_composite_rule_components":[{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_count":1,"token_description":"3/3 colorless Phyrexian Wurm artifact creature token with deathtouch","token_keywords":["deathtouch"],"token_name":"Phyrexian Wurm Token","token_power":3,"token_subtype":"Phyrexian Wurm","token_toughness":3,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmWithDeathtouchToken"},{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_count":1,"token_description":"3/3 colorless Phyrexian Wurm artifact creature token with lifelink","token_keywords":["lifelink"],"token_name":"Phyrexian Wurm Token","token_power":3,"token_subtype":"Phyrexian Wurm","token_toughness":3,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmWithLifelinkToken"}],"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","deathtouch":true,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["deathtouch","lifelink"],"lifelink":true,"token_component_count":2,"token_total_count":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["WurmWithDeathtouchToken","WurmWithLifelinkToken"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WurmcoilEngine translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wurmcoil larva', 'Wurmcoil Larva', 'c280486479b469cc2588bc75649b6bd8', 'battle_rule_v1:e2a1c5e81f46a15a6080f1c929b4b70a', '{"_composite_rule_components":[{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["B"],"token_count":1,"token_description":"1/2 black Phyrexian Wurm artifact creature token with deathtouch","token_keywords":["deathtouch"],"token_name":"Phyrexian Wurm Token","token_power":1,"token_subtype":"Phyrexian Wurm","token_toughness":2,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"PhyrexianWurm12DeathtouchToken"},{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"xmage_creature_dies_create_tokens_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["B"],"token_count":1,"token_description":"2/1 black Phyrexian Wurm artifact creature token with lifelink","token_keywords":["lifelink"],"token_name":"Phyrexian Wurm Token","token_power":2,"token_subtype":"Phyrexian Wurm","token_toughness":1,"trigger":"dies","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"PhyrexianWurm21LifelinkToken"}],"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","deathtouch":true,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["deathtouch","lifelink"],"lifelink":true,"token_component_count":2,"token_total_count":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["PhyrexianWurm12DeathtouchToken","PhyrexianWurm21LifelinkToken"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WurmcoilLarva translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
