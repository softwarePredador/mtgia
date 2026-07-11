-- PG780B trusted oracle_hash backfill postcheck.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

WITH remaining AS (
  SELECT br.*
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source = 'curated'
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
),
backfilled AS (
  SELECT br.*
  FROM public.card_battle_rules br
  JOIN public.card_battle_rules_backup_pg780b_hash_new_server backup
    ON backup.normalized_name = br.normalized_name
   AND backup.logical_rule_key = br.logical_rule_key
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.oracle_hash = md5(c.oracle_text)
)
SELECT
  (SELECT COUNT(*) FROM public.card_battle_rules_backup_pg780b_hash_new_server) AS backup_rows,
  (SELECT COUNT(*) FROM backfilled) AS backfilled_rows,
  (SELECT COUNT(*) FROM remaining) AS remaining_target_rows;

SELECT
  br.card_name,
  br.logical_rule_key,
  br.oracle_hash,
  md5(c.oracle_text) AS expected_oracle_hash,
  br.oracle_hash = md5(c.oracle_text) AS hash_matches
FROM public.card_battle_rules br
JOIN public.card_battle_rules_backup_pg780b_hash_new_server backup
  ON backup.normalized_name = br.normalized_name
 AND backup.logical_rule_key = br.logical_rule_key
JOIN public.cards c ON c.id = br.card_id
ORDER BY br.card_name, br.logical_rule_key;
