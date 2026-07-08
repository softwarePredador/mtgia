\echo 'PG661 trusted rule oracle_hash backfill postcheck'

SELECT COUNT(*) AS trusted_executable_rules_missing_oracle_hash
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('curated', 'manual')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND COALESCE(c.oracle_text, '') <> '';

SELECT COUNT(*) AS backup_rows
FROM manaloom_deploy_audit.pg661_trusted_rule_oracle_hash_backfill_new_server_20260708;

SELECT COUNT(*) AS pg661_annotated_rows
FROM public.card_battle_rules
WHERE notes LIKE '%PG661 2026-07-08: metadata-only oracle_hash backfill%';
