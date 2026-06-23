-- PG068 deck6 copy/token-copy stack rules apply.
-- Promotes oracle-hashed runtime scopes for Dualcaster Mage, Reiterate,
-- Heat Shimmer, Twinflame, and Molten Duplication.

\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name IN (
  'dualcaster mage',
  'reiterate',
  'heat shimmer',
  'twinflame',
  'molten duplication'
);

DO $$
DECLARE
  v_backup_rows integer;
  v_target_cards integer;
  v_deck6_rows integer;
  v_hash_matches integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443;

  WITH target_rules(card_name, normalized_name, expected_oracle_hash) AS (
    VALUES
      ('Dualcaster Mage', 'dualcaster mage', 'e26f613394b72e9724d299512983218a'),
      ('Reiterate', 'reiterate', '996fb5f02f16605ff7f1c899f2c50f60'),
      ('Heat Shimmer', 'heat shimmer', '9c4cfbeb99bfea90a8a5d4c3c7894793'),
      ('Twinflame', 'twinflame', 'd9c51f63ac78f713113c52feadfba6db'),
      ('Molten Duplication', 'molten duplication', '7c24d56660499c0af4db967925de1573')
  ),
  resolved AS (
    SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
    FROM target_rules tr
    LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
  )
  SELECT
    count(*) FILTER (WHERE card_id IS NOT NULL),
    count(*) FILTER (WHERE live_oracle_hash = expected_oracle_hash)
  INTO v_target_cards, v_hash_matches
  FROM resolved;

  SELECT count(*) INTO v_deck6_rows
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND lower(c.name) IN (
      'dualcaster mage',
      'reiterate',
      'heat shimmer',
      'twinflame',
      'molten duplication'
    );

  IF v_backup_rows <> 12 THEN
    RAISE EXCEPTION 'PG068 precondition failed: backup_rows=% expected 12', v_backup_rows;
  END IF;
  IF v_target_cards <> 5 THEN
    RAISE EXCEPTION 'PG068 precondition failed: target_cards=% expected 5', v_target_cards;
  END IF;
  IF v_deck6_rows <> 5 THEN
    RAISE EXCEPTION 'PG068 precondition failed: deck6_rows=% expected 5', v_deck6_rows;
  END IF;
  IF v_hash_matches <> 5 THEN
    RAISE EXCEPTION 'PG068 precondition failed: oracle_hash_matches=% expected 5', v_hash_matches;
  END IF;
END $$;

WITH target_rule(
  normalized_name,
  card_name,
  logical_rule_key,
  expected_oracle_hash,
  effect_json,
  deck_role_json,
  confidence,
  notes
) AS (
  VALUES
    (
      'dualcaster mage',
      'Dualcaster Mage',
      'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
      'e26f613394b72e9724d299512983218a',
      jsonb_build_object(
        'cmc', 3.0,
        'effect', 'copy_spell',
        'instant', true,
        'keywords', jsonb_build_array('flash'),
        'is_creature_permanent', true,
        'power', 2,
        'toughness', 2,
        'etb_copy_spell', true,
        'target', 'instant_or_sorcery_on_stack',
        'copy_is_not_cast', true,
        'may_choose_new_targets', true,
        'choose_new_targets_status', 'annotation_only',
        'battle_model_scope', 'creature_etb_copy_stack_instant_or_sorcery_v1'
      ),
      jsonb_build_object(
        'category', 'interaction',
        'effect', 'copy_spell',
        'timing', 'flash_creature_etb',
        'target', 'instant_or_sorcery_on_stack'
      ),
      0.92,
      'PG068: oracle-hashed Dualcaster Mage runtime model. Flash creature resolves as a permanent, then its ETB copies a legal instant/sorcery on the stack as a non-cast copy. Retargeting remains annotation_only.'
    ),
    (
      'reiterate',
      'Reiterate',
      'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405',
      '996fb5f02f16605ff7f1c899f2c50f60',
      jsonb_build_object(
        'cmc', 3.0,
        'effect', 'copy_spell',
        'instant', true,
        'target', 'instant_or_sorcery_on_stack',
        'copy_is_not_cast', true,
        'may_choose_new_targets', true,
        'choose_new_targets_status', 'annotation_only',
        'buyback_status', 'annotation_only',
        'battle_model_scope', 'copy_stack_instant_or_sorcery_buyback_annotation_v1'
      ),
      jsonb_build_object(
        'category', 'interaction',
        'effect', 'copy_spell',
        'timing', 'instant',
        'target', 'instant_or_sorcery_on_stack'
      ),
      0.91,
      'PG068: oracle-hashed Reiterate runtime model. Runtime copies a legal instant/sorcery spell on stack as a non-cast copy; buyback and retargeting stay annotation_only.'
    ),
    (
      'heat shimmer',
      'Heat Shimmer',
      'battle_rule_v1:644897bfa688d33b1a718723360e2480',
      '9c4cfbeb99bfea90a8a5d4c3c7894793',
      jsonb_build_object(
        'cmc', 3.0,
        'effect', 'copy_creature_token',
        'target_controller', 'any',
        'copy_target_types', jsonb_build_array('creature'),
        'token_haste', true,
        'exile_token_at_end_step', true,
        'battle_model_scope', 'target_creature_copy_haste_exile_eot_v1'
      ),
      jsonb_build_object(
        'category', 'threat',
        'effect', 'copy_creature_token',
        'subtype', 'temporary_hasty_copy',
        'target', 'any_creature'
      ),
      0.91,
      'PG068: oracle-hashed Heat Shimmer runtime model. Runtime creates one hasty copy token of the best legal creature from any controller and exiles it at end step.'
    ),
    (
      'twinflame',
      'Twinflame',
      'battle_rule_v1:97ab0167213936bfa544f19731284e56',
      'd9c51f63ac78f713113c52feadfba6db',
      jsonb_build_object(
        'cmc', 2.0,
        'effect', 'copy_creature_token',
        'target_controller', 'own',
        'copy_target_types', jsonb_build_array('creature'),
        'token_haste', true,
        'exile_token_at_end_step', true,
        'strive_multi_target_status', 'annotation_only_single_best_own_creature',
        'battle_model_scope', 'own_creature_single_copy_haste_exile_eot_v1'
      ),
      jsonb_build_object(
        'category', 'combo',
        'effect', 'copy_creature_token',
        'subtype', 'temporary_hasty_copy',
        'target', 'own_creature'
      ),
      0.90,
      'PG068: oracle-hashed Twinflame runtime model. Runtime executes the single best own-creature hasty copy and exiles it at end step; multi-target Strive remains annotation_only.'
    ),
    (
      'molten duplication',
      'Molten Duplication',
      'battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69',
      '7c24d56660499c0af4db967925de1573',
      jsonb_build_object(
        'cmc', 2.0,
        'effect', 'copy_creature_token',
        'target_controller', 'own',
        'copy_target_types', jsonb_build_array('artifact', 'creature'),
        'artifact_in_addition', true,
        'token_haste', true,
        'sacrifice_token_at_end_step', true,
        'battle_model_scope', 'own_artifact_or_creature_copy_artifact_haste_sacrifice_eot_v1'
      ),
      jsonb_build_object(
        'category', 'combo',
        'effect', 'copy_creature_token',
        'subtype', 'temporary_artifact_copy',
        'target', 'own_artifact_or_creature'
      ),
      0.90,
      'PG068: oracle-hashed Molten Duplication runtime model. Runtime copies the best own artifact/creature target, marks artifact-in-addition, grants haste where relevant, and sacrifices the token at end step.'
    )
),
resolved AS (
  SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_rule tr
  JOIN cards c ON lower(c.name) = tr.normalized_name
)
INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
)
SELECT
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  'curated',
  confidence,
  'active',
  'auto',
  1,
  expected_oracle_hash,
  notes,
  'codex_central_auditor_pg068',
  now(),
  now(),
  now(),
  now()
FROM resolved
WHERE live_oracle_hash = expected_oracle_hash
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  updated_at = now(),
  last_seen_at = now();

WITH target_rule(normalized_name, logical_rule_key) AS (
  VALUES
    ('dualcaster mage', 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55'),
    ('reiterate', 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'),
    ('heat shimmer', 'battle_rule_v1:644897bfa688d33b1a718723360e2480'),
    ('twinflame', 'battle_rule_v1:97ab0167213936bfa544f19731284e56'),
    ('molten duplication', 'battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69')
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG068 2026-06-23: Disabled superseded generic/shadow copy or token-copy row after promoting oracle-hashed deck6 copy/token-copy runtime rule.'
  ),
  updated_at = now(),
  last_seen_at = now()
FROM target_rule tr
WHERE cbr.normalized_name = tr.normalized_name
  AND cbr.logical_rule_key <> tr.logical_rule_key
  AND cbr.review_status NOT IN ('deprecated', 'rejected');

COMMIT;
