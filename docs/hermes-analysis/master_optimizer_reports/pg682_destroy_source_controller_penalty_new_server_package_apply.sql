BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg682_destroy_source_controller_penalty_20260709_012940 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('aftershock', 'infernal grasp', 'reckless spite', 'wicked pact', 'withering torment')
   OR normalized_name LIKE 'aftershock // %'
   OR normalized_name LIKE 'infernal grasp // %'
   OR normalized_name LIKE 'reckless spite // %'
   OR normalized_name LIKE 'wicked pact // %'
   OR normalized_name LIKE 'withering torment // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aftershock', 'Aftershock', '35dc73d5a88dc039ddcdffb53181b083', 'battle_rule_v1:100b2701ae685f36978dbaffd5908ee2', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_damage_spell_v1","damage_amount":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"resolution_order":"destroy_then_source_controller_damage","sorcery":true,"source_controller_damage_on_resolve":3,"target":"artifact_creature_or_land","target_constraints":{"card_types":["artifact","creature","land"]},"xmage_effect_classes":["DestroyTargetEffect","DamageControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aftershock translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infernal grasp', 'Infernal Grasp', '3b76619b3ecdbafc14a3015ca3a3073b', 'battle_rule_v1:d6d2ea2bf2839c48250d4142a00650a0', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InfernalGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reckless spite', 'Reckless Spite', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:16f50903bd0ea73d9170b60af44385d3', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RecklessSpite translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wicked pact', 'Wicked Pact', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:4d5b1d988662baacaa8acd4146e95b43', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":true,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WickedPact translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering torment', 'Withering Torment', 'd52f19b218bf50ac4ab71edd91ddc0b0', 'battle_rule_v1:41e281910727fb998934ffbfadeb8883', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringTorment translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aftershock', 'Aftershock', '35dc73d5a88dc039ddcdffb53181b083', 'battle_rule_v1:100b2701ae685f36978dbaffd5908ee2', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_damage_spell_v1","damage_amount":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"resolution_order":"destroy_then_source_controller_damage","sorcery":true,"source_controller_damage_on_resolve":3,"target":"artifact_creature_or_land","target_constraints":{"card_types":["artifact","creature","land"]},"xmage_effect_classes":["DestroyTargetEffect","DamageControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aftershock translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infernal grasp', 'Infernal Grasp', '3b76619b3ecdbafc14a3015ca3a3073b', 'battle_rule_v1:d6d2ea2bf2839c48250d4142a00650a0', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InfernalGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reckless spite', 'Reckless Spite', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:16f50903bd0ea73d9170b60af44385d3', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RecklessSpite translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wicked pact', 'Wicked Pact', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:4d5b1d988662baacaa8acd4146e95b43', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":true,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WickedPact translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering torment', 'Withering Torment', 'd52f19b218bf50ac4ab71edd91ddc0b0', 'battle_rule_v1:41e281910727fb998934ffbfadeb8883', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringTorment translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aftershock', 'Aftershock', '35dc73d5a88dc039ddcdffb53181b083', 'battle_rule_v1:100b2701ae685f36978dbaffd5908ee2', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_damage_spell_v1","damage_amount":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"resolution_order":"destroy_then_source_controller_damage","sorcery":true,"source_controller_damage_on_resolve":3,"target":"artifact_creature_or_land","target_constraints":{"card_types":["artifact","creature","land"]},"xmage_effect_classes":["DestroyTargetEffect","DamageControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aftershock translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infernal grasp', 'Infernal Grasp', '3b76619b3ecdbafc14a3015ca3a3073b', 'battle_rule_v1:d6d2ea2bf2839c48250d4142a00650a0', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InfernalGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reckless spite', 'Reckless Spite', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:16f50903bd0ea73d9170b60af44385d3', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RecklessSpite translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wicked pact', 'Wicked Pact', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:4d5b1d988662baacaa8acd4146e95b43', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":true,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WickedPact translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering torment', 'Withering Torment', 'd52f19b218bf50ac4ab71edd91ddc0b0', 'battle_rule_v1:41e281910727fb998934ffbfadeb8883', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringTorment translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
