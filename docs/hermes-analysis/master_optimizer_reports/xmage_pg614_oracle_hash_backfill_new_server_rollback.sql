begin;

update card_battle_rules cbr
set
  oracle_hash = b.oracle_hash,
  updated_at = b.updated_at
from manaloom_deploy_audit.pg614_oracle_hash_backfill_backup b
where cbr.normalized_name = b.normalized_name
  and cbr.logical_rule_key = b.logical_rule_key;

select count(*) as rolled_back_rows
from manaloom_deploy_audit.pg614_oracle_hash_backfill_backup;

commit;
