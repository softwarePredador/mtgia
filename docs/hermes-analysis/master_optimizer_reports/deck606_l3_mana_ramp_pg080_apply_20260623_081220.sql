\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg080_deck606_l3_mana_ramp_20260623_081220 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name IN ('monologue tax', 'mox opal', 'simian spirit guide');

DO $$
DECLARE
  updated_count integer;
  shadow_count integer;
BEGIN
  WITH expected(normalized_name, old_logical_rule_key, new_logical_rule_key, oracle_hash, effect_json, deck_role_json) AS (
    VALUES
      (
        'monologue tax',
        'battle_rule_v1:f1e0d9cb7e20dbb87296e1fc11566ad5',
        'battle_rule_v1:4c6a09e794fd065ea945bb51e8fe045d',
        'ebe3a1480ad7cad5f9de5567b06db92e',
        '{"effect":"ramp_engine","trigger":"opponent_spell","opponent_second_spell_each_turn":true,"treasure_count":1,"battle_model_scope":"opponent_second_spell_each_turn_create_treasure_v1","oracle_runtime_scope":"opponent_second_spell_each_turn_treasure_trigger_compact_v1","cmc":3.0}'::jsonb,
        '{"effect":"ramp_engine","category":"ramp","functions":["tax","treasure","spell_count_payoff"],"runtime_modes":["opponent_second_spell_create_treasure"]}'::jsonb
      ),
      (
        'mox opal',
        'battle_rule_v1:a5270b2fac934dee9b6efc9d0e2ea81d',
        'battle_rule_v1:b236b60de8fac9e692f1442119330f34',
        '24b582b5091c110d1da08fec15ad07a1',
        '{"effect":"ramp_permanent","produces":"WUBRGC","mana_produced":1,"metalcraft_required":true,"metalcraft_artifact_threshold":3,"battle_model_scope":"metalcraft_three_artifacts_any_color_mana_rock_v1","oracle_runtime_scope":"metalcraft_checked_on_mana_refresh_v1","cmc":0.0}'::jsonb,
        '{"effect":"ramp_permanent","category":"ramp","functions":["fast_mana","color_fixing","artifact_threshold"],"runtime_modes":["metalcraft_any_color_mana"]}'::jsonb
      ),
      (
        'simian spirit guide',
        'battle_rule_v1:4e1327303383797ace516af3151eed77',
        'battle_rule_v1:5ceeb0717088fe3c67faab83de1a48c9',
        'd48d6662206fd4ed5137e37ec214e46d',
        '{"effect":"ramp_ritual","produces":"R","mana_produced":1,"source_zone":"hand","hand_exile_mana_ability":true,"mana_color_status":"abstracted_to_generic_pool_runtime","battle_model_scope":"hand_exile_red_mana_ability_v1","oracle_runtime_scope":"hand_exile_for_red_mana_generic_pool_runtime_v1","cmc":3.0}'::jsonb,
        '{"effect":"ramp_ritual","timing":"mana_ability","category":"ramp","functions":["one_shot_mana","hand_exile_cost"],"runtime_modes":["hand_exile_add_red_mana"]}'::jsonb
      )
  )
  UPDATE card_battle_rules cbr
  SET logical_rule_key = expected.new_logical_rule_key,
      effect_json = expected.effect_json,
      deck_role_json = expected.deck_role_json,
      oracle_hash = expected.oracle_hash,
      confidence = 0.97,
      review_status = 'verified',
      execution_status = 'auto',
      rule_version = GREATEST(cbr.rule_version, 2),
      reviewed_by = 'codex_pg080_l3_mana_ramp_family',
      reviewed_at = now(),
      updated_at = now(),
      notes = concat_ws(E'\n', NULLIF(cbr.notes, ''), 'PG080 L3 deck606 mana/ramp family: oracle-specific scope + hash; runtime-safe executor verified.')
  FROM expected
  WHERE cbr.normalized_name = expected.normalized_name
    AND cbr.logical_rule_key = expected.old_logical_rule_key
    AND cbr.source = 'curated'
    AND cbr.review_status = 'verified'
    AND cbr.execution_status = 'auto';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 3 THEN
    RAISE EXCEPTION 'PG080 expected 3 trusted rule updates, got %', updated_count;
  END IF;

  WITH expected(normalized_name) AS (
    VALUES ('monologue tax'), ('mox opal'), ('simian spirit guide')
  )
  UPDATE card_battle_rules cbr
  SET review_status = 'deprecated',
      execution_status = 'disabled',
      updated_at = now(),
      notes = concat_ws(E'\n', NULLIF(cbr.notes, ''), 'PG080 disabled generated shadow after trusted L3 mana/ramp rule promotion.')
  FROM expected
  WHERE cbr.normalized_name = expected.normalized_name
    AND cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only';

  GET DIAGNOSTICS shadow_count = ROW_COUNT;
  IF shadow_count <> 3 THEN
    RAISE EXCEPTION 'PG080 expected 3 generated shadow disables, got %', shadow_count;
  END IF;
END $$;

COMMIT;
