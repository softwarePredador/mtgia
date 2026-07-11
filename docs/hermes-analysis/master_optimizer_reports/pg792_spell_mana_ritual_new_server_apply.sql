BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg792_spell_mana_ritual_20260711_225729 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('battle hymn', 'channel the suns', 'inner fire', 'songs of the damned')
   OR normalized_name LIKE 'battle hymn // %'
   OR normalized_name LIKE 'channel the suns // %'
   OR normalized_name LIKE 'inner fire // %'
   OR normalized_name LIKE 'songs of the damned // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('battle hymn', 'Battle Hymn', 'd10736bf0f1c20741e6573e8a0f9756f', 'battle_rule_v1:ecc388cb0b7a7b6053fa356c319a35d0', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_battlefield_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_battlefield_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleHymn translated into ManaLoom runtime scope xmage_controlled_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('channel the suns', 'Channel the Suns', '00f37ae750187d98c2ee7ef1cefe2d81', 'battle_rule_v1:99bac902f7bd0c57a57d2986e5798b55', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","effect":"ramp_ritual","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":5,"produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","sorcery":true,"xmage_effect_class":"AddManaToManaPoolSourceControllerEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChannelTheSuns translated into ManaLoom runtime scope xmage_fixed_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inner fire', 'Inner Fire', '8a7377dabd39dd4288983536683a62c2', 'battle_rule_v1:5c3ffd7cf5ad80a9c9334df4e439b863', '{"ability_kind":"one_shot","battle_model_scope":"xmage_hand_size_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_hand_size","effect":"ramp_ritual","instant":false,"mana_amount_model":"controller_hand_size","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":true,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnerFire translated into ManaLoom runtime scope xmage_hand_size_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('songs of the damned', 'Songs of the Damned', 'bd0c43c5486b85ec17a57ad84ebfef68', 'battle_rule_v1:5a7a56cb9e6b6ff52ebe704b292915ba', '{"ability_kind":"one_shot","battle_model_scope":"xmage_graveyard_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_graveyard_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_graveyard_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"B","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SongsOfTheDamned translated into ManaLoom runtime scope xmage_graveyard_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('battle hymn', 'Battle Hymn', 'd10736bf0f1c20741e6573e8a0f9756f', 'battle_rule_v1:ecc388cb0b7a7b6053fa356c319a35d0', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_battlefield_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_battlefield_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleHymn translated into ManaLoom runtime scope xmage_controlled_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('channel the suns', 'Channel the Suns', '00f37ae750187d98c2ee7ef1cefe2d81', 'battle_rule_v1:99bac902f7bd0c57a57d2986e5798b55', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","effect":"ramp_ritual","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":5,"produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","sorcery":true,"xmage_effect_class":"AddManaToManaPoolSourceControllerEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChannelTheSuns translated into ManaLoom runtime scope xmage_fixed_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inner fire', 'Inner Fire', '8a7377dabd39dd4288983536683a62c2', 'battle_rule_v1:5c3ffd7cf5ad80a9c9334df4e439b863', '{"ability_kind":"one_shot","battle_model_scope":"xmage_hand_size_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_hand_size","effect":"ramp_ritual","instant":false,"mana_amount_model":"controller_hand_size","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":true,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnerFire translated into ManaLoom runtime scope xmage_hand_size_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('songs of the damned', 'Songs of the Damned', 'bd0c43c5486b85ec17a57ad84ebfef68', 'battle_rule_v1:5a7a56cb9e6b6ff52ebe704b292915ba', '{"ability_kind":"one_shot","battle_model_scope":"xmage_graveyard_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_graveyard_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_graveyard_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"B","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SongsOfTheDamned translated into ManaLoom runtime scope xmage_graveyard_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('battle hymn', 'Battle Hymn', 'd10736bf0f1c20741e6573e8a0f9756f', 'battle_rule_v1:ecc388cb0b7a7b6053fa356c319a35d0', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_battlefield_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_battlefield_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleHymn translated into ManaLoom runtime scope xmage_controlled_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('channel the suns', 'Channel the Suns', '00f37ae750187d98c2ee7ef1cefe2d81', 'battle_rule_v1:99bac902f7bd0c57a57d2986e5798b55', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","effect":"ramp_ritual","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":5,"produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","sorcery":true,"xmage_effect_class":"AddManaToManaPoolSourceControllerEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChannelTheSuns translated into ManaLoom runtime scope xmage_fixed_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inner fire', 'Inner Fire', '8a7377dabd39dd4288983536683a62c2', 'battle_rule_v1:5c3ffd7cf5ad80a9c9334df4e439b863', '{"ability_kind":"one_shot","battle_model_scope":"xmage_hand_size_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_hand_size","effect":"ramp_ritual","instant":false,"mana_amount_model":"controller_hand_size","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":true,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnerFire translated into ManaLoom runtime scope xmage_hand_size_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('songs of the damned', 'Songs of the Damned', 'bd0c43c5486b85ec17a57ad84ebfef68', 'battle_rule_v1:5a7a56cb9e6b6ff52ebe704b292915ba', '{"ability_kind":"one_shot","battle_model_scope":"xmage_graveyard_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_graveyard_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_graveyard_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"B","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SongsOfTheDamned translated into ManaLoom runtime scope xmage_graveyard_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
