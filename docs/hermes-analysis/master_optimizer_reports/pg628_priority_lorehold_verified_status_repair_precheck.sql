-- PG628 precheck: priority Lorehold verified-status repair.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
),
requested_cards(name) AS (
  VALUES
    ('Fellwar Stone'),
    ('Library of Leng'),
    ('Scroll Rack'),
    ('Talisman of Conviction')
)
SELECT
  'target_rows' AS check_name,
  COUNT(*)::text AS value
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)

UNION ALL

SELECT
  'target_active_auto_rows',
  COUNT(*)::text
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE cbr.review_status = 'active'
  AND cbr.execution_status = 'auto'

UNION ALL

SELECT
  'target_verified_auto_rows',
  COUNT(*)::text
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE cbr.review_status = 'verified'
  AND cbr.execution_status = 'auto'

UNION ALL

SELECT
  'target_missing_oracle_hash',
  COUNT(*)::text
FROM card_battle_rules cbr
JOIN target_rules t USING (normalized_name, logical_rule_key)
WHERE COALESCE(cbr.oracle_hash, '') = ''

UNION ALL

SELECT
  'requested_cards_snapshot_verified_before',
  COUNT(*)::text || '/' || (SELECT COUNT(*) FROM requested_cards)::text
FROM requested_cards r
JOIN cards c ON lower(c.name) = lower(r.name)
JOIN card_intelligence_snapshot cis ON cis.card_id = c.id
WHERE COALESCE(cis.verified_battle_rule_count, 0) > 0;
