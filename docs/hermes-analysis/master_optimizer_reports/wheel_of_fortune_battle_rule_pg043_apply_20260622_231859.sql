\pset pager off
\echo 'PG043 Wheel of Fortune battle-rule apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859 as
select *
from card_battle_rules
where card_id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
   or normalized_name = 'wheel of fortune';

do $$
declare
  expected_card_rows integer;
  expected_hash_rows integer;
begin
  select count(*) into expected_card_rows
  from cards
  where id = '534bdccc-25ac-4776-a986-4a8e943cbaa4';

  select count(*) into expected_hash_rows
  from cards
  where id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
    and md5(coalesce(oracle_text, '')) = 'c37cd579d8132efac0c2118608f6f001'
    and oracle_text = 'Each player discards their hand, then draws seven cards.';

  if expected_card_rows <> 1 or expected_hash_rows <> 1 then
    raise exception 'Wheel of Fortune card/hash precondition failed: card_rows=%, hash_rows=%',
      expected_card_rows, expected_hash_rows;
  end if;
end $$;

insert into card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
) values (
  'wheel of fortune',
  'battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3',
  '534bdccc-25ac-4776-a986-4a8e943cbaa4',
  'Wheel of Fortune',
  '{"cmc":3.0,"count":7,"effect":"draw_cards","sorcery":true,"wheel_like":true,"discard_hand_each_player":true,"battle_model_scope":"multiplayer_discard_draw_v1"}'::jsonb,
  '{"category":"draw","effect":"draw_cards","subtype":"wheel","scope":"each_player_discard_hand_draw_seven","timing":"sorcery"}'::jsonb,
  'curated',
  0.950,
  'active',
  'auto',
  1,
  'c37cd579d8132efac0c2118608f6f001',
  'PG043 oracle-hash activation: Wheel of Fortune is a multiplayer wheel, each player discards their hand then draws seven. Runtime uses multiplayer_discard_draw_v1 and emits wheel_resolved provenance for this logical rule.',
  'codex_pg043',
  now(),
  now(),
  now(),
  now()
)
on conflict (normalized_name, logical_rule_key) do update set
  card_id = excluded.card_id,
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  execution_status = excluded.execution_status,
  rule_version = excluded.rule_version,
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at;

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg043',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG043 disabled: legacy curated Wheel of Fortune row lacked oracle_hash and battle_model_scope, and encoded the card as generic draw seven instead of multiplayer discard-hand wheel.')
where normalized_name = 'wheel of fortune'
  and logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg043',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG043 disabled: generated Wheel of Fortune shadow is superseded by the oracle-backed multiplayer_discard_draw_v1 rule.')
where normalized_name = 'wheel of fortune'
  and logical_rule_key = 'battle_rule_v1:3bd7f7866ce30619d4d92b4e9e7b520e';

do $$
declare
  exact_count integer;
  legacy_enabled_count integer;
  generated_review_only_count integer;
  generic_without_scope_count integer;
  trusted_missing_hash_count integer;
begin
  select count(*) into exact_count
  from card_battle_rules
  where normalized_name = 'wheel of fortune'
    and logical_rule_key = 'battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = 'c37cd579d8132efac0c2118608f6f001'
    and effect_json->>'battle_model_scope' = 'multiplayer_discard_draw_v1'
    and effect_json->>'wheel_like' = 'true';

  select count(*) into legacy_enabled_count
  from card_battle_rules
  where normalized_name = 'wheel of fortune'
    and logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd'
    and review_status in ('active', 'verified')
    and execution_status = 'auto';

  select count(*) into generated_review_only_count
  from card_battle_rules
  where normalized_name = 'wheel of fortune'
    and logical_rule_key = 'battle_rule_v1:3bd7f7866ce30619d4d92b4e9e7b520e'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  select count(*) into generic_without_scope_count
  from card_battle_rules
  where normalized_name = 'wheel of fortune'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and effect_json->>'effect' = 'draw_cards'
    and nullif(effect_json->>'battle_model_scope', '') is null;

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name = 'wheel of fortune'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if exact_count <> 1
     or legacy_enabled_count <> 0
     or generated_review_only_count <> 0
     or generic_without_scope_count <> 0
     or trusted_missing_hash_count <> 0 then
    raise exception 'PG043 postcondition failed: exact=%, legacy=%, generated_review=%, generic_without_scope=%, missing_hash=%',
      exact_count, legacy_enabled_count, generated_review_only_count, generic_without_scope_count, trusted_missing_hash_count;
  end if;
end $$;

commit;
