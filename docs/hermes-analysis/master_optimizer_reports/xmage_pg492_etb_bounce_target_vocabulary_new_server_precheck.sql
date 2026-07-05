WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('air-cult elemental', 'Air-Cult Elemental', '00cefdd464d0c7e0783d11ae42a4ca57', 'battle_rule_v1:add0e0805dd63d69ec22ac0c106dfc08', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flying":true,"keywords":["flying"],"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AirCultElemental translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardians of koilos', 'Guardians of Koilos', 'd98db2233ec18e6c04d492d26d91c045', 'battle_rule_v1:f38b5f7861c20bd8bad36225b02e1919', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"historic_permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"historic_permanent","exclude_source":true,"target":"historic_permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["permanent"],"required_supertypes":["legendary"]},{"card_types":["enchantment"],"required_subtypes":["saga"]}],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"historic_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardiansOfKoilos translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roaming ghostlight', 'Roaming Ghostlight', 'bd14f162bc972d608f87fb6cc5e3c2a5', 'battle_rule_v1:f37702fd67802ff846d310a75da27ded', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"non_spirit_creature","etb_remove_effect":"remove_creature","etb_remove_target":"non_spirit_creature","flying":true,"keywords":["flying"],"target":"non_spirit_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["spirit"]},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"non_spirit_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoamingGhostlight translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter eladrin', 'Winter Eladrin', 'aa12b5b95838062b861c58759881cdd2', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WinterEladrin translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
