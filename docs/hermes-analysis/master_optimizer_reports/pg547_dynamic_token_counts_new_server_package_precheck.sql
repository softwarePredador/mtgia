WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crash the party', 'Crash the Party', 'fcc5c9091e8dc516fbe887bb09d4369f', 'battle_rule_v1:5617d2a4db40a81168145b32a933e9ec', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_tapped_creatures","token_description":"4/4 green Rhino Warrior creature token","token_name":"Rhino Warrior Token","token_power":4,"token_subtype":"Rhino Warrior","token_tapped":true,"token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RhinoWarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrashTheParty translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deploy to the front', 'Deploy to the Front', '4179614d05de27ce72bb3a55659ef40b', 'battle_rule_v1:7db95ac0624f990faca2a4a8d4e864de', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"all_creatures_on_battlefield","token_description":"1/1 white Soldier creature token","token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeployToTheFront translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fungal sprouting', 'Fungal Sprouting', '2a5a44d545d22c40ad1cf5f1b330d152', 'battle_rule_v1:f3a6a30cc5e2bd3ed129bcfbd9084bf2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"greatest_power_among_controlled_creatures","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FungalSprouting translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin gathering', 'Goblin Gathering', '6986d05a3b7a31a80d433ad992684d3f', 'battle_rule_v1:a0c433cb3bf28fab494fe04f4e10f96b', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["R"],"token_count_base":2,"token_count_card_name":"Goblin Gathering","token_count_source":"named_cards_in_controller_graveyard_plus_base","token_description":"1/1 red Goblin creature token","token_name":"Goblin Token","token_power":1,"token_subtype":"Goblin","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GoblinToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGathering translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('howl of the night pack', 'Howl of the Night Pack', '6890aca1767d2d1b23b90713ae03e1a2', 'battle_rule_v1:f075c7e5b6bb551a0f217eba3bf6ac63', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_subtype_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_permanents_with_subtype","token_count_subtype":"Forest","token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HowlOfTheNightPack translated into ManaLoom runtime scope xmage_controlled_subtype_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
