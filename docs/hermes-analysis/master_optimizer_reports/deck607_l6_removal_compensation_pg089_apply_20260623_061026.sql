BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg089_deck607_l6_removal_compensation_20260623_061026') IS NOT NULL THEN
    RAISE EXCEPTION 'backup table manaloom_deploy_audit.pg089_deck607_l6_removal_compensation_20260623_061026 already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg089_l6_removal_compensation_target AS
SELECT
  'Generous Gift'::text AS name,
  'generous gift'::text AS normalized_name,
  'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'::text AS promote_from_key,
  'battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c'::text AS expected_logical_rule_key,
  '9363edd299df8476da36798bd527cde1'::text AS expected_oracle_hash,
  'destroy_target_permanent_create_3_3_green_elephant_for_controller_v1'::text AS expected_scope,
  jsonb_build_object(
    'cmc', 3.0,
    'effect', 'remove_permanent',
    'target', 'permanent',
    'instant', true,
    'target_controller_creature_tokens', 1,
    'target_controller_token_name', 'Elephant',
    'target_controller_token_subtype', 'Elephant',
    'target_controller_token_power', 3,
    'target_controller_token_toughness', 3,
    'target_controller_token_colors', jsonb_build_array('G'),
    'compensation_token_status', 'dynamic_creature_token_executor',
    'battle_model_scope', 'destroy_target_permanent_create_3_3_green_elephant_for_controller_v1',
    'oracle_runtime_scope', 'destroy_target_permanent_runtime_create_3_3_green_elephant_for_controller_v1'
  ) AS effect_json,
  jsonb_build_object(
    'effect', 'remove_permanent',
    'category', 'removal',
    'timing', 'instant',
    'functions', jsonb_build_array('destroy_target_permanent', 'target_controller_creature_token_compensation'),
    'runtime_modes', jsonb_build_array('targeted_destroy_permanent', 'creature_token_compensation')
  ) AS deck_role_json
UNION ALL
SELECT
  'Stroke of Midnight',
  'stroke of midnight',
  'battle_rule_v1:9d5afecce0b2500c1dff74bcd97e6eb4',
  'battle_rule_v1:9b50d2f897b561c8c390c9e0e04da417',
  'a885e8190e19cf23b1f4c82563ca111b',
  'destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1',
  jsonb_build_object(
    'cmc', 3.0,
    'effect', 'remove_permanent',
    'target', 'nonland_permanent',
    'instant', true,
    'target_controller_creature_tokens', 1,
    'target_controller_token_name', 'Human',
    'target_controller_token_subtype', 'Human',
    'target_controller_token_power', 1,
    'target_controller_token_toughness', 1,
    'target_controller_token_colors', jsonb_build_array('W'),
    'compensation_token_status', 'dynamic_creature_token_executor',
    'battle_model_scope', 'destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1',
    'oracle_runtime_scope', 'destroy_target_nonland_permanent_runtime_create_1_1_white_human_for_controller_v1'
  ),
  jsonb_build_object(
    'effect', 'remove_permanent',
    'category', 'removal',
    'timing', 'instant',
    'functions', jsonb_build_array('destroy_target_nonland_permanent', 'target_controller_creature_token_compensation'),
    'runtime_modes', jsonb_build_array('targeted_destroy_nonland_permanent', 'creature_token_compensation')
  );

DO $$
DECLARE
  target_count integer;
  card_count integer;
  promotable_count integer;
  oracle_match_count integer;
  conflict_count integer;
BEGIN
  SELECT count(*) INTO target_count FROM pg089_l6_removal_compensation_target;

  SELECT count(*) INTO card_count
  FROM pg089_l6_removal_compensation_target t
  JOIN cards c ON lower(c.name) = t.normalized_name;

  SELECT count(*) INTO promotable_count
  FROM pg089_l6_removal_compensation_target t
  JOIN card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.promote_from_key;

  SELECT count(*) INTO oracle_match_count
  FROM pg089_l6_removal_compensation_target t
  JOIN cards c ON lower(c.name) = t.normalized_name
  WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash;

  SELECT count(*) INTO conflict_count
  FROM card_battle_rules r
  JOIN pg089_l6_removal_compensation_target t
    ON r.logical_rule_key = t.expected_logical_rule_key
   AND r.normalized_name <> t.normalized_name;

  IF target_count <> 2 OR card_count <> 2 OR promotable_count <> 2 OR oracle_match_count <> 2 OR conflict_count <> 0 THEN
    RAISE EXCEPTION 'PG089 precondition failed target=% card=% promotable=% oracle_match=% conflicts=%',
      target_count, card_count, promotable_count, oracle_match_count, conflict_count;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg089_deck607_l6_removal_compensation_20260623_061026 AS
SELECT r.*
FROM card_battle_rules r
JOIN pg089_l6_removal_compensation_target t
  ON r.normalized_name = t.normalized_name;

UPDATE card_battle_rules r
SET
  logical_rule_key = t.expected_logical_rule_key,
  oracle_hash = t.expected_oracle_hash,
  effect_json = t.effect_json,
  deck_role_json = t.deck_role_json,
  source = 'curated',
  confidence = 1.0,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(coalesce(r.rule_version, 1), 2),
  reviewed_by = 'codex-pg089',
  reviewed_at = now(),
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG089 2026-06-23: L6 removal compensation token family. Added card-specific oracle_hash, target scope, and executable creature-token compensation; no deck swap.')
FROM pg089_l6_removal_compensation_target t
WHERE r.normalized_name = t.normalized_name
  AND r.logical_rule_key = t.promote_from_key;

UPDATE card_battle_rules r
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG089 disabled: superseded generated/review-only shadow after card-specific removal compensation rule was validated.')
FROM pg089_l6_removal_compensation_target t
WHERE r.normalized_name = t.normalized_name
  AND r.logical_rule_key <> t.expected_logical_rule_key
  AND (
    r.source = 'generated'
    OR r.review_status IN ('needs_review', 'review_only')
    OR r.execution_status = 'review_only'
  );

COMMIT;
