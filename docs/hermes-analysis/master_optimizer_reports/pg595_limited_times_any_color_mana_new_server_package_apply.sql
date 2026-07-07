BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg595_limited_times_any_color_mana_new_s_20260707_051029 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('barrels of blasting jelly', 'foraging wickermaw', 'gravestone strider', 'salvaged manaworker', 'scarecrow guide', 'shire scarecrow', 'three tree mascot')
   OR normalized_name LIKE 'barrels of blasting jelly // %'
   OR normalized_name LIKE 'foraging wickermaw // %'
   OR normalized_name LIKE 'gravestone strider // %'
   OR normalized_name LIKE 'salvaged manaworker // %'
   OR normalized_name LIKE 'scarecrow guide // %'
   OR normalized_name LIKE 'shire scarecrow // %'
   OR normalized_name LIKE 'three tree mascot // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
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
    ('barrels of blasting jelly', 'Barrels of Blasting Jelly', '1358ec0bd768ddbbe61d4f51da75d371', 'battle_rule_v1:f0bb162937ccbfd72c8e910cc65998f2', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","DamageTargetEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect","xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DamageTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrelsOfBlastingJelly translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('foraging wickermaw', 'Foraging Wickermaw', 'b561eaa6ae6de6a44a544f77eedf8633', 'battle_rule_v1:55658d4a6b69b4823da754648c7dbd95', '{"_runtime_partial":true,"_runtime_partial_mana_tail":"this creature becomes that color until end of turn","_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["EntersBattlefieldTriggeredAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","BecomesColorTargetEffect","ForagingWickermawManaEffect","SurveilEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"ForagingWickermawManaEffect","xmage_unmodeled_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_unmodeled_effect_classes":["BecomesColorTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForagingWickermaw translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gravestone strider', 'Gravestone Strider', 'e82c9d20f6c97b9308ba55d02d973f08', 'battle_rule_v1:3e54c7656b564d9a607ed69435e255d6', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","ExileTargetEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect","xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["ExileTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GravestoneStrider translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('salvaged manaworker', 'Salvaged Manaworker', '2fbc40e2067c411ec5f194d7ebae3317', 'battle_rule_v1:d19499df027fc37f6a1862428765a9c6', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SalvagedManaworker translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarecrow guide', 'Scarecrow Guide', '2b574d886916add2c83e13828a3c56bc', 'battle_rule_v1:a407bfb0d5db91d6d983a3e411b5941a', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","ReachAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarecrowGuide translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shire scarecrow', 'Shire Scarecrow', 'da5ac98e86a8c1b47220fe1f95eeb411', 'battle_rule_v1:eb31c0c9cacc01c00982e7e947066737', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["DefenderAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShireScarecrow translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('three tree mascot', 'Three Tree Mascot', 'c19d8274215aab484e04c9afc964a00e', 'battle_rule_v1:c2b8dfa7df8651fe720a44afa8e4f4fc', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ChangelingAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_auxiliary_ability_classes":["ChangelingAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaOfAnyColorEffect","xmage_unmodeled_auxiliary_ability_classes":["ChangelingAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThreeTreeMascot translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
