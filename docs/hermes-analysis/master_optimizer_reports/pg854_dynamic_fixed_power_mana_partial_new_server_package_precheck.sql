WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cradle clearcutter', 'Cradle Clearcutter', 'f6f17e04c8fd1131bf4cfccbb45da46d', 'battle_rule_v1:67039961b31e595b0e6225b15870c610', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{6}","source_type_line":"Artifact Creature \u2014 Golem","xmage_ability_classes":["DynamicManaAbility","PrototypeAbility"],"xmage_auxiliary_ability_classes":["PrototypeAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["PrototypeAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CradleClearcutter translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marwyn, the nurturer', 'Marwyn, the Nurturer', '14619d564954637c44a7555df0aaaa16', 'battle_rule_v1:10746bf8180402a32b4d7dcc0162943d', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Legendary Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility","EntersBattlefieldControlledTriggeredAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldControlledTriggeredAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldControlledTriggeredAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarwynTheNurturer translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rainveil rejuvenator', 'Rainveil Rejuvenator', 'c515bf72d40914e15aae6ec2016f2fb0', 'battle_rule_v1:a3fc52a6a3a0ed7c7f85b41c2614e1b4', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elephant Druid","xmage_ability_classes":["DynamicManaAbility","EntersBattlefieldTriggeredAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["MillCardsControllerEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_unmodeled_effect_classes":["MillCardsControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainveilRejuvenator translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('topiary lecturer', 'Topiary Lecturer', '1e64589b4932cc3fac0a4e80b22a476c', 'battle_rule_v1:a7d0f71be5140437ea11a5634f7c4862', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility","IncrementAbility"],"xmage_auxiliary_ability_classes":["IncrementAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["IncrementAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TopiaryLecturer translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
