\pset pager off
\echo 'PG047 Archaeomancer''s Map battle-rule apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244 as
select *
from card_battle_rules
where card_id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
   or normalized_name = 'archaeomancer''s map';

do $$
declare
  expected_card_rows integer;
  expected_hash_rows integer;
begin
  select count(*) into expected_card_rows
  from cards
  where id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1';

  select count(*) into expected_hash_rows
  from cards
  where id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
    and md5(coalesce(oracle_text, '')) = '22b82ca6bbef42371227bc38a9a546b5'
    and oracle_text = E'When this artifact enters, search your library for up to two basic Plains cards, reveal them, put them into your hand, then shuffle.\nWhenever a land an opponent controls enters, if that player controls more lands than you, you may put a land card from your hand onto the battlefield.';

  if expected_card_rows <> 1 or expected_hash_rows <> 1 then
    raise exception 'Archaeomancer''s Map card/hash precondition failed: card_rows=%, hash_rows=%',
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
  'archaeomancer''s map',
  'battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e',
  '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1',
  'Archaeomancer''s Map',
  '{"cmc":3.0,"effect":"ramp_engine","trigger":"opponent_land_play","etb_tutor_target":"basic_plains","etb_tutor_count":2,"may_put_land_from_hand":true,"trigger_condition":"opponent_controls_more_lands_than_you","trigger_rechecks_on_resolution":true,"battle_model_scope":"basic_plains_etb_plus_opponent_land_catchup_v2"}'::jsonb,
  '{"category":"ramp","effect":"ramp_engine","subtype":"plains_tutor_land_catchup_artifact"}'::jsonb,
  'curated',
  0.930,
  'active',
  'auto',
  1,
  '22b82ca6bbef42371227bc38a9a546b5',
  'PG047 oracle-backed activation: Archaeomancer''s Map searches up to two basic Plains to hand on ETB and only uses the opponent-land catch-up trigger when that opponent controls more lands than the Map controller, with a recheck on resolution.',
  'codex_pg047',
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
  reviewed_by = 'codex_pg047',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG047 disabled: v1 Map row lacked oracle_hash and did not encode the opponent-controls-more-lands trigger condition/recheck now enforced by v2.')
where normalized_name = 'archaeomancer''s map'
  and logical_rule_key = 'battle_rule_v1:a2cbd7e64ee611d7284e4aa326e06d36';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg047',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG047 disabled: generated tutor:any shadow is superseded by the oracle-backed basic_plains_etb_plus_opponent_land_catchup_v2 rule.')
where normalized_name = 'archaeomancer''s map'
  and logical_rule_key in (
    'battle_rule_v1:d8dfc058ea5870cde290c3d57dc34849',
    'battle_rule_v1:f1fec28b4adc813d6a8a0a5722c288cd'
  );

do $$
declare
  exact_count integer;
  legacy_enabled_count integer;
  generated_review_only_count integer;
  trusted_missing_hash_count integer;
begin
  select count(*) into exact_count
  from card_battle_rules
  where normalized_name = 'archaeomancer''s map'
    and logical_rule_key = 'battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = '22b82ca6bbef42371227bc38a9a546b5'
    and effect_json->>'effect' = 'ramp_engine'
    and effect_json->>'battle_model_scope' = 'basic_plains_etb_plus_opponent_land_catchup_v2'
    and effect_json->>'etb_tutor_target' = 'basic_plains'
    and effect_json->>'trigger_condition' = 'opponent_controls_more_lands_than_you'
    and effect_json->>'trigger_rechecks_on_resolution' = 'true';

  select count(*) into legacy_enabled_count
  from card_battle_rules
  where normalized_name = 'archaeomancer''s map'
    and logical_rule_key in (
      'battle_rule_v1:a2cbd7e64ee611d7284e4aa326e06d36',
      'battle_rule_v1:d8dfc058ea5870cde290c3d57dc34849',
      'battle_rule_v1:f1fec28b4adc813d6a8a0a5722c288cd'
    )
    and review_status in ('active', 'verified')
    and execution_status = 'auto';

  select count(*) into generated_review_only_count
  from card_battle_rules
  where normalized_name = 'archaeomancer''s map'
    and logical_rule_key in (
      'battle_rule_v1:d8dfc058ea5870cde290c3d57dc34849',
      'battle_rule_v1:f1fec28b4adc813d6a8a0a5722c288cd'
    )
    and (review_status = 'needs_review' or execution_status = 'review_only');

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name = 'archaeomancer''s map'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if exact_count <> 1
     or legacy_enabled_count <> 0
     or generated_review_only_count <> 0
     or trusted_missing_hash_count <> 0 then
    raise exception 'PG047 postcondition failed: exact=%, legacy=%, generated_review=%, missing_hash=%',
      exact_count, legacy_enabled_count, generated_review_only_count, trusted_missing_hash_count;
  end if;
end $$;

commit;
