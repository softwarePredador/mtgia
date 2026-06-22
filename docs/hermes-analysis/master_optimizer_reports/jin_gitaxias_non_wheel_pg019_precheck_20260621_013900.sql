\pset pager off

SELECT
  'pg019_jin_gitaxias_precheck_rule' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'jin-gitaxias, core augur'
  AND logical_rule_key = 'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e';

SELECT
  'pg019_jin_gitaxias_precheck_card' AS check_name,
  c.id AS card_id,
  c.name,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash
FROM cards c
WHERE lower(c.name) = 'jin-gitaxias, core augur';
