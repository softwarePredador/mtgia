\pset pager off
\echo 'PG046 Approach of the Second Sun battle-rule rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
   or normalized_name = 'approach of the second sun';

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
from manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039;

commit;
