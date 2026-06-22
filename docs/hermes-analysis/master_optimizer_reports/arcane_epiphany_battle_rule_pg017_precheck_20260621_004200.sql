\pset pager off

SELECT
  'pg017_arcane_epiphany_precheck_card' AS check_name,
  c.id AS card_id,
  c.name,
  c.mana_cost,
  c.cmc,
  c.type_line,
  c.color_identity,
  c.oracle_text,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash
FROM cards c
WHERE lower(c.name) = 'arcane epiphany';

SELECT
  'pg017_arcane_epiphany_precheck_rules' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) = 'arcane epiphany'
ORDER BY source, review_status, execution_status, logical_rule_key;
