BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg849_counter_target_controller_mill_new_20260712_224816 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('countermand', 'didn''t say please', 'psychic strike', 'thought collapse')
   OR normalized_name LIKE 'countermand // %'
   OR normalized_name LIKE 'didn''t say please // %'
   OR normalized_name LIKE 'psychic strike // %'
   OR normalized_name LIKE 'thought collapse // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('countermand', 'Countermand', '37339221401fd8154c74806cb83bd49a', 'battle_rule_v1:f402fd7b0ba896c377a82bcafb4211c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":4,"effect":"mill_cards","mill_count":4,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"CountermandEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":4,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":4,"target_player_mill":true,"xmage_effect_classes":["CountermandEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countermand translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('didn''t say please', 'Didn''t Say Please', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:3c0bee9a432ecc6ed6777b2f880a5145', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"DidntSayPleaseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","DidntSayPleaseEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DidntSayPlease translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic strike', 'Psychic Strike', 'cdc9a084c42879b19393966222db8237', 'battle_rule_v1:57349935a74c3f3e23997e05f68a8b1a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"PsychicStrikeEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":2,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":2,"target_player_mill":true,"xmage_effect_classes":["OneShotEffect","PsychicStrikeEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicStrike translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought collapse', 'Thought Collapse', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:be6aee29492f6a8dda8894351e7e3474', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"ThoughtCollapseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","OneShotEffect","ThoughtCollapseEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtCollapse translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('countermand', 'Countermand', '37339221401fd8154c74806cb83bd49a', 'battle_rule_v1:f402fd7b0ba896c377a82bcafb4211c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":4,"effect":"mill_cards","mill_count":4,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"CountermandEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":4,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":4,"target_player_mill":true,"xmage_effect_classes":["CountermandEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countermand translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('didn''t say please', 'Didn''t Say Please', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:3c0bee9a432ecc6ed6777b2f880a5145', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"DidntSayPleaseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","DidntSayPleaseEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DidntSayPlease translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic strike', 'Psychic Strike', 'cdc9a084c42879b19393966222db8237', 'battle_rule_v1:57349935a74c3f3e23997e05f68a8b1a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"PsychicStrikeEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":2,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":2,"target_player_mill":true,"xmage_effect_classes":["OneShotEffect","PsychicStrikeEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicStrike translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought collapse', 'Thought Collapse', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:be6aee29492f6a8dda8894351e7e3474', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"ThoughtCollapseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","OneShotEffect","ThoughtCollapseEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtCollapse translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('countermand', 'Countermand', '37339221401fd8154c74806cb83bd49a', 'battle_rule_v1:f402fd7b0ba896c377a82bcafb4211c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":4,"effect":"mill_cards","mill_count":4,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"CountermandEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":4,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":4,"target_player_mill":true,"xmage_effect_classes":["CountermandEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countermand translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('didn''t say please', 'Didn''t Say Please', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:3c0bee9a432ecc6ed6777b2f880a5145', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"DidntSayPleaseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","DidntSayPleaseEffect","OneShotEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DidntSayPlease translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic strike', 'Psychic Strike', 'cdc9a084c42879b19393966222db8237', 'battle_rule_v1:57349935a74c3f3e23997e05f68a8b1a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"PsychicStrikeEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":2,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":2,"target_player_mill":true,"xmage_effect_classes":["OneShotEffect","PsychicStrikeEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicStrike translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought collapse', 'Thought Collapse', '1d9b8324a53964a8dc4a4b79ca4e0ac2', 'battle_rule_v1:be6aee29492f6a8dda8894351e7e3474', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"target_controller","target_player_mill":true,"xmage_effect_class":"ThoughtCollapseEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_mill_spell_v1","effect":"counter","instant":true,"mill_count":3,"resolution_order":"counter_then_target_controller_mill","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_mill_on_counter":3,"target_player_mill":true,"xmage_effect_classes":["CounterTargetEffect","OneShotEffect","ThoughtCollapseEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtCollapse translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
