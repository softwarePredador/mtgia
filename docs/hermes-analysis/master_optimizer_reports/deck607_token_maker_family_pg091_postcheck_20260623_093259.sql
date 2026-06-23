\pset pager off

CREATE TEMP TABLE pg091_deck607_token_maker_target AS
SELECT
  'Furygale Flocking'::text AS name,
  'furygale flocking'::text AS normalized_name,
  'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5'::text AS expected_logical_rule_key,
  '8946b0e85c8430c6105ea70c7fb2724a'::text AS expected_oracle_hash,
  'per_opponent_two_3_3_flying_hasty_elemental_tokens_v1'::text AS expected_scope
UNION ALL
SELECT
  'Prismari Pianist',
  'prismari pianist',
  'battle_rule_v1:0288989021534a6f036968f62361f634',
  '1594ae692e3095e544f3cd3430d43e86',
  'instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1'
UNION ALL
SELECT
  'Tempt with Bunnies',
  'tempt with bunnies',
  'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80',
  '201f6c7234bfef550f3d497e736f0d7a',
  'tempting_offer_base_draw_one_component_v1'
UNION ALL
SELECT
  'Tempt with Bunnies',
  'tempt with bunnies',
  'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
  '201f6c7234bfef550f3d497e736f0d7a',
  'tempting_offer_base_create_1_1_white_rabbit_component_v1';

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE r.oracle_hash = t.expected_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE r.oracle_hash IS NULL) AS target_missing_hash_rows,
  count(*) FILTER (WHERE r.effect_json->>'battle_model_scope' = t.expected_scope) AS target_expected_scope_rows,
  count(*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE r.rule_version >= 2) AS rule_version_at_least_2_rows,
  count(*) FILTER (WHERE r.effect_json ? 'token_colors') AS token_color_rows,
  count(*) FILTER (WHERE r.effect_json ? 'token_subtype') AS token_subtype_rows
FROM pg091_deck607_token_maker_target t
JOIN card_battle_rules r
  ON r.normalized_name = t.normalized_name
 AND r.logical_rule_key = t.expected_logical_rule_key;

SELECT
  count(*) FILTER (WHERE r.normalized_name = 'tempt with bunnies' AND r.effect_json->>'compose_on_resolution' = 'true') AS tempt_compose_rows,
  count(*) FILTER (WHERE r.normalized_name = 'furygale flocking' AND (r.effect_json->>'token_count_per_opponent')::int = 2) AS furygale_per_opponent_rows,
  count(*) FILTER (WHERE r.normalized_name = 'prismari pianist' AND (r.effect_json->>'trigger_token_count_if_spell_cmc_at_least')::int = 5) AS prismari_threshold_rows
FROM card_battle_rules r
JOIN pg091_deck607_token_maker_target t
  ON r.normalized_name = t.normalized_name
 AND r.logical_rule_key = t.expected_logical_rule_key;

SELECT
  count(*) AS non_disabled_shadow_rows
FROM card_battle_rules r
WHERE r.normalized_name IN (
    SELECT DISTINCT normalized_name FROM pg091_deck607_token_maker_target
  )
  AND r.logical_rule_key NOT IN (
    SELECT expected_logical_rule_key FROM pg091_deck607_token_maker_target
  )
  AND r.execution_status <> 'disabled';

SELECT
  count(*) AS disabled_shadow_rows
FROM card_battle_rules r
WHERE r.normalized_name IN (
    SELECT DISTINCT normalized_name FROM pg091_deck607_token_maker_target
  )
  AND r.logical_rule_key NOT IN (
    SELECT expected_logical_rule_key FROM pg091_deck607_token_maker_target
  )
  AND r.execution_status = 'disabled';

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259;

SELECT
  r.normalized_name,
  r.card_name,
  r.logical_rule_key,
  r.oracle_hash,
  r.effect_json,
  r.deck_role_json,
  r.review_status,
  r.execution_status,
  r.rule_version
FROM card_battle_rules r
WHERE r.normalized_name IN (
    SELECT DISTINCT normalized_name FROM pg091_deck607_token_maker_target
  )
ORDER BY r.normalized_name, r.execution_status, r.logical_rule_key;
