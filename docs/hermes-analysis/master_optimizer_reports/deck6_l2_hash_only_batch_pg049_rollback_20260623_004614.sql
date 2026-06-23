\pset pager off
\echo 'PG049 deck 6 L2 hash-only batch rollback'

begin;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614') is null then
    raise exception 'Backup table manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614 does not exist';
  end if;
end $$;

delete from card_battle_rules
where card_id in (
  'b6c3ff3b-e172-4e40-b9b3-b5eb2f5f0e7b',
  '648e2ae9-e079-4a62-9b45-8fae846c81cd',
  '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
)
or normalized_name in (
  'crawlspace',
  'ghostly prison',
  'valakut awakening // valakut stoneforge'
);

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
from manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614;

commit;
