BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg093_deck607_insurrection_20260623_100709') IS NOT NULL THEN
    RAISE EXCEPTION 'PG093 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg093_deck607_insurrection_20260623_100709 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'insurrection';

DO $$
DECLARE
  card_rows integer;
  hash_rows integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(c.oracle_text) = 'a756d0c90be63a18b7eaf97582e75b8e')
  INTO card_rows, hash_rows
  FROM cards c
  WHERE lower(c.name) = 'insurrection';

  IF card_rows <> 1 OR hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG093 Insurrection precondition failed: card_rows=%, hash_rows=%',
      card_rows, hash_rows;
  END IF;
END $$;

WITH target_rules AS (
  SELECT *
  FROM (
    VALUES
      (
        'insurrection',
        'battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954',
        'Insurrection',
        'steal_all_creatures',
        'a756d0c90be63a18b7eaf97582e75b8e',
        jsonb_build_object(
          'cmc', 8.0,
          'effect', 'steal_all_creatures',
          'battle_model_scope', 'steal_all_creatures_until_eot_haste_attack_projection_v1',
          'oracle_runtime_scope', 'untap_gain_control_all_creatures_haste_until_eot_compact_attack_projection_v1',
          'control_duration', 'until_end_of_turn',
          'untap_stolen_creatures', true,
          'stolen_creatures_gain_haste', true,
          'runtime_model', 'compact_damage_projection',
          'runtime_limitations', jsonb_build_array(
            'does_not_transfer_objects_to_controller_battlefield',
            'projects_combat_damage_evenly_across_live_opponents'
          )
        ),
        jsonb_build_object(
          'effect', 'steal_all_creatures',
          'timing', 'sorcery',
          'category', 'wincon',
          'functions', jsonb_build_array(
            'untap_all_creatures_annotation',
            'gain_control_all_creatures_until_eot',
            'haste_until_eot',
            'attack_damage_projection'
          ),
          'runtime_modes', jsonb_build_array('compact_damage_projection')
        )
      )
  ) AS v(normalized_name, logical_rule_key, card_name, effect_name, oracle_hash, effect_json, deck_role_json)
),
target_cards AS (
  SELECT tr.*, c.id AS card_id
  FROM target_rules tr
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
  0.94,
  'verified',
  'auto',
  2,
  oracle_hash,
  'PG093 Insurrection cleanup: verified Oracle hash/model scope; runtime remains compact damage projection of gain-control/haste until EOT.',
  'codex-pg093',
  now(),
  now()
FROM target_cards
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = excluded.card_id,
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  execution_status = excluded.execution_status,
  rule_version = excluded.rule_version,
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  updated_at = now(),
  last_seen_at = excluded.last_seen_at;

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('insurrection', 'battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954')
)
UPDATE card_battle_rules cbr
SET review_status = 'deprecated',
    execution_status = 'disabled',
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'Disabled by PG093 Insurrection cleanup after verified card-specific replacement.'
    ),
    updated_at = now(),
    last_seen_at = now()
FROM target_rules tr
WHERE cbr.normalized_name = tr.normalized_name
  AND cbr.logical_rule_key <> tr.logical_rule_key;

COMMIT;
