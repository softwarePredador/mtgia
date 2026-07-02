WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bone dragon', 'Bone Dragon', '9df52a9a4df8a0c3c8fea1ed5067dcba', 'battle_rule_v1:ed192d13af826e2cba9fc1a0193966b9', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{B}","activation_exile_from_graveyard_count":7,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":7,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"any_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneDragon translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('despoiler of souls', 'Despoiler of Souls', '6da4cbe8dcb147c6ac132e4123adbe80', 'battle_rule_v1:cb987efceb3f6cb411733e0382b5415d', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_exile_from_graveyard_count":2,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":0,"graveyard_self_return_activation_cost_mana":"{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":2,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DespoilerOfSouls translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapheap scrounger', 'Scrapheap Scrounger', 'cec4c3f81a746a934176bc31381355b8', 'battle_rule_v1:b2bcbf2dbafe43780992bc75976967fe', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_exile_from_graveyard_count":1,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{B}","graveyard_self_return_activation_exile_from_graveyard_count":1,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapheapScrounger translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
