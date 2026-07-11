-- PG783B trusted rule oracle_hash backfill postcheck.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

WITH remaining AS (
  SELECT br.*
  FROM public.card_battle_rules br
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
backfilled AS (
  SELECT br.*
  FROM public.card_battle_rules br
  JOIN manaloom_deploy_audit.pg783b_trusted_rule_oracle_hash_backfill_new_server_20260711 backup
    ON backup.normalized_name = br.normalized_name
   AND backup.logical_rule_key = br.logical_rule_key
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.oracle_hash = md5(c.oracle_text)
)
SELECT
  (SELECT COUNT(*) FROM manaloom_deploy_audit.pg783b_trusted_rule_oracle_hash_backfill_new_server_20260711) AS backup_rows,
  (SELECT COUNT(*) FROM backfilled) AS backfilled_rows,
  (SELECT COUNT(*) FROM remaining) AS trusted_executable_rules_missing_oracle_hash;

SELECT
  br.card_name,
  br.logical_rule_key,
  br.source,
  br.review_status,
  br.execution_status,
  br.oracle_hash,
  md5(c.oracle_text) AS expected_oracle_hash,
  br.oracle_hash = md5(c.oracle_text) AS hash_matches
FROM public.card_battle_rules br
JOIN manaloom_deploy_audit.pg783b_trusted_rule_oracle_hash_backfill_new_server_20260711 backup
  ON backup.normalized_name = br.normalized_name
 AND backup.logical_rule_key = br.logical_rule_key
JOIN public.cards c ON c.id = br.card_id
ORDER BY br.card_name, br.logical_rule_key;
