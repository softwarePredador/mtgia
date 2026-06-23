\pset pager off
\echo 'PG047 Archaeomancer''s Map battle-rule rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
   or normalized_name = 'archaeomancer''s map';

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
from manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244;

commit;
