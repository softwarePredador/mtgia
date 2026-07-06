WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('flurry of wings', 'Flurry of Wings', '72f8eaf4e66233d8fee70bdc89b0d9e8', 'battle_rule_v1:a91caec6e84e9d586a9840e0c3b920f2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"attacking_creatures","token_description":"1/1 white Bird Soldier creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Soldier Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BirdSoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlurryOfWings translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ordered migration', 'Ordered Migration', '1b5c3336a9ee95c0a884e68cefd3125b', 'battle_rule_v1:86ed16a7f8dfea78058cc7433c03045c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["U"],"token_count_source":"domain_basic_land_types","token_description":"1/1 blue Bird creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BlueBirdToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrderedMigration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise from the tides', 'Rise from the Tides', '5c3cc3549eb1d78a63802563e6421d4d', 'battle_rule_v1:8702d53c8c4cd31c2e292abb579597fe', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["B"],"token_count_source":"controller_graveyard_instant_sorcery_count","token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_tapped":true,"token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseFromTheTides translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spontaneous generation', 'Spontaneous Generation', '46e11b6dffc19a0d146cf67ef7478f98', 'battle_rule_v1:47e922b3dd61e1f57d31c4518423fcd5', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controller_hand_count","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpontaneousGeneration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spore burst', 'Spore Burst', 'a2b75ca550ba7fa0f34e5d925329a95f', 'battle_rule_v1:ae6d8c0ab8584b64df647dc87a0fb320', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"domain_basic_land_types","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SporeBurst translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg548_dynamic_token_extended_new_server_20260706_040441) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
