\pset pager off

CREATE TEMP TABLE pg068_target_rules AS
SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.notes
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name IN ('dualcaster mage', 'reiterate');

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
        'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
      )
      AND source = 'curated'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND confidence = 1.000
      AND (
        (normalized_name = 'reiterate'
          AND oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60'
          AND effect_json->>'effect' = 'copy_spell'
          AND effect_json->>'battle_model_scope' = 'copy_stack_instant_or_sorcery_buyback_annotation_v1'
          AND effect_json->>'target' = 'instant_or_sorcery_on_stack'
          AND effect_json->>'buyback_status' = 'annotation_only')
        OR
        (normalized_name = 'dualcaster mage'
          AND oracle_hash = 'e26f613394b72e9724d299512983218a'
          AND effect_json->>'effect' = 'copy_spell'
          AND effect_json->>'battle_model_scope' = 'creature_etb_copy_stack_instant_or_sorcery_v1'
          AND effect_json->>'target' = 'instant_or_sorcery_on_stack'
          AND coalesce((effect_json->>'etb_copy_spell')::boolean, false) IS true
          AND coalesce((effect_json->>'is_creature_permanent')::boolean, false) IS true)
      )
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE logical_rule_key NOT IN (
        'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
        'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
      )
      AND review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg068_deck6_l5a_copy_spell_stack_20260623_004158
  ) AS backup_rows
FROM pg068_target_rules;

SELECT
  name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM pg068_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
