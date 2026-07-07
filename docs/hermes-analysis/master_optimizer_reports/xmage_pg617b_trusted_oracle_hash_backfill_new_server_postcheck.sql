select
  count(*) as trusted_executable_rules_missing_oracle_hash
from card_battle_rules cbr
where cbr.execution_status = 'auto'
  and cbr.review_status in ('verified', 'active')
  and coalesce(cbr.oracle_hash, '') = '';

select
  count(*) as backed_up_rows,
  count(*) filter (where coalesce(cbr.oracle_hash, '') <> '') as rows_now_with_oracle_hash
from manaloom_deploy_audit.pg617b_trusted_oracle_hash_backfill_backup b
join card_battle_rules cbr
  on cbr.card_id = b.card_id
 and cbr.normalized_name = b.normalized_name
 and cbr.logical_rule_key = b.logical_rule_key;
