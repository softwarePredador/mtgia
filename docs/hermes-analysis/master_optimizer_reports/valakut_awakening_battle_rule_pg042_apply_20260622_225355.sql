\pset pager off
\echo 'PG042 Valakut Awakening battle-rule apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg042_valakut_awakening_battle_rule_20260622_225355') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg042_valakut_awakening_battle_rule_20260622_225355 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg042_valakut_awakening_battle_rule_20260622_225355 as
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
    raise exception 'Valakut Awakening card/hash precondition failed: card_rows=%, hash_rows=%',
      expected_card_rows, expected_hash_rows;
  end if;
end $$;

update card_battle_rules
set
  review_status = 'active',
  execution_status = 'auto',
  oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887',
  reviewed_by = 'codex_pg042',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = 'PG042 oracle-hash activation: front face puts any number of cards from hand on bottom, then draws that many plus one; rulings confirm zero bottoms draws one and count is chosen on resolution. Runtime uses bottom_then_draw_plus_one_mdfc_land_v1; MDFC land-face metadata remains cache/runtime support from the existing curated split-name model.'
where normalized_name = 'valakut awakening // valakut stoneforge'
  and logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
  and card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd';

update card_battle_rules
set
  review_status = 'active',
  execution_status = 'auto',
  oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887',
  reviewed_by = 'codex_pg042',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = 'PG042 oracle-hash activation for front-face alias: Valakut Awakening puts any number of cards from hand on bottom, then draws that many plus one. Alias is retained for front-face lookups; split-name rule carries MDFC land-face metadata.'
where normalized_name = 'valakut awakening'
  and logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
  and card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg042',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG042 disabled: legacy curated Valakut hand-filter row lacks oracle_hash and battle_model_scope; superseded by oracle-hashed bottom_then_draw_plus_one rule.')
where card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
  and normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
  and logical_rule_key in (
    'battle_rule_v1:88dd44afe6b8d12389094384c46eb0d4',
    'battle_rule_v1:abc2aab4f282840b48f5cc1d23c71457'
  );

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg042',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG042 disabled: generated draw_cards shadow is less specific than the oracle-backed bottom-then-draw-plus-one hand_filter executor.')
where card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
  and normalized_name = 'valakut awakening // valakut stoneforge'
  and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549';

do $$
declare
  exact_full_count integer;
  exact_alias_count integer;
  legacy_enabled_count integer;
  trusted_missing_hash_count integer;
  review_only_shadow_count integer;
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

  select count(*) into legacy_enabled_count
  from card_battle_rules
  where normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
    and logical_rule_key in (
      'battle_rule_v1:88dd44afe6b8d12389094384c46eb0d4',
      'battle_rule_v1:abc2aab4f282840b48f5cc1d23c71457'
    )
    and review_status in ('active', 'verified')
    and execution_status = 'auto';

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  select count(*) into review_only_shadow_count
  from card_battle_rules
  where normalized_name = 'valakut awakening // valakut stoneforge'
    and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  if exact_full_count <> 1
     or exact_alias_count <> 1
     or legacy_enabled_count <> 0
     or trusted_missing_hash_count <> 0
     or review_only_shadow_count <> 0 then
    raise exception 'PG042 postcondition failed: full=%, alias=%, legacy=%, missing_hash=%, review_shadow=%',
      exact_full_count, exact_alias_count, legacy_enabled_count, trusted_missing_hash_count, review_only_shadow_count;
  end if;
end $$;

commit;
