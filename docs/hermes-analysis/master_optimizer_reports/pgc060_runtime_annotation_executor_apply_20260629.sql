BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc060_runtime_annotation_executor_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC060 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc060_runtime_annotation_executor_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE (normalized_name = 'furygale flocking'
   AND logical_rule_key = 'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5')
   OR (normalized_name = 'tempt with bunnies'
   AND logical_rule_key IN (
     'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
     'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
   ));

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || $json${
      "attack_each_opponent_this_turn_status": "runtime_executor_v1",
      "battle_model_scope": "per_opponent_two_3_3_flying_hasty_elementals_graveyard_cost_reduction_runtime_attack_requirement_v1",
      "oracle_runtime_scope": "graveyard_instant_sorcery_cost_reduction_runtime_per_opponent_tokens_attack_requirement_v1"
    }$json$::jsonb,
    rule_version = greatest(r.rule_version + 1, 4),
    reviewed_by = 'codex-pgc060',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC060: promoted Furygale Flocking per-opponent attack assignment from annotation_only to runtime_executor_v1 after batch/no-override runtime probe.'
    )
  WHERE r.normalized_name = 'furygale flocking'
    AND r.logical_rule_key = 'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.oracle_hash = '8946b0e85c8430c6105ea70c7fb2724a';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 1 THEN
    RAISE EXCEPTION 'PGC060 expected to update 1 Furygale row, updated %', updated_count;
  END IF;
END $$;

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || CASE r.logical_rule_key
      WHEN 'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86' THEN $json${
        "tempting_offer_opponent_choice_status": "runtime_executor_v1",
        "battle_model_scope": "tempting_offer_base_create_1_1_white_rabbit_component_runtime_v1",
        "oracle_runtime_scope": "tempting_offer_base_create_1_1_white_rabbit_opponent_choice_runtime_v1"
      }$json$::jsonb
      WHEN 'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80' THEN $json${
        "tempting_offer_opponent_choice_status": "runtime_executor_v1",
        "battle_model_scope": "tempting_offer_base_draw_one_component_runtime_v1",
        "oracle_runtime_scope": "tempting_offer_base_draw_one_opponent_choice_runtime_v1"
      }$json$::jsonb
      ELSE '{}'::jsonb
    END,
    rule_version = greatest(r.rule_version + 1, 3),
    reviewed_by = 'codex-pgc060',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC060: promoted Tempt with Bunnies tempting-offer opponent choice components from annotation_only to runtime_executor_v1 after batch/no-override runtime probe.'
    )
  WHERE r.normalized_name = 'tempt with bunnies'
    AND r.logical_rule_key IN (
      'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
      'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
    )
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.oracle_hash = '201f6c7234bfef550f3d497e736f0d7a';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 2 THEN
    RAISE EXCEPTION 'PGC060 expected to update 2 Tempt with Bunnies rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
