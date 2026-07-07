BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg633_static_colored_cost_increase_new_s_20260707_192935 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('alabaster leech', 'derelor', 'jade leech', 'ruby leech', 'sapphire leech')
   OR normalized_name LIKE 'alabaster leech // %'
   OR normalized_name LIKE 'derelor // %'
   OR normalized_name LIKE 'jade leech // %'
   OR normalized_name LIKE 'ruby leech // %'
   OR normalized_name LIKE 'sapphire leech // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alabaster leech', 'Alabaster Leech', 'e7c2a0c4c950ed0738e080350a345bbd', 'battle_rule_v1:88b395d0c0c7cc5123797b48455a9e88', '{"ability_kind":"static","applies_to_spell_colors":["W"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["W"],"cost_increase_filters":[{"applies_to_spell_colors":["W"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlabasterLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('derelor', 'Derelor', '8d9ecea248b1e7283cc48f6f9b74b4a4', 'battle_rule_v1:05af1d08c9819263e1ed091468c92619', '{"ability_kind":"static","applies_to_spell_colors":["B"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["B"],"cost_increase_filters":[{"applies_to_spell_colors":["B"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Derelor translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jade leech', 'Jade Leech', '9b99eebb5e5009ee76776dbf6c3ce49c', 'battle_rule_v1:0e4f00561c6818cd4f49abd7255f4335', '{"ability_kind":"static","applies_to_spell_colors":["G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["G"],"cost_increase_filters":[{"applies_to_spell_colors":["G"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruby leech', 'Ruby Leech', 'afdea65ad826903da25f776e75e6b34d', 'battle_rule_v1:07e39974d21d191bcbb64924b6757a73', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["R"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["R"],"cost_increase_filters":[{"applies_to_spell_colors":["R"]}],"cost_increase_generic":0,"effect":"static_cost_increase","first_strike":true,"instant":false,"keywords":["first_strike"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubyLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sapphire leech', 'Sapphire Leech', 'fbe7a4420e2cf5ced99e5fd22fc2bf31', 'battle_rule_v1:0092745eb49d15a69bd8afafd8165d7f', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["U"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["U"],"cost_increase_filters":[{"applies_to_spell_colors":["U"]}],"cost_increase_generic":0,"effect":"static_cost_increase","flying":true,"instant":false,"keywords":["flying"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SapphireLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('alabaster leech', 'Alabaster Leech', 'e7c2a0c4c950ed0738e080350a345bbd', 'battle_rule_v1:88b395d0c0c7cc5123797b48455a9e88', '{"ability_kind":"static","applies_to_spell_colors":["W"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["W"],"cost_increase_filters":[{"applies_to_spell_colors":["W"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlabasterLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('derelor', 'Derelor', '8d9ecea248b1e7283cc48f6f9b74b4a4', 'battle_rule_v1:05af1d08c9819263e1ed091468c92619', '{"ability_kind":"static","applies_to_spell_colors":["B"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["B"],"cost_increase_filters":[{"applies_to_spell_colors":["B"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Derelor translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jade leech', 'Jade Leech', '9b99eebb5e5009ee76776dbf6c3ce49c', 'battle_rule_v1:0e4f00561c6818cd4f49abd7255f4335', '{"ability_kind":"static","applies_to_spell_colors":["G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["G"],"cost_increase_filters":[{"applies_to_spell_colors":["G"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruby leech', 'Ruby Leech', 'afdea65ad826903da25f776e75e6b34d', 'battle_rule_v1:07e39974d21d191bcbb64924b6757a73', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["R"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["R"],"cost_increase_filters":[{"applies_to_spell_colors":["R"]}],"cost_increase_generic":0,"effect":"static_cost_increase","first_strike":true,"instant":false,"keywords":["first_strike"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubyLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sapphire leech', 'Sapphire Leech', 'fbe7a4420e2cf5ced99e5fd22fc2bf31', 'battle_rule_v1:0092745eb49d15a69bd8afafd8165d7f', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["U"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["U"],"cost_increase_filters":[{"applies_to_spell_colors":["U"]}],"cost_increase_generic":0,"effect":"static_cost_increase","flying":true,"instant":false,"keywords":["flying"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SapphireLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('alabaster leech', 'Alabaster Leech', 'e7c2a0c4c950ed0738e080350a345bbd', 'battle_rule_v1:88b395d0c0c7cc5123797b48455a9e88', '{"ability_kind":"static","applies_to_spell_colors":["W"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["W"],"cost_increase_filters":[{"applies_to_spell_colors":["W"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlabasterLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('derelor', 'Derelor', '8d9ecea248b1e7283cc48f6f9b74b4a4', 'battle_rule_v1:05af1d08c9819263e1ed091468c92619', '{"ability_kind":"static","applies_to_spell_colors":["B"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["B"],"cost_increase_filters":[{"applies_to_spell_colors":["B"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Derelor translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jade leech', 'Jade Leech', '9b99eebb5e5009ee76776dbf6c3ce49c', 'battle_rule_v1:0e4f00561c6818cd4f49abd7255f4335', '{"ability_kind":"static","applies_to_spell_colors":["G"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["G"],"cost_increase_filters":[{"applies_to_spell_colors":["G"]}],"cost_increase_generic":0,"effect":"static_cost_increase","instant":false,"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruby leech', 'Ruby Leech', 'afdea65ad826903da25f776e75e6b34d', 'battle_rule_v1:07e39974d21d191bcbb64924b6757a73', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["R"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["R"],"cost_increase_filters":[{"applies_to_spell_colors":["R"]}],"cost_increase_generic":0,"effect":"static_cost_increase","first_strike":true,"instant":false,"keywords":["first_strike"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubyLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sapphire leech', 'Sapphire Leech', 'fbe7a4420e2cf5ced99e5fd22fc2bf31', 'battle_rule_v1:0092745eb49d15a69bd8afafd8165d7f', '{"_keywords_are_self":true,"ability_kind":"static","applies_to_spell_colors":["U"],"battle_model_scope":"xmage_static_generic_cost_increase_for_matching_spells_v1","cost_increase_amount_source":"fixed","cost_increase_applies_to":"spells_you_cast","cost_increase_color_symbols":["U"],"cost_increase_filters":[{"applies_to_spell_colors":["U"]}],"cost_increase_generic":0,"effect":"static_cost_increase","flying":true,"instant":false,"keywords":["flying"],"permanent_type":"creature","sorcery":false,"static_effect":"generic_cost_increase_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostIncreasingAllEffect"}'::jsonb, '{"category":"unknown","effect":"static_cost_increase"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SapphireLeech translated into ManaLoom runtime scope xmage_static_generic_cost_increase_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost increase for matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
