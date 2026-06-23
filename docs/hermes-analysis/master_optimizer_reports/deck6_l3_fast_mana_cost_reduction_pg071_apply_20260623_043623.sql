BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg071_deck6_l3_fast_mana_cost_reduction_20260623_043623') IS NOT NULL THEN
    RAISE EXCEPTION 'PG071 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg071_deck6_l3_fast_mana_cost_reduction_20260623_043623 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('lotus petal', 'ruby medallion');

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_specific integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE (
      c.name = 'Lotus Petal'
      AND md5(coalesce(c.oracle_text, '')) = 'a5b9069217908acfd75c5704b414b035'
    )
    OR (
      c.name = 'Ruby Medallion'
      AND md5(coalesce(c.oracle_text, '')) = '52bc55846d69bacf3afba1ffa734b81e'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('lotus petal', 'ruby medallion');

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE (normalized_name = 'lotus petal'
      AND logical_rule_key = 'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d')
    OR (normalized_name = 'ruby medallion'
      AND logical_rule_key = 'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a');

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG071 precondition failed: expected 2 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG071 precondition failed: expected 4 target rules, got %', v_rules;
  END IF;
  IF v_specific <> 2 THEN
    RAISE EXCEPTION 'PG071 precondition failed: expected 2 existing curated runtime rows, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = 'a5b9069217908acfd75c5704b414b035',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'ramp_ritual',
    'artifact', true,
    'mana_produced', 1,
    'produces', 'WUBRGC',
    'activation_cost', 'tap_sacrifice_self',
    'sacrifice_self_for_mana', true,
    'battle_model_scope', 'zero_mana_artifact_sacrifice_one_mana_one_shot_runtime_v1',
    'oracle_runtime_scope', 'tap_sacrifice_artifact_add_one_mana_any_color_runtime_as_one_shot_mana_v1',
    'activation_timing_status', 'runtime_abstracts_cast_then_tap_sacrifice_to_same_turn_one_shot_mana',
    'color_model_status', 'any_color_abstracted_to_generic_pool_runtime'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'ramp_ritual',
    'category', 'ramp',
    'artifact', true,
    'one_shot_fast_mana', true
  ),
  confidence = 0.970,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG071: scoped Lotus Petal as zero-mana artifact fast mana; runtime abstracts tap+sacrifice into one-shot same-turn mana and does not model it as recurring ramp.'
  )
WHERE normalized_name = 'lotus petal'
  AND logical_rule_key = 'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d';

UPDATE card_battle_rules
SET
  oracle_hash = '52bc55846d69bacf3afba1ffa734b81e',
  effect_json = jsonb_build_object(
    'effect', 'passive',
    'artifact', true,
    'cost_reduction', 1,
    'cost_reduction_color', 'R',
    'cost_reduction_applies_to', 'red_spells_you_cast',
    'battle_model_scope', 'red_spell_cost_reduction_annotation_only_v1',
    'oracle_runtime_scope', 'red_spells_cost_one_less_annotation_only_no_dynamic_executor_v1',
    'cost_reduction_status', 'annotation_only_no_dynamic_cost_executor',
    'dynamic_cost_executor', false
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'passive',
    'category', 'cost_reduction',
    'ramp_support', true,
    'spellslinger_support', true
  ),
  confidence = 0.970,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG071: replaced generic ramp_engine with passive red-spell cost-reduction metadata; cost reduction remains annotation-only because battle has no dynamic cost reducer executor.'
  )
WHERE normalized_name = 'ruby medallion'
  AND logical_rule_key = 'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG071: disabled superseded generated review-only row after scoped curated mana-support rule validation.'
  )
WHERE normalized_name IN ('lotus petal', 'ruby medallion')
  AND logical_rule_key IN (
    'battle_rule_v1:36148b392c7b1647bbd2950cd49b277e',
    'battle_rule_v1:601753de1461f2f66d16bb51bd3fb408'
  );

COMMIT;
