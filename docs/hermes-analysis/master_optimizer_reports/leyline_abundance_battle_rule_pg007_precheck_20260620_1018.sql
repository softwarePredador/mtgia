\set ON_ERROR_STOP on

BEGIN READ ONLY;

SELECT 'pg007_target_card' AS check_name, count(*) AS row_count
FROM cards
WHERE id = 'd524183f-6430-411b-8a9b-48eda6cb0f7d'::uuid
  AND lower(name) = 'leyline of abundance';

SELECT 'pg007_existing_target_rule' AS check_name, count(*) AS row_count
FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941';

SELECT 'pg007_existing_any_leyline_rule' AS check_name, count(*) AS row_count
FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
   OR lower(card_name) = 'leyline of abundance';

SELECT 'pg007_snapshot_before' AS check_name,
       id,
       card_id,
       name,
       battle_rules::text AS battle_rules,
       function_tags::text AS function_tags
FROM card_intelligence_snapshot
WHERE card_id = 'd524183f-6430-411b-8a9b-48eda6cb0f7d'::uuid
   OR lower(name) = 'leyline of abundance'
ORDER BY name, card_id;

SELECT 'pg007_target_card_detail' AS check_name,
       id,
       name,
       type_line,
       oracle_id,
       left(coalesce(oracle_text, ''), 240) AS oracle_text_prefix
FROM cards
WHERE id = 'd524183f-6430-411b-8a9b-48eda6cb0f7d'::uuid
  AND lower(name) = 'leyline of abundance';

ROLLBACK;
