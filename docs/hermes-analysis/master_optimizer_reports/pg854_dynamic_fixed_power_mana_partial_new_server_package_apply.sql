BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg854_dynamic_fixed_power_mana_partial_n_20260713_005518 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('cradle clearcutter', 'marwyn, the nurturer', 'rainveil rejuvenator', 'topiary lecturer')
   OR normalized_name LIKE 'cradle clearcutter // %'
   OR normalized_name LIKE 'marwyn, the nurturer // %'
   OR normalized_name LIKE 'rainveil rejuvenator // %'
   OR normalized_name LIKE 'topiary lecturer // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cradle clearcutter', 'Cradle Clearcutter', 'f6f17e04c8fd1131bf4cfccbb45da46d', 'battle_rule_v1:67039961b31e595b0e6225b15870c610', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{6}","source_type_line":"Artifact Creature \u2014 Golem","xmage_ability_classes":["DynamicManaAbility","PrototypeAbility"],"xmage_auxiliary_ability_classes":["PrototypeAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["PrototypeAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CradleClearcutter translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marwyn, the nurturer', 'Marwyn, the Nurturer', '14619d564954637c44a7555df0aaaa16', 'battle_rule_v1:10746bf8180402a32b4d7dcc0162943d', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Legendary Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility","EntersBattlefieldControlledTriggeredAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldControlledTriggeredAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldControlledTriggeredAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarwynTheNurturer translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rainveil rejuvenator', 'Rainveil Rejuvenator', 'c515bf72d40914e15aae6ec2016f2fb0', 'battle_rule_v1:a3fc52a6a3a0ed7c7f85b41c2614e1b4', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elephant Druid","xmage_ability_classes":["DynamicManaAbility","EntersBattlefieldTriggeredAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["MillCardsControllerEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_unmodeled_effect_classes":["MillCardsControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainveilRejuvenator translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('topiary lecturer', 'Topiary Lecturer', '1e64589b4932cc3fac0a4e80b22a476c', 'battle_rule_v1:a7d0f71be5140437ea11a5634f7c4862', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility","IncrementAbility"],"xmage_auxiliary_ability_classes":["IncrementAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["IncrementAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TopiaryLecturer translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cradle clearcutter', 'Cradle Clearcutter', 'f6f17e04c8fd1131bf4cfccbb45da46d', 'battle_rule_v1:67039961b31e595b0e6225b15870c610', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{6}","source_type_line":"Artifact Creature \u2014 Golem","xmage_ability_classes":["DynamicManaAbility","PrototypeAbility"],"xmage_auxiliary_ability_classes":["PrototypeAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["PrototypeAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CradleClearcutter translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marwyn, the nurturer', 'Marwyn, the Nurturer', '14619d564954637c44a7555df0aaaa16', 'battle_rule_v1:10746bf8180402a32b4d7dcc0162943d', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Legendary Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility","EntersBattlefieldControlledTriggeredAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldControlledTriggeredAbility"],"xmage_effect_classes":["AddCountersSourceEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldControlledTriggeredAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarwynTheNurturer translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rainveil rejuvenator', 'Rainveil Rejuvenator', 'c515bf72d40914e15aae6ec2016f2fb0', 'battle_rule_v1:a3fc52a6a3a0ed7c7f85b41c2614e1b4', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Elephant Druid","xmage_ability_classes":["DynamicManaAbility","EntersBattlefieldTriggeredAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["MillCardsControllerEffect"],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_unmodeled_effect_classes":["MillCardsControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainveilRejuvenator translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('topiary lecturer', 'Topiary Lecturer', '1e64589b4932cc3fac0a4e80b22a476c', 'battle_rule_v1:a7d0f71be5140437ea11a5634f7c4862', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The DynamicManaAbility mana production is fully modeled by the fixed-color dynamic mana runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage fixed-color DynamicManaAbility is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility","IncrementAbility"],"xmage_auxiliary_ability_classes":["IncrementAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["IncrementAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TopiaryLecturer translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
