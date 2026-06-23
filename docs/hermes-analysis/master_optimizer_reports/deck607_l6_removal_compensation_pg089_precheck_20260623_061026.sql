\pset pager off

BEGIN;

CREATE TEMP TABLE pg089_l6_removal_compensation_target AS
SELECT
  'Generous Gift'::text AS name,
  'generous gift'::text AS normalized_name,
  'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'::text AS promote_from_key,
  'battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c'::text AS expected_logical_rule_key,
  '9363edd299df8476da36798bd527cde1'::text AS expected_oracle_hash,
  'destroy_target_permanent_create_3_3_green_elephant_for_controller_v1'::text AS expected_scope,
  'permanent'::text AS expected_target,
  1::integer AS expected_creature_tokens
UNION ALL
SELECT
  'Stroke of Midnight',
  'stroke of midnight',
  'battle_rule_v1:9d5afecce0b2500c1dff74bcd97e6eb4',
  'battle_rule_v1:9b50d2f897b561c8c390c9e0e04da417',
  'a885e8190e19cf23b1f4c82563ca111b',
  'destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1',
  'nonland_permanent',
  1;

SELECT
  (SELECT count(*) FROM pg089_l6_removal_compensation_target) AS expected_target_rules,
  (SELECT count(*)
   FROM pg089_l6_removal_compensation_target t
   JOIN cards c ON lower(c.name) = t.normalized_name) AS cards_resolved_rows,
  (SELECT count(*)
   FROM pg089_l6_removal_compensation_target t
   JOIN cards c ON lower(c.name) = t.normalized_name
   WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash) AS raw_oracle_hash_match_rows,
  (SELECT count(*)
   FROM pg089_l6_removal_compensation_target t
   JOIN card_battle_rules r
     ON r.normalized_name = t.normalized_name
    AND r.logical_rule_key = t.promote_from_key) AS promotable_rows,
  (SELECT count(*)
   FROM card_battle_rules r
   JOIN pg089_l6_removal_compensation_target t
     ON r.normalized_name = t.normalized_name) AS current_rule_rows,
  (SELECT count(*)
   FROM card_battle_rules r
   JOIN pg089_l6_removal_compensation_target t
     ON r.normalized_name = t.normalized_name
    AND r.logical_rule_key <> t.promote_from_key
    AND (
      r.source = 'generated'
      OR r.review_status IN ('needs_review', 'review_only')
      OR r.execution_status = 'review_only'
    )) AS shadow_rows_to_disable,
  (SELECT count(*)
   FROM card_battle_rules r
   JOIN pg089_l6_removal_compensation_target t
     ON r.logical_rule_key = t.expected_logical_rule_key
    AND r.normalized_name <> t.normalized_name) AS new_key_conflict_rows,
  (to_regclass('manaloom_deploy_audit.pg089_deck607_l6_removal_compensation_20260623_061026') IS NOT NULL) AS backup_table_already_exists;

SELECT
  t.name,
  c.id AS card_id,
  c.type_line,
  c.oracle_text,
  md5(coalesce(c.oracle_text, '')) AS actual_oracle_hash,
  t.expected_oracle_hash
FROM pg089_l6_removal_compensation_target t
JOIN cards c ON lower(c.name) = t.normalized_name
ORDER BY t.name;

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
JOIN pg089_l6_removal_compensation_target t
  ON r.normalized_name = t.normalized_name
ORDER BY r.normalized_name, r.review_status, r.logical_rule_key;

ROLLBACK;
