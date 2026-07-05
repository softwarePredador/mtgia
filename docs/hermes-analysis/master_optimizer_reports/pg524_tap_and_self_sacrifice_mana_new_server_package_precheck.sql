WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eye of ramos', 'Eye of Ramos', '6f652cb7ac056ddfc5e4213753f0df80', 'battle_rule_v1:cebb0acee193419e9fdc9340f293e607', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["U"],"produces":"U","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["U"],"sacrifice_produces":"U","xmage_ability_classes":["BlueManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlueManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('heart of ramos', 'Heart of Ramos', '26b3e2b5a380b8d9998b1054fc500690', 'battle_rule_v1:e1af4e70352a8b7e668917359f2c020f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["R"],"sacrifice_produces":"R","xmage_ability_classes":["RedManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["RedManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeartOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horn of ramos', 'Horn of Ramos', '291e4d62cfb289ce58695ddaf27db585', 'battle_rule_v1:149688a3e0852130a77d37a899da3ede', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["G"],"produces":"G","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["G"],"sacrifice_produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["GreenManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HornOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skull of ramos', 'Skull of Ramos', 'f5afc49a19163867d1d6ed10a9bd7192', 'battle_rule_v1:9ea6c346cb56167508e401c63aac6e5f', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["B"],"produces":"B","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["B"],"sacrifice_produces":"B","xmage_ability_classes":["BlackManaAbility","SimpleManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["BlackManaAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkullOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tooth of ramos', 'Tooth of Ramos', 'b24169ac0da54a32bade58cc60a0b2ef', 'battle_rule_v1:51cc15772f2a262e43a834ecc03b9c7d', '{"ability_kind":"mana_and_sacrifice_mana","activation_requires_tap":true,"battle_model_scope":"xmage_tap_and_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["W"],"produces":"W","sacrifice_activation_requires_sacrifice":true,"sacrifice_activation_requires_tap":false,"sacrifice_mana_activation_requires_sacrifice":true,"sacrifice_mana_activation_requires_tap":false,"sacrifice_mana_produced":1,"sacrifice_mana_source_contextual_only":true,"sacrifice_produced_mana_symbols":["W"],"sacrifice_produces":"W","xmage_ability_classes":["SimpleManaAbility","WhiteManaAbility"],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ToothOfRamos translated into ManaLoom runtime scope xmage_tap_and_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow tap mana-source permanent with separate self-sacrifice mana ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
