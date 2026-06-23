\pset pager off
\echo 'PG045 Aetherflux Reservoir battle-rule rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id = '4c1b213e-a694-49f4-9882-e774950dac55'
   or normalized_name = 'aetherflux reservoir';

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
from manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656;

commit;
