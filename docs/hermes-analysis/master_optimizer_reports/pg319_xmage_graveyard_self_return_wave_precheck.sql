WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('clay revenant', 'Clay Revenant', 'eda7a643bd39973b1c503a2911e8075c', 'battle_rule_v1:6db80ae97aed2cb8a0254e51b304e59c', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClayRevenant translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('durable coilbug', 'Durable Coilbug', '629741079e6af2edd2d1cd2048c5c1f6', 'battle_rule_v1:7d15b0674691123c9fd7f56ef65e7605', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":4,"activation_cost_mana":"{4}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":4,"graveyard_self_return_activation_cost_mana":"{4}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DurableCoilbug translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firewing phoenix', 'Firewing Phoenix', 'da336e9fec070e0aecf2c8ac03cda88e', 'battle_rule_v1:837aa65ddae8b447d7a49da13bd85c20', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["R","R","R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}{R}{R}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["R","R","R"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{R}{R}{R}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirewingPhoenix translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle creeper', 'Jungle Creeper', '440698b16883b0b3e1f91f066a069aa3', 'battle_rule_v1:5b4aab512c66d50d12086d9209691de3', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B","G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{G}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B","G"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{G}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleCreeper translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merchant of many hats', 'Merchant of Many Hats', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerchantOfManyHats translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanitarium skeleton', 'Sanitarium Skeleton', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanitariumSkeleton translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
