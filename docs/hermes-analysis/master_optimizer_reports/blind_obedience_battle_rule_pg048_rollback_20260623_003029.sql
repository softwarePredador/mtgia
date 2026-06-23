\pset pager off
\echo 'PG048 Blind Obedience battle-rule rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id = '86112bb9-98f9-4615-8464-fbe770a5235f'
   or normalized_name = 'blind obedience';

insert into card_battle_rules (
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
)
select
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
from manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029;

commit;
