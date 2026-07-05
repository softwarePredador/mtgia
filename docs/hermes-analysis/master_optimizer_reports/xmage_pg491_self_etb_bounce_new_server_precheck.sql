WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deputy of acquittals', 'Deputy of Acquittals', '8658050003924c8990794806bcf34c88', 'battle_rule_v1:493e0ab5c91fdbd60a0fda3532814452', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeputyOfAcquittals translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exosuit savior', 'Exosuit Savior', '4b1f906a2af79e08338a65d5700bc5cd', 'battle_rule_v1:692686d146f19ec536fb0704620e44cd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flying":true,"keywords":["flying"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExosuitSavior translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeskai barricade', 'Jeskai Barricade', 'ca71ecc80d1273684e448324fdfd168a', 'battle_rule_v1:661b62cfa162aee53b66adff80c17e78', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","defender":true,"destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash","defender"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeskaiBarricade translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous pup', 'Mischievous Pup', 'ea8a2a09c160913a1ad518e6b9d3711b', 'battle_rule_v1:7d59845fceced1b041f0de871f39d129', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flash":true,"keywords":["flash"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousPup translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rimekin recluse', 'Rimekin Recluse', '79d7243258226d60ebdf5c3170702002', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RimekinRecluse translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stickytongue sentinel', 'Stickytongue Sentinel', '4b53aac3ac2fe4a7437abe425ee751f6', 'battle_rule_v1:6768ad939d7a940cece11d406c451774', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"keywords":["reach"],"reach":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StickytongueSentinel translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
