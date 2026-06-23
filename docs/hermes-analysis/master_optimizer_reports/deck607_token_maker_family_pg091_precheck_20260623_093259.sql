\pset pager off

BEGIN;

CREATE TEMP TABLE pg091_deck607_token_maker_target AS
SELECT
  'Furygale Flocking'::text AS name,
  'furygale flocking'::text AS normalized_name,
  'battle_rule_v1:8efd14e0d2f631b8e9f0205cf6030f39'::text AS promote_from_key,
  'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5'::text AS expected_logical_rule_key,
  '8946b0e85c8430c6105ea70c7fb2724a'::text AS expected_oracle_hash,
  'per_opponent_two_3_3_flying_hasty_elemental_tokens_v1'::text AS expected_scope
UNION ALL
SELECT
  'Prismari Pianist',
  'prismari pianist',
  'battle_rule_v1:8efd14e0d2f631b8e9f0205cf6030f39',
  'battle_rule_v1:0288989021534a6f036968f62361f634',
  '1594ae692e3095e544f3cd3430d43e86',
  'instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1'
UNION ALL
SELECT
  'Tempt with Bunnies',
  'tempt with bunnies',
  'battle_rule_v1:030b2f3e0f549a462c3c8ea429877980',
  'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80',
  '201f6c7234bfef550f3d497e736f0d7a',
  'tempting_offer_base_draw_one_component_v1'
UNION ALL
SELECT
  'Tempt with Bunnies',
  'tempt with bunnies',
  'battle_rule_v1:adf4845203520f2f668e196538e532f2',
  'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
  '201f6c7234bfef550f3d497e736f0d7a',
  'tempting_offer_base_create_1_1_white_rabbit_component_v1';

SELECT
  (SELECT count(*) FROM pg091_deck607_token_maker_target) AS expected_target_rules,
  (SELECT count(DISTINCT c.id)
   FROM pg091_deck607_token_maker_target t
   JOIN cards c ON lower(c.name) = t.normalized_name) AS cards_resolved_rows,
  (SELECT count(*)
   FROM pg091_deck607_token_maker_target t
   JOIN cards c ON lower(c.name) = t.normalized_name
   WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash) AS raw_oracle_hash_match_rows,
  (SELECT count(*)
   FROM pg091_deck607_token_maker_target t
   JOIN card_battle_rules r
     ON r.normalized_name = t.normalized_name
    AND r.logical_rule_key = t.promote_from_key) AS promotable_rows,
  (SELECT count(*)
   FROM card_battle_rules r
   JOIN pg091_deck607_token_maker_target t
     ON r.normalized_name = t.normalized_name) AS current_rule_rows,
  (SELECT count(*)
   FROM card_battle_rules r
   JOIN pg091_deck607_token_maker_target t
     ON r.normalized_name = t.normalized_name
    AND r.logical_rule_key <> t.promote_from_key
    AND (
      r.source = 'generated'
      OR r.review_status IN ('needs_review', 'review_only')
      OR r.execution_status = 'review_only'
    )) AS shadow_rows_to_disable,
  (SELECT count(*)
   FROM card_battle_rules r
   JOIN pg091_deck607_token_maker_target t
     ON r.logical_rule_key = t.expected_logical_rule_key
    AND r.normalized_name <> t.normalized_name) AS new_key_conflict_rows,
  (to_regclass('manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259') IS NOT NULL) AS backup_table_already_exists;

SELECT
  t.name,
  c.id AS card_id,
  c.type_line,
  c.mana_cost,
  c.oracle_text,
  md5(coalesce(c.oracle_text, '')) AS actual_oracle_hash,
  t.expected_oracle_hash,
  t.expected_scope
FROM pg091_deck607_token_maker_target t
JOIN cards c ON lower(c.name) = t.normalized_name
ORDER BY t.name, t.expected_logical_rule_key;

SELECT
  r.normalized_name,
  r.card_name,
  r.logical_rule_key,
  r.effect_json,
  r.deck_role_json,
  r.source,
  r.review_status,
  r.execution_status,
  r.oracle_hash
FROM card_battle_rules r
JOIN pg091_deck607_token_maker_target t
  ON r.normalized_name = t.normalized_name
ORDER BY r.normalized_name, r.review_status, r.logical_rule_key;

ROLLBACK;
