BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg092_deck608_l7_modal_interaction_20260623_095405 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name IN ('return the favor', 'untimely malfunction');

WITH target_rules AS (
  SELECT *
  FROM (
    VALUES
      (
        'return the favor',
        'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2',
        'Return the Favor',
        'copy_spell',
        'a24911b7ea2027ebba59bb6792eee776',
        jsonb_build_object(
          'cmc', 2.0,
          'effect', 'copy_spell',
          'instant', true,
          'target', 'instant_or_sorcery_on_stack',
          'may_choose_new_targets', true,
          'modes', jsonb_build_array('copy_instant_or_sorcery_spell', 'change_single_target'),
          'spree', true,
          'battle_model_scope', 'spree_copy_instant_or_sorcery_stack_spell_change_target_annotation_v1',
          'oracle_runtime_scope', 'copy_target_instant_or_sorcery_stack_spell_spree_change_target_annotation_v1',
          'spree_additional_cost_status', 'annotation_only',
          'copy_activated_triggered_ability_status', 'annotation_only',
          'change_target_mode_status', 'annotation_only',
          'choose_new_targets_status', 'may_choose_new_targets'
        ),
        jsonb_build_object(
          'effect', 'copy_spell',
          'timing', 'instant',
          'category', 'engine',
          'functions', jsonb_build_array('copy_stack_instant_or_sorcery', 'change_target_annotation'),
          'runtime_modes', jsonb_build_array('stack_copy_target_minimal')
        )
      ),
      (
        'untimely malfunction',
        'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8',
        'Untimely Malfunction',
        'remove_permanent',
        '877f2d75c90c7886ca9536135829bb90',
        jsonb_build_object(
          'cmc', 2.0,
          'effect', 'remove_permanent',
          'instant', true,
          'target', 'artifact',
          'modes', jsonb_build_array('destroy_artifact', 'redirect_target', 'cant_block'),
          'battle_model_scope', 'modal_destroy_artifact_redirect_or_cant_block_annotation_v1',
          'oracle_runtime_scope', 'destroy_target_artifact_redirect_cant_block_annotation_v1',
          'destroy_artifact_mode', true,
          'redirect_target_mode_status', 'annotation_only',
          'cant_block_mode_status', 'annotation_only'
        ),
        jsonb_build_object(
          'effect', 'remove_permanent',
          'timing', 'instant',
          'category', 'removal',
          'modal', true,
          'functions', jsonb_build_array('destroy_artifact', 'redirect_target_annotation', 'cant_block_annotation'),
          'runtime_modes', jsonb_build_array('artifact_target_removal')
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
  0.92,
  'verified',
  'auto',
  2,
  oracle_hash,
  'PG092 L7 modal interaction cleanup: verified Oracle hash/model scope; unsupported modal branches are annotation_only.',
  'codex',
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
    ('return the favor', 'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2'),
    ('untimely malfunction', 'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8')
)
UPDATE card_battle_rules cbr
SET review_status = 'deprecated',
    execution_status = 'disabled',
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'Disabled by PG092 L7 modal interaction cleanup after verified card-specific replacement.'
    ),
    updated_at = now(),
    last_seen_at = now()
FROM target_rules tr
WHERE cbr.normalized_name = tr.normalized_name
  AND cbr.logical_rule_key <> tr.logical_rule_key;

COMMIT;
