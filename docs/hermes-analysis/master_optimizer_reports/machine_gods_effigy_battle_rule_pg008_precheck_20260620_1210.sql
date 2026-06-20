\set ON_ERROR_STOP on

BEGIN READ ONLY;

SELECT 'pg008_target_card' AS check_name, count(*) AS row_count
FROM cards
WHERE id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid
  AND lower(name) = 'machine god''s effigy';

SELECT 'pg008_existing_target_rule' AS check_name, count(*) AS row_count
FROM card_battle_rules
WHERE normalized_name = 'machine god''s effigy'
  AND logical_rule_key = 'battle_rule_v1:c07949dca69471872a2d2b70c527b5f8';

SELECT 'pg008_existing_any_machine_gods_effigy_rule' AS check_name,
       count(*) AS row_count
FROM card_battle_rules
WHERE normalized_name = 'machine god''s effigy'
   OR lower(card_name) = 'machine god''s effigy';

SELECT 'pg008_snapshot_before' AS check_name,
       id,
       card_id,
       name,
       battle_rule_count,
       verified_battle_rule_count,
       battle_rules::text AS battle_rules,
       function_tags::text AS function_tags,
       function_tag_details::text AS function_tag_details,
       source_coverage::text AS source_coverage
FROM card_intelligence_snapshot
WHERE card_id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid
   OR lower(name) = 'machine god''s effigy'
ORDER BY name, card_id;

SELECT 'pg008_target_card_detail' AS check_name,
       id,
       name,
       type_line,
       oracle_id,
       left(coalesce(oracle_text, ''), 320) AS oracle_text_prefix
FROM cards
WHERE id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid
  AND lower(name) = 'machine god''s effigy';

SELECT 'pg008_function_tags_before' AS check_name,
       c.id,
       c.name,
       ft.tag,
       ft.confidence,
       ft.source,
       ft.evidence
FROM cards c
JOIN card_function_tags ft ON ft.card_id = c.id
WHERE c.id = '1f48fdfb-983c-429b-a777-df0ce2b1d8f0'::uuid
ORDER BY ft.tag, ft.source;

ROLLBACK;
