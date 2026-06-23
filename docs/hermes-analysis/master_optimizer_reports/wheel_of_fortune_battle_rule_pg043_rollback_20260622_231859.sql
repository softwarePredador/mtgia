\pset pager off
\echo 'PG043 Wheel of Fortune battle-rule rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
   or normalized_name = 'wheel of fortune';

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
from manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859;

commit;
