begin;

update card_battle_rules cbr
set
  oracle_hash = b.oracle_hash,
  updated_at = b.updated_at
from manaloom_deploy_audit.pg617b_trusted_oracle_hash_backfill_backup b
where cbr.card_id = b.card_id
  and cbr.normalized_name = b.normalized_name
  and cbr.logical_rule_key = b.logical_rule_key;

select count(*) as restored_rows
from manaloom_deploy_audit.pg617b_trusted_oracle_hash_backfill_backup;

commit;
