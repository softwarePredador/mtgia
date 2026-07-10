WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('talisman of hierarchy', 'Talisman of Hierarchy', 'c3f90c58fc890387f9608a3549409f43', 'battle_rule_v1:954458c0931b6437bede6a45cc70f7f9', '{"ability_kind":"activated","activation_requires_tap":true,"battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","is_mana_source":true,"life_for_colored_mana":1,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"CWB","xmage_ability_classes":["BlackManaAbility","ColorlessManaAbility","WhiteManaAbility"],"xmage_effect_classes":["DamageControllerEffect"],"xmage_mana_ability_classes":["BlackManaAbility","ColorlessManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalismanOfHierarchy translated into ManaLoom runtime scope pain_talisman_color_pair_partial_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('talisman of unity', 'Talisman of Unity', '4c305e3cd5e26bba34476b11bf0ba586', 'battle_rule_v1:19e359edcda29948ab87cec015062f41', '{"ability_kind":"activated","activation_requires_tap":true,"battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","is_mana_source":true,"life_for_colored_mana":1,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"CGW","xmage_ability_classes":["ColorlessManaAbility","GreenManaAbility","WhiteManaAbility"],"xmage_effect_classes":["DamageControllerEffect"],"xmage_mana_ability_classes":["ColorlessManaAbility","GreenManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalismanOfUnity translated into ManaLoom runtime scope pain_talisman_color_pair_partial_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
