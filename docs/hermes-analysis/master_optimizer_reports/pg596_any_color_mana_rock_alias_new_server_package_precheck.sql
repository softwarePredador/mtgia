WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('celestial prism', 'Celestial Prism', 'd4fbeac453cff388c63c90d13b51a63b', 'battle_rule_v1:8abc926d110e8c26fb4143c78b705d4a', '{"activation_mana_cost":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CelestialPrism translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chromatic sphere', 'Chromatic Sphere', '9feea6f9709f43a5e6cebccf273b2ebc', 'battle_rule_v1:f3f232b22d73b373966715bfc102dc89', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage self-sacrifice mana ability is executable in this rule; listed auxiliary ability/effect classes and same-ability non-mana tails remain unmodeled.","_runtime_partial_sacrifice_mana_tail":"draw a card.","ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_source_contextual_only":true,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_class":"AnyColorManaAbility","xmage_auxiliary_ability_classes":[],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_effect_classes":["DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChromaticSphere translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mana cylix', 'Mana Cylix', 'e7da6ddd05e9302702b6f8a48bba9fd6', 'battle_rule_v1:5bddc6f173c531e5421b248587ad9200', '{"activation_mana_cost":"{1}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ManaCylix translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('manalith', 'Manalith', '2cb86f263cc7e5d235b1db55361d97ae', 'battle_rule_v1:a58e029d95561381bb71d4cea43788df', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Manalith translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian altar', 'Phyrexian Altar', 'b7c5a22696e90cd9ed2601073ce9551d', 'battle_rule_v1:37b8c3fa5a8d0e1058c9fa50c55f73fb', '{"ability_kind":"activated_mana","activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"creature","battle_model_scope":"xmage_target_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice_target":true,"mana_activation_requires_tap":false,"mana_produced":1,"mana_source_contextual_only":true,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility"],"xmage_auxiliary_ability_classes":[],"xmage_cost_class":"SacrificeTargetCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianAltar translated into ManaLoom runtime scope xmage_target_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
