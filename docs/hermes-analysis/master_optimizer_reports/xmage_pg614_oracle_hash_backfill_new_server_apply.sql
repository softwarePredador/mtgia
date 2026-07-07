begin;

create schema if not exists manaloom_deploy_audit;

drop table if exists manaloom_deploy_audit.pg614_oracle_hash_backfill_backup;

create table manaloom_deploy_audit.pg614_oracle_hash_backfill_backup as
select
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.updated_at
from card_battle_rules cbr
join cards c on c.id = cbr.card_id
where cbr.execution_status = 'auto'
  and cbr.review_status in ('verified', 'active')
  and coalesce(cbr.oracle_hash, '') = ''
  and c.oracle_text is not null;

update card_battle_rules cbr
set
  oracle_hash = md5(coalesce(c.oracle_text, '')),
  updated_at = now()
from cards c
where c.id = cbr.card_id
  and cbr.execution_status = 'auto'
  and cbr.review_status in ('verified', 'active')
  and coalesce(cbr.oracle_hash, '') = ''
  and c.oracle_text is not null;

select count(*) as backed_up_rows
from manaloom_deploy_audit.pg614_oracle_hash_backfill_backup;

select count(*) as updated_missing_oracle_hash_rows
from manaloom_deploy_audit.pg614_oracle_hash_backfill_backup b
join card_battle_rules cbr
  on cbr.normalized_name = b.normalized_name
 and cbr.logical_rule_key = b.logical_rule_key
where coalesce(cbr.oracle_hash, '') <> '';

commit;
