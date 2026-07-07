BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg642_counter_stack_object_targets_new_s_20260707_213839 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('disallow', 'stern scolding', 'tale''s end', 'voidslime')
   OR normalized_name LIKE 'disallow // %'
   OR normalized_name LIKE 'stern scolding // %'
   OR normalized_name LIKE 'tale''s end // %'
   OR normalized_name LIKE 'voidslime // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('disallow', 'Disallow', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disallow translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stern scolding', 'Stern Scolding', 'f26dd82537e6e5c9206d47a50fa691c3', 'battle_rule_v1:5286b6c6a626a88c60e657c46eef1105', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_power_or_toughness_2_or_less","target_constraints":{"card_types":["creature"],"power_or_toughness_max":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_power_or_toughness_2_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SternScolding translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tale''s end', 'Tale''s End', '1347d000d1e4acf8d2675e1ed216b6f7', 'battle_rule_v1:f70b57cccbd61a55ec60298342a6613c', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"activated_or_triggered_ability_or_legendary_spell","target_constraints":{"any_of":[{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"},{"require_legendary":true,"stack_object":"spell"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_or_triggered_ability_or_legendary_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalesEnd translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('voidslime', 'Voidslime', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Voidslime translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('disallow', 'Disallow', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disallow translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stern scolding', 'Stern Scolding', 'f26dd82537e6e5c9206d47a50fa691c3', 'battle_rule_v1:5286b6c6a626a88c60e657c46eef1105', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_power_or_toughness_2_or_less","target_constraints":{"card_types":["creature"],"power_or_toughness_max":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_power_or_toughness_2_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SternScolding translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tale''s end', 'Tale''s End', '1347d000d1e4acf8d2675e1ed216b6f7', 'battle_rule_v1:f70b57cccbd61a55ec60298342a6613c', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"activated_or_triggered_ability_or_legendary_spell","target_constraints":{"any_of":[{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"},{"require_legendary":true,"stack_object":"spell"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_or_triggered_ability_or_legendary_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalesEnd translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('voidslime', 'Voidslime', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Voidslime translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('disallow', 'Disallow', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disallow translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stern scolding', 'Stern Scolding', 'f26dd82537e6e5c9206d47a50fa691c3', 'battle_rule_v1:5286b6c6a626a88c60e657c46eef1105', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_power_or_toughness_2_or_less","target_constraints":{"card_types":["creature"],"power_or_toughness_max":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_power_or_toughness_2_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SternScolding translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tale''s end', 'Tale''s End', '1347d000d1e4acf8d2675e1ed216b6f7', 'battle_rule_v1:f70b57cccbd61a55ec60298342a6613c', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"activated_or_triggered_ability_or_legendary_spell","target_constraints":{"any_of":[{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"},{"require_legendary":true,"stack_object":"spell"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_or_triggered_ability_or_legendary_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalesEnd translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('voidslime', 'Voidslime', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Voidslime translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
