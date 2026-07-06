WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eternal student', 'Eternal Student', '5d0d28b33adc1da99013cace22fa94e3', 'battle_rule_v1:14a6c4f3e3b0ff2645919f71c042b467', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalStudent translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('illustrious historian', 'Illustrious Historian', 'fa81074d782e0d0677343f5b38ee6ce4', 'battle_rule_v1:c1687c5ca0cc72d415cd8e171f2436e0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IllustriousHistorian translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
