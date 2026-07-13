WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('birthing boughs', 'Birthing Boughs', '2465083f401a35e89bd81d155353bfb0', 'battle_rule_v1:3566e78c8b8acc37b06979e9f460145c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_all_creature_types":true,"token_changeling":true,"token_count":1,"token_description":"2/2 colorless Shapeshifter creature token with changeling","token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":2,"token_subtype":"Shapeshifter","token_toughness":2,"token_universal_creature_subtypes":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ShapeshifterToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"artifact","token_all_creature_types":true,"token_changeling":true,"token_count":1,"token_description":"2/2 colorless Shapeshifter creature token with changeling","token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":2,"token_subtype":"Shapeshifter","token_toughness":2,"token_universal_creature_subtypes":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ShapeshifterToken"}'::jsonb, '{"category":"unknown","effect":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BirthingBoughs translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
