WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('atzocan seer', 'Atzocan Seer', '8cfc020809e20c5144de4fe3190c4a14', 'battle_rule_v1:a02f72f5836fcdf1615e1b794c614fa1', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["ReturnFromGraveyardToHandTargetEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["ReturnFromGraveyardToHandTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AtzocanSeer translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blitzball', 'Blitzball', 'c56e79138d8cd9203ed2c656b6e29544', 'battle_rule_v1:5eb770e1e4ddf91aedc56c91c2a4cc68', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["ActivateIfConditionActivatedAbility","AnyColorManaAbility"],"xmage_auxiliary_ability_classes":["ActivateIfConditionActivatedAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["ActivateIfConditionActivatedAbility"],"xmage_unmodeled_effect_classes":["DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Blitzball translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infernal idol', 'Infernal Idol', '26d095b2335f2e707ada37e4cd13ec37', 'battle_rule_v1:8c0d0d38000aaadd1c37f74d08da71db', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produced_mana_symbols":["B"],"produces":"B","xmage_ability_classes":["BlackManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"],"xmage_mana_ability_classes":["BlackManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InfernalIdol translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sunset strikemaster', 'Sunset Strikemaster', 'b3704d74c41bec1009d80157b2205dca', 'battle_rule_v1:a364afcbd31f337b4c889f59dfe289a8', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produced_mana_symbols":["R"],"produces":"R","xmage_ability_classes":["RedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["DamageTargetEffect"],"xmage_mana_ability_classes":["RedManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DamageTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SunsetStrikemaster translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unstable obelisk', 'Unstable Obelisk', '1ac95fa9caf3159f1e75cd142025365b', 'battle_rule_v1:e7a25e72cb2d8069de71a6d64c69d04e', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ColorlessManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["DestroyTargetEffect"],"xmage_mana_ability_classes":["ColorlessManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DestroyTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnstableObelisk translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
