BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg743_mana_source_support_cost_new_serve_20260711_055411 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('citanul stalwart', 'jaspera sentinel', 'loam dryad', 'saruli caretaker')
   OR normalized_name LIKE 'citanul stalwart // %'
   OR normalized_name LIKE 'jaspera sentinel // %'
   OR normalized_name LIKE 'loam dryad // %'
   OR normalized_name LIKE 'saruli caretaker // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('citanul stalwart', 'Citanul Stalwart', '7e8765a64a1d3c8775914745ee280f8d', 'battle_rule_v1:ab258dce31ac650782de9f06e8036162', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"artifact_or_creature","mana_produced":1,"mana_source_requires_untapped_artifact_or_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CitanulStalwart translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaspera sentinel', 'Jaspera Sentinel', 'a9e1a252d2d06280c9f7a5f4b2ba213f', 'battle_rule_v1:53fddee02366902e529f36face750f2d', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","ReachAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JasperaSentinel translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam dryad', 'Loam Dryad', 'bc0d67ab4c23dc0ffed1100c30eac1d5', 'battle_rule_v1:4d6e4eddb7fc0a7a794f0af96f4f5fe5', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamDryad translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saruli caretaker', 'Saruli Caretaker', '0b9879abab7f49482456a5969bbeabd2', 'battle_rule_v1:6cf57a838d0947fad3c0c9b6e13f9014', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","DefenderAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SaruliCaretaker translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('citanul stalwart', 'Citanul Stalwart', '7e8765a64a1d3c8775914745ee280f8d', 'battle_rule_v1:ab258dce31ac650782de9f06e8036162', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"artifact_or_creature","mana_produced":1,"mana_source_requires_untapped_artifact_or_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CitanulStalwart translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaspera sentinel', 'Jaspera Sentinel', 'a9e1a252d2d06280c9f7a5f4b2ba213f', 'battle_rule_v1:53fddee02366902e529f36face750f2d', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","ReachAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JasperaSentinel translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam dryad', 'Loam Dryad', 'bc0d67ab4c23dc0ffed1100c30eac1d5', 'battle_rule_v1:4d6e4eddb7fc0a7a794f0af96f4f5fe5', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamDryad translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saruli caretaker', 'Saruli Caretaker', '0b9879abab7f49482456a5969bbeabd2', 'battle_rule_v1:6cf57a838d0947fad3c0c9b6e13f9014', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","DefenderAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SaruliCaretaker translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('citanul stalwart', 'Citanul Stalwart', '7e8765a64a1d3c8775914745ee280f8d', 'battle_rule_v1:ab258dce31ac650782de9f06e8036162', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"artifact_or_creature","mana_produced":1,"mana_source_requires_untapped_artifact_or_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CitanulStalwart translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaspera sentinel', 'Jaspera Sentinel', 'a9e1a252d2d06280c9f7a5f4b2ba213f', 'battle_rule_v1:53fddee02366902e529f36face750f2d', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","ReachAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JasperaSentinel translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam dryad', 'Loam Dryad', 'bc0d67ab4c23dc0ffed1100c30eac1d5', 'battle_rule_v1:4d6e4eddb7fc0a7a794f0af96f4f5fe5', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamDryad translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saruli caretaker', 'Saruli Caretaker', '0b9879abab7f49482456a5969bbeabd2', 'battle_rule_v1:6cf57a838d0947fad3c0c9b6e13f9014', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","DefenderAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SaruliCaretaker translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
