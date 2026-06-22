\pset pager off

SELECT
  'pg019_jin_gitaxias_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name = 'jin-gitaxias, core augur'
  AND logical_rule_key = 'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e';

SELECT
  'pg019_jin_gitaxias_snapshot_postcheck' AS check_name,
  name,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'jin-gitaxias, core augur';
