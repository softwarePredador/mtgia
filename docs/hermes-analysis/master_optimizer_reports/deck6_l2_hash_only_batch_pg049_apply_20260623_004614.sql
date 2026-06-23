\pset pager off
\echo 'PG049 deck 6 L2 hash-only batch apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614 as
select *
from card_battle_rules
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

do $$
declare
  card_rows integer;
  hash_rows integer;
  missing_hash_rows integer;
begin
  with expected(card_name, card_id, expected_hash) as (
    values
      ('Crawlspace', 'b6c3ff3b-e172-4e40-b9b3-b5eb2f5f0e7b'::uuid, '57fcd38030641ceb36bbcf1a6dcbc6c8'),
      ('Ghostly Prison', '648e2ae9-e079-4a62-9b45-8fae846c81cd'::uuid, '5725b39ca4bb7c5e8e4bebf0d246be13'),
      ('Valakut Awakening // Valakut Stoneforge', '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'::uuid, '22b42fcc181b7aed71f78b2e1e51e887')
  )
  select
    count(*) filter (where c.id = e.card_id and c.name = e.card_name),
    count(*) filter (
      where c.id = e.card_id
        and c.name = e.card_name
        and md5(coalesce(c.oracle_text, '')) = e.expected_hash
    )
  into card_rows, hash_rows
  from expected e
  left join cards c on c.id = e.card_id;

  select count(*) into missing_hash_rows
  from card_battle_rules
  where logical_rule_key in (
    'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591',
    'battle_rule_v1:99151859bece89ba3ead032e05b1f65a',
    'battle_rule_v1:245b8d2627720fadfd7a30464d07605a',
    'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
  )
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if card_rows <> 3 or hash_rows <> 3 or missing_hash_rows <> 4 then
    raise exception 'PG049 precondition failed: card_rows=%, hash_rows=%, missing_hash_rows=%',
      card_rows, hash_rows, missing_hash_rows;
  end if;
end $$;

with updates(logical_rule_key, oracle_hash) as (
  values
    ('battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591', '57fcd38030641ceb36bbcf1a6dcbc6c8'),
    ('battle_rule_v1:99151859bece89ba3ead032e05b1f65a', '5725b39ca4bb7c5e8e4bebf0d246be13'),
    ('battle_rule_v1:245b8d2627720fadfd7a30464d07605a', '22b42fcc181b7aed71f78b2e1e51e887'),
    ('battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887')
)
update card_battle_rules cbr
set
  oracle_hash = updates.oracle_hash,
  reviewed_by = 'codex_pg049',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(cbr.notes, ''), 'PG049 deck6 L2 hash-only batch: oracle_hash set from current PostgreSQL cards.oracle_text; no executor or effect_json change.')
from updates
where cbr.logical_rule_key = updates.logical_rule_key
  and cbr.review_status in ('active', 'verified')
  and cbr.execution_status = 'auto';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg049',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG049 deck6 L2 cleanup: generated draw_cards shadow is superseded by oracle-hashed Valakut hand_filter rules.')
where normalized_name = 'valakut awakening // valakut stoneforge'
  and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
  and source = 'generated'
  and execution_status = 'disabled';

do $$
declare
  hashed_target_rows integer;
  missing_hash_rows integer;
  valakut_shadow_rows integer;
begin
  select count(*) into hashed_target_rows
  from card_battle_rules
  where (
    logical_rule_key = 'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591'
    and oracle_hash = '57fcd38030641ceb36bbcf1a6dcbc6c8'
    and effect_json->>'effect' = 'attack_limit'
  ) or (
    logical_rule_key = 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'
    and oracle_hash = '5725b39ca4bb7c5e8e4bebf0d246be13'
    and effect_json->>'effect' = 'attack_tax'
  ) or (
    logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
    and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
    and effect_json->>'battle_model_scope' = 'bottom_then_draw_plus_one_v1'
  ) or (
    logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
    and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
    and effect_json->>'battle_model_scope' = 'bottom_then_draw_plus_one_mdfc_land_v1'
  );

  select count(*) into missing_hash_rows
  from card_battle_rules
  where logical_rule_key in (
    'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591',
    'battle_rule_v1:99151859bece89ba3ead032e05b1f65a',
    'battle_rule_v1:245b8d2627720fadfd7a30464d07605a',
    'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
  )
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  select count(*) into valakut_shadow_rows
  from card_battle_rules
  where normalized_name = 'valakut awakening // valakut stoneforge'
    and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  if hashed_target_rows <> 4 or missing_hash_rows <> 0 or valakut_shadow_rows <> 0 then
    raise exception 'PG049 postcondition failed: hashed_target_rows=%, missing_hash_rows=%, valakut_shadow_rows=%',
      hashed_target_rows, missing_hash_rows, valakut_shadow_rows;
  end if;
end $$;

commit;
