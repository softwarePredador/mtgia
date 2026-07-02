WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('advanced stitchwing', 'Advanced Stitchwing', 'c9276c16fe79a207f14b0d2cfce820d2', 'battle_rule_v1:7919ab5e9550d99f6530737dcd12bc48', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["U"],"activation_cost_generic":2,"activation_cost_mana":"{2}{U}","activation_discard_count":2,"activation_discard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["U"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{U}","graveyard_self_return_activation_discard_count":2,"graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AdvancedStitchwing translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ghoulsteed', 'Ghoulsteed', '85a6ebe806fc422f895e6010f766c5b7', 'battle_rule_v1:57d0e158ef6f3bb936ac09a64ba1141b', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_discard_count":2,"activation_discard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_activation_discard_count":2,"graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Ghoulsteed translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stitchwing skaab', 'Stitchwing Skaab', '0c5c60d1c06788f80a724d4f62e365cf', 'battle_rule_v1:5dc1b5fcfe5ba33c0ae895a3eec6d558', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"discard_cards","activation_cost_colors":["U"],"activation_cost_generic":1,"activation_cost_mana":"{1}{U}","activation_discard_count":2,"activation_discard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["U"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{U}","graveyard_self_return_activation_discard_count":2,"graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StitchwingSkaab translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
