BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg736_fixed_color_dynamic_mana_new_serve_20260711_025659 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('karametra''s acolyte', 'magus of the coffers', 'priest of titania', 'viridian joiner')
   OR normalized_name LIKE 'karametra''s acolyte // %'
   OR normalized_name LIKE 'magus of the coffers // %'
   OR normalized_name LIKE 'priest of titania // %'
   OR normalized_name LIKE 'viridian joiner // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('karametra''s acolyte', 'Karametra''s Acolyte', '86ef6a0e66d69ce98708d5ce0b56042b', 'battle_rule_v1:dd227cb6ed995b861940b1a20fd98c61', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"devotion_to_green","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Human Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KarametrasAcolyte translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magus of the coffers', 'Magus of the Coffers', '67510b2a763e30208e8994fe303f2aa8', 'battle_rule_v1:b062dff12fc4c68a00586a403c0d2a17', '{"ability_kind":"activated_mana","activation_mana_cost":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["swamp"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"B","source_mana_cost":"{4}{B}","source_type_line":"Creature \u2014 Human Wizard","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagusOfTheCoffers translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of titania', 'Priest of Titania', '6e8046fc4e2e3861e3c4640df24c7a58', 'battle_rule_v1:444642bee4291bcee2fa0714a3de442d', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfTitania translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viridian joiner', 'Viridian Joiner', '314025c76fd5612c62ec3a071d193fd4', 'battle_rule_v1:5184680f67f1492cf91f168740b71798', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViridianJoiner translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('karametra''s acolyte', 'Karametra''s Acolyte', '86ef6a0e66d69ce98708d5ce0b56042b', 'battle_rule_v1:dd227cb6ed995b861940b1a20fd98c61', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"devotion_to_green","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Human Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KarametrasAcolyte translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magus of the coffers', 'Magus of the Coffers', '67510b2a763e30208e8994fe303f2aa8', 'battle_rule_v1:b062dff12fc4c68a00586a403c0d2a17', '{"ability_kind":"activated_mana","activation_mana_cost":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["swamp"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"B","source_mana_cost":"{4}{B}","source_type_line":"Creature \u2014 Human Wizard","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagusOfTheCoffers translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of titania', 'Priest of Titania', '6e8046fc4e2e3861e3c4640df24c7a58', 'battle_rule_v1:444642bee4291bcee2fa0714a3de442d', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfTitania translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viridian joiner', 'Viridian Joiner', '314025c76fd5612c62ec3a071d193fd4', 'battle_rule_v1:5184680f67f1492cf91f168740b71798', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViridianJoiner translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('karametra''s acolyte', 'Karametra''s Acolyte', '86ef6a0e66d69ce98708d5ce0b56042b', 'battle_rule_v1:dd227cb6ed995b861940b1a20fd98c61', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"devotion_to_green","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Human Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KarametrasAcolyte translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magus of the coffers', 'Magus of the Coffers', '67510b2a763e30208e8994fe303f2aa8', 'battle_rule_v1:b062dff12fc4c68a00586a403c0d2a17', '{"ability_kind":"activated_mana","activation_mana_cost":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["swamp"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"B","source_mana_cost":"{4}{B}","source_type_line":"Creature \u2014 Human Wizard","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagusOfTheCoffers translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of titania', 'Priest of Titania', '6e8046fc4e2e3861e3c4640df24c7a58', 'battle_rule_v1:444642bee4291bcee2fa0714a3de442d', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfTitania translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viridian joiner', 'Viridian Joiner', '314025c76fd5612c62ec3a071d193fd4', 'battle_rule_v1:5184680f67f1492cf91f168740b71798', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViridianJoiner translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
