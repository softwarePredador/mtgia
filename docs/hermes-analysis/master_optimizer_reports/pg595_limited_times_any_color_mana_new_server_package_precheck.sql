WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barrels of blasting jelly', 'Barrels of Blasting Jelly', '1358ec0bd768ddbbe61d4f51da75d371', 'battle_rule_v1:f0bb162937ccbfd72c8e910cc65998f2', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","DamageTargetEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect","xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DamageTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrelsOfBlastingJelly translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('foraging wickermaw', 'Foraging Wickermaw', 'b561eaa6ae6de6a44a544f77eedf8633', 'battle_rule_v1:55658d4a6b69b4823da754648c7dbd95', '{"_runtime_partial":true,"_runtime_partial_mana_tail":"this creature becomes that color until end of turn","_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["EntersBattlefieldTriggeredAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","BecomesColorTargetEffect","ForagingWickermawManaEffect","SurveilEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"ForagingWickermawManaEffect","xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_unmodeled_effect_classes":["BecomesColorTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForagingWickermaw translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gravestone strider', 'Gravestone Strider', 'e82c9d20f6c97b9308ba55d02d973f08', 'battle_rule_v1:3e54c7656b564d9a607ed69435e255d6', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","ExileTargetEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect","xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["ExileTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GravestoneStrider translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('salvaged manaworker', 'Salvaged Manaworker', '2fbc40e2067c411ec5f194d7ebae3317', 'battle_rule_v1:d19499df027fc37f6a1862428765a9c6', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SalvagedManaworker translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarecrow guide', 'Scarecrow Guide', '2b574d886916add2c83e13828a3c56bc', 'battle_rule_v1:a407bfb0d5db91d6d983a3e411b5941a', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","ReachAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarecrowGuide translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shire scarecrow', 'Shire Scarecrow', 'da5ac98e86a8c1b47220fe1f95eeb411', 'battle_rule_v1:eb31c0c9cacc01c00982e7e947066737', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["DefenderAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShireScarecrow translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('three tree mascot', 'Three Tree Mascot', 'c19d8274215aab484e04c9afc964a00e', 'battle_rule_v1:c2b8dfa7df8651fe720a44afa8e4f4fc', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ChangelingAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_auxiliary_ability_classes":["ChangelingAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect","xmage_unmodeled_auxiliary_ability_classes":["ChangelingAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThreeTreeMascot translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
