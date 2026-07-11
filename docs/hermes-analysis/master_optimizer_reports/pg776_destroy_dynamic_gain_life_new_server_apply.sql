BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg776_destroy_dynamic_gain_life_new_serv_20260711_172405 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('divine offering', 'molder', 'serene offering', 'tidy conclusion')
   OR normalized_name LIKE 'divine offering // %'
   OR normalized_name LIKE 'molder // %'
   OR normalized_name LIKE 'serene offering // %'
   OR normalized_name LIKE 'tidy conclusion // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('divine offering', 'Divine Offering', '0c067819a69c20217f9b19b711d92400', 'battle_rule_v1:384969d75fc0ceb3fc48e0fbadd1c0ca', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DivineOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('molder', 'Molder', '8d0f792325fcc149eaadf57e53ed1949', 'battle_rule_v1:ad6e9448ff14addb039ac653ac28c528', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"x_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"],"target_mana_value_source":"x_value"},"target_mana_value_exact_from_x":true,"target_mana_value_source":"x_value","xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Molder translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene offering', 'Serene Offering', '514db4af9246c82d3b8817c1feef0f51', 'battle_rule_v1:45d637ad04edc0bd7690d28ff510deab', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidy conclusion', 'Tidy Conclusion', '2b0c7ef2b530e70f2069bc11f7860ce1', 'battle_rule_v1:9ac359aa50729b9baf3955aa613a4cce', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","controller_gain_life_source":"battlefield_permanent_count","controller_gains_life":0,"destination":"graveyard","effect":"remove_creature","instant":true,"life_gain_per_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidyConclusion translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('divine offering', 'Divine Offering', '0c067819a69c20217f9b19b711d92400', 'battle_rule_v1:384969d75fc0ceb3fc48e0fbadd1c0ca', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DivineOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('molder', 'Molder', '8d0f792325fcc149eaadf57e53ed1949', 'battle_rule_v1:ad6e9448ff14addb039ac653ac28c528', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"x_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"],"target_mana_value_source":"x_value"},"target_mana_value_exact_from_x":true,"target_mana_value_source":"x_value","xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Molder translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene offering', 'Serene Offering', '514db4af9246c82d3b8817c1feef0f51', 'battle_rule_v1:45d637ad04edc0bd7690d28ff510deab', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidy conclusion', 'Tidy Conclusion', '2b0c7ef2b530e70f2069bc11f7860ce1', 'battle_rule_v1:9ac359aa50729b9baf3955aa613a4cce', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","controller_gain_life_source":"battlefield_permanent_count","controller_gains_life":0,"destination":"graveyard","effect":"remove_creature","instant":true,"life_gain_per_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidyConclusion translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('divine offering', 'Divine Offering', '0c067819a69c20217f9b19b711d92400', 'battle_rule_v1:384969d75fc0ceb3fc48e0fbadd1c0ca', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DivineOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('molder', 'Molder', '8d0f792325fcc149eaadf57e53ed1949', 'battle_rule_v1:ad6e9448ff14addb039ac653ac28c528', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"x_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"],"target_mana_value_source":"x_value"},"target_mana_value_exact_from_x":true,"target_mana_value_source":"x_value","xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Molder translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene offering', 'Serene Offering', '514db4af9246c82d3b8817c1feef0f51', 'battle_rule_v1:45d637ad04edc0bd7690d28ff510deab', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidy conclusion', 'Tidy Conclusion', '2b0c7ef2b530e70f2069bc11f7860ce1', 'battle_rule_v1:9ac359aa50729b9baf3955aa613a4cce', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","controller_gain_life_source":"battlefield_permanent_count","controller_gains_life":0,"destination":"graveyard","effect":"remove_creature","instant":true,"life_gain_per_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidyConclusion translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
