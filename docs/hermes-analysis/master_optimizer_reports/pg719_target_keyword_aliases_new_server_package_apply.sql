BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg719_target_keyword_aliases_new_server_20260710_201249 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('breach', 'hooded kavu', 'shriek of dread', 'withstand death')
   OR normalized_name LIKE 'breach // %'
   OR normalized_name LIKE 'hooded kavu // %'
   OR normalized_name LIKE 'shriek of dread // %'
   OR normalized_name LIKE 'withstand death // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('breach', 'Breach', '224c0d53fa8be85465b652ca0159f3d3', 'battle_rule_v1:1a80a59bfe60d19ce999c58d8ac0625d', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Breach translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hooded kavu', 'Hooded Kavu', '50d94303fbeddf742c7ad88d483140dd', 'battle_rule_v1:5f8dd5e86f63f36f1155e92d6949b87b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HoodedKavu translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shriek of dread', 'Shriek of Dread', '9b96055cb88f677761b150c4b7d5a167', 'battle_rule_v1:8d46159e8ae2f9b5ee8b04b9f0b2db80', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShriekOfDread translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withstand death', 'Withstand Death', '7cf7b1aef30648b3a79cba54d4c8f659', 'battle_rule_v1:64b2eb6d72830a72e6188d12589b5e97', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WithstandDeath translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('breach', 'Breach', '224c0d53fa8be85465b652ca0159f3d3', 'battle_rule_v1:1a80a59bfe60d19ce999c58d8ac0625d', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Breach translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hooded kavu', 'Hooded Kavu', '50d94303fbeddf742c7ad88d483140dd', 'battle_rule_v1:5f8dd5e86f63f36f1155e92d6949b87b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HoodedKavu translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shriek of dread', 'Shriek of Dread', '9b96055cb88f677761b150c4b7d5a167', 'battle_rule_v1:8d46159e8ae2f9b5ee8b04b9f0b2db80', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShriekOfDread translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withstand death', 'Withstand Death', '7cf7b1aef30648b3a79cba54d4c8f659', 'battle_rule_v1:64b2eb6d72830a72e6188d12589b5e97', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WithstandDeath translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('breach', 'Breach', '224c0d53fa8be85465b652ca0159f3d3', 'battle_rule_v1:1a80a59bfe60d19ce999c58d8ac0625d', '{"battle_model_scope":"xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_classes":["BoostTargetEffect","GainAbilityTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Breach translated into ManaLoom runtime scope xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-creature boost plus until-end-of-turn keyword spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hooded kavu', 'Hooded Kavu', '50d94303fbeddf742c7ad88d483140dd', 'battle_rule_v1:5f8dd5e86f63f36f1155e92d6949b87b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","activated_effect":"self_keyword_until_eot","activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_keyword_until_eot_v1","duration":"until_end_of_turn","effect":"creature","granted_keywords_until_eot":["fear"],"power_delta":0,"target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","toughness_delta":0,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"GainAbilitySourceEffect","xmage_keyword_ability_class":"FearAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HoodedKavu translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_keyword_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shriek of dread', 'Shriek of Dread', '9b96055cb88f677761b150c4b7d5a167', 'battle_rule_v1:8d46159e8ae2f9b5ee8b04b9f0b2db80', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["fear"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["FearAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShriekOfDread translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withstand death', 'Withstand Death', '7cf7b1aef30648b3a79cba54d4c8f659', 'battle_rule_v1:64b2eb6d72830a72e6188d12589b5e97', '{"battle_model_scope":"xmage_fixed_keyword_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","granted_keywords_until_eot":["indestructible"],"instant":true,"power_boost":0,"power_delta":0,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"xmage_ability_classes":["IndestructibleAbility"],"xmage_effect_class":"GainAbilityTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WithstandDeath translated into ManaLoom runtime scope xmage_fixed_keyword_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
