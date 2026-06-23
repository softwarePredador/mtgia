\pset pager off
\echo 'PG044 Valakut Awakening hash refresh rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
   or normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge');

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
from manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411;

commit;
