BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg676_gain_control_untap_haste_20260708_230749 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('act of treason', 'blind with anger', 'claim the firstborn', 'hijack', 'metallic mastery', 'threaten', 'wrangle')
   OR normalized_name LIKE 'act of treason // %'
   OR normalized_name LIKE 'blind with anger // %'
   OR normalized_name LIKE 'claim the firstborn // %'
   OR normalized_name LIKE 'hijack // %'
   OR normalized_name LIKE 'metallic mastery // %'
   OR normalized_name LIKE 'threaten // %'
   OR normalized_name LIKE 'wrangle // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('act of treason', 'Act of Treason', '314d7d72d85e8d60855b79224faa18a0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ActOfTreason translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blind with anger', 'Blind with Anger', '162af0a71afdbc978f0e9530a2930b60', 'battle_rule_v1:1d33ee89a15a6b3fc2b5c63b1ba31d8c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_supertypes":["legendary"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindWithAnger translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('claim the firstborn', 'Claim the Firstborn', '4844d46e00c8278d9b188b290aa88777', 'battle_rule_v1:67e89d7ed196e92637743285bc65dace', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"mana_value_max":3},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClaimTheFirstborn translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hijack', 'Hijack', '3711f7d4278a254798ac98fbda59b936', 'battle_rule_v1:8d3585724a53c93157963888594819c6', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hijack translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metallic mastery', 'Metallic Mastery', 'c26c2a0a7881cd27fe7d29931ad559b3', 'battle_rule_v1:94992b67574bf9d7d4a187521ee18c6a', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetallicMastery translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('threaten', 'Threaten', '851f2791896c2e7d48ec022575763ce0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Threaten translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wrangle', 'Wrangle', '8be9095f8bcf4906391501cc2f94294f', 'battle_rule_v1:5cfcbf2ede0226e481d4fbc7e825d78c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_max":4},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Wrangle translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('act of treason', 'Act of Treason', '314d7d72d85e8d60855b79224faa18a0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ActOfTreason translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blind with anger', 'Blind with Anger', '162af0a71afdbc978f0e9530a2930b60', 'battle_rule_v1:1d33ee89a15a6b3fc2b5c63b1ba31d8c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_supertypes":["legendary"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindWithAnger translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('claim the firstborn', 'Claim the Firstborn', '4844d46e00c8278d9b188b290aa88777', 'battle_rule_v1:67e89d7ed196e92637743285bc65dace', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"mana_value_max":3},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClaimTheFirstborn translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hijack', 'Hijack', '3711f7d4278a254798ac98fbda59b936', 'battle_rule_v1:8d3585724a53c93157963888594819c6', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hijack translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metallic mastery', 'Metallic Mastery', 'c26c2a0a7881cd27fe7d29931ad559b3', 'battle_rule_v1:94992b67574bf9d7d4a187521ee18c6a', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetallicMastery translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('threaten', 'Threaten', '851f2791896c2e7d48ec022575763ce0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Threaten translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wrangle', 'Wrangle', '8be9095f8bcf4906391501cc2f94294f', 'battle_rule_v1:5cfcbf2ede0226e481d4fbc7e825d78c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_max":4},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Wrangle translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('act of treason', 'Act of Treason', '314d7d72d85e8d60855b79224faa18a0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ActOfTreason translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blind with anger', 'Blind with Anger', '162af0a71afdbc978f0e9530a2930b60', 'battle_rule_v1:1d33ee89a15a6b3fc2b5c63b1ba31d8c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_supertypes":["legendary"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindWithAnger translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('claim the firstborn', 'Claim the Firstborn', '4844d46e00c8278d9b188b290aa88777', 'battle_rule_v1:67e89d7ed196e92637743285bc65dace', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"mana_value_max":3},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClaimTheFirstborn translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hijack', 'Hijack', '3711f7d4278a254798ac98fbda59b936', 'battle_rule_v1:8d3585724a53c93157963888594819c6', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hijack translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metallic mastery', 'Metallic Mastery', 'c26c2a0a7881cd27fe7d29931ad559b3', 'battle_rule_v1:94992b67574bf9d7d4a187521ee18c6a', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetallicMastery translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('threaten', 'Threaten', '851f2791896c2e7d48ec022575763ce0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Threaten translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wrangle', 'Wrangle', '8be9095f8bcf4906391501cc2f94294f', 'battle_rule_v1:5cfcbf2ede0226e481d4fbc7e825d78c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_max":4},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Wrangle translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
