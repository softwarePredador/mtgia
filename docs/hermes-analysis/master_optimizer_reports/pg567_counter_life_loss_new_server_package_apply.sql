BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg567_counter_life_loss_new_server_20260706_124236 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('countersquall', 'psychic barrier', 'undermine')
   OR normalized_name LIKE 'countersquall // %'
   OR normalized_name LIKE 'psychic barrier // %'
   OR normalized_name LIKE 'undermine // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('countersquall', 'Countersquall', 'd11f89ab2042320e17aa9df329f10dc7', 'battle_rule_v1:f447ed982ad715fdcb2e953a58d5165c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":2,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":2,"life_loss_on_counter":2,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":2,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"noncreature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countersquall translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic barrier', 'Psychic Barrier', '24afa1ac0b2f719e88b1ab657b86243e', 'battle_rule_v1:06b4050177f0ce18ffc74b822d1c8e89', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":1,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":1,"life_loss_on_counter":1,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":1,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicBarrier translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('undermine', 'Undermine', 'a2fafff02a4e52fdfb9778567baa5a7b', 'battle_rule_v1:712f2d24087fbcb90adbc83f61d36f86', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":3,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":3,"life_loss_on_counter":3,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":3,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Undermine translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('countersquall', 'Countersquall', 'd11f89ab2042320e17aa9df329f10dc7', 'battle_rule_v1:f447ed982ad715fdcb2e953a58d5165c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":2,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":2,"life_loss_on_counter":2,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":2,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"noncreature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countersquall translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic barrier', 'Psychic Barrier', '24afa1ac0b2f719e88b1ab657b86243e', 'battle_rule_v1:06b4050177f0ce18ffc74b822d1c8e89', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":1,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":1,"life_loss_on_counter":1,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":1,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicBarrier translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('undermine', 'Undermine', 'a2fafff02a4e52fdfb9778567baa5a7b', 'battle_rule_v1:712f2d24087fbcb90adbc83f61d36f86', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":3,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":3,"life_loss_on_counter":3,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":3,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Undermine translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('countersquall', 'Countersquall', 'd11f89ab2042320e17aa9df329f10dc7', 'battle_rule_v1:f447ed982ad715fdcb2e953a58d5165c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":2,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":2,"life_loss_on_counter":2,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"noncreature_spell","target_constraints":{"exclude_card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":2,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"noncreature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Countersquall translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('psychic barrier', 'Psychic Barrier', '24afa1ac0b2f719e88b1ab657b86243e', 'battle_rule_v1:06b4050177f0ce18ffc74b822d1c8e89', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":1,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":1,"life_loss_on_counter":1,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":1,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PsychicBarrier translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('undermine', 'Undermine', 'a2fafff02a4e52fdfb9778567baa5a7b', 'battle_rule_v1:712f2d24087fbcb90adbc83f61d36f86', '{"_composite_rule_components":[{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"},{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss_amount":3,"target":"target_controller","xmage_effect_class":"LoseLifeTargetControllerEffect"}],"battle_model_scope":"xmage_counter_target_and_target_controller_loses_life_spell_v1","effect":"counter","instant":true,"life_loss_amount":3,"life_loss_on_counter":3,"resolution_order":"counter_then_target_controller_life_loss","sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_controller_life_loss_on_counter":3,"xmage_effect_classes":["CounterTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Undermine translated into ManaLoom runtime scope xmage_counter_target_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed counter-target spell with target-controller life loss with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
