\pset pager off

CREATE TEMP TABLE pg069_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE c.name IN ('The One Ring', 'Unexpected Windfall');

CREATE TEMP TABLE pg069_target_rules AS
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
  cbr.deck_role_json
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE c.name IN ('The One Ring', 'Unexpected Windfall');

SELECT
  count(*) FILTER (
    WHERE (name = 'The One Ring' AND oracle_hash = '644d5305e6be932586a6d3b7325cadf7')
       OR (name = 'Unexpected Windfall' AND oracle_hash = '9c4fbe06104051a2e8b1d295d307b26a')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg069_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg069_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1',
      'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
    )
  ) AS target_specific_rule_rows,
  (
    SELECT count(*)
    FROM pg069_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1',
        'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM pg069_target_rules
    WHERE logical_rule_key IN (
        'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1',
        'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
      )
      AND (
        oracle_hash IS NULL
        OR oracle_hash NOT IN (
          '644d5305e6be932586a6d3b7325cadf7',
          '9c4fbe06104051a2e8b1d295d307b26a'
        )
      )
  ) AS target_specific_hash_defect_rows,
  to_regclass('manaloom_deploy_audit.pg069_deck6_l2_specific_runtime_cleanup_20260623_005736') IS NOT NULL AS backup_table_already_exists
FROM pg069_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg069_target_cards
ORDER BY name;

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
  deck_role_json
FROM pg069_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
