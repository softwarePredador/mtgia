\pset pager off
\echo 'PG044 Valakut Awakening hash refresh apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411 as
select *
from card_battle_rules
where card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
   or normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge');

do $$
declare
  expected_card_rows integer;
  expected_hash_rows integer;
begin
  select count(*) into expected_card_rows
  from cards
  where id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd';

  select count(*) into expected_hash_rows
  from cards
  where id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
    and md5(coalesce(oracle_text, '')) = '22b42fcc181b7aed71f78b2e1e51e887'
    and oracle_text = 'Put any number of cards from your hand on the bottom of your library, then draw that many cards plus one.';

  if expected_card_rows <> 1 or expected_hash_rows <> 1 then
    raise exception 'Valakut Awakening hash refresh precondition failed: card_rows=%, hash_rows=%',
      expected_card_rows, expected_hash_rows;
  end if;
end $$;

update card_battle_rules
set
  review_status = 'active',
  execution_status = 'auto',
  oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887',
  reviewed_by = 'codex_pg044',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = 'PG044 hash refresh: front face puts any number of cards from hand on bottom, then draws that many plus one. Runtime uses bottom_then_draw_plus_one_mdfc_land_v1; MDFC land face remains metadata, not a separate land-play executor.'
where normalized_name = 'valakut awakening // valakut stoneforge'
  and logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
  and card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd';

update card_battle_rules
set
  review_status = 'active',
  execution_status = 'auto',
  oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887',
  reviewed_by = 'codex_pg044',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = 'PG044 hash refresh for front-face alias: Valakut Awakening puts any number of cards from hand on bottom, then draws that many plus one.'
where normalized_name = 'valakut awakening'
  and logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
  and card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg044',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG044 disabled: generated draw_cards shadow remains less specific than the oracle-backed bottom-then-draw-plus-one hand_filter executor.')
where normalized_name = 'valakut awakening // valakut stoneforge'
  and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549';

do $$
declare
  exact_full_count integer;
  exact_alias_count integer;
  generated_review_rows integer;
  trusted_missing_hash_count integer;
begin
  select count(*) into exact_full_count
  from card_battle_rules
  where normalized_name = 'valakut awakening // valakut stoneforge'
    and logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887';

  select count(*) into exact_alias_count
  from card_battle_rules
  where normalized_name = 'valakut awakening'
    and logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887';

  select count(*) into generated_review_rows
  from card_battle_rules
  where normalized_name = 'valakut awakening // valakut stoneforge'
    and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if exact_full_count <> 1
     or exact_alias_count <> 1
     or generated_review_rows <> 0
     or trusted_missing_hash_count <> 0 then
    raise exception 'PG044 postcondition failed: full=%, alias=%, generated_review=%, missing_hash=%',
      exact_full_count, exact_alias_count, generated_review_rows, trusted_missing_hash_count;
  end if;
end $$;

commit;
