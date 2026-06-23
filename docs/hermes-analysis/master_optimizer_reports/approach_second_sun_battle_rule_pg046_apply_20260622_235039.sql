\pset pager off
\echo 'PG046 Approach of the Second Sun battle-rule apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039 as
select *
from card_battle_rules
where card_id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
   or normalized_name = 'approach of the second sun';

do $$
declare
  expected_card_rows integer;
  expected_hash_rows integer;
begin
  select count(*) into expected_card_rows
  from cards
  where id = '3730958e-18ee-4dde-bd62-46a18b24bf11';

  select count(*) into expected_hash_rows
  from cards
  where id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
    and md5(coalesce(oracle_text, '')) = '0838960b80a282fb4508532f7bae8c2b'
    and oracle_text = 'If this spell was cast from your hand and you''ve cast another spell named Approach of the Second Sun this game, you win the game. Otherwise, put Approach of the Second Sun into its owner''s library seventh from the top and you gain 7 life.';

  if expected_card_rows <> 1 or expected_hash_rows <> 1 then
    raise exception 'Approach of the Second Sun card/hash precondition failed: card_rows=%, hash_rows=%',
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
  'approach of the second sun',
  'battle_rule_v1:ed74fb069b6c1d635392d907804a1d98',
  '3730958e-18ee-4dde-bd62-46a18b24bf11',
  'Approach of the Second Sun',
  '{"cmc":7.0,"effect":"approach","gain_life":7,"first_resolution_library_position":7,"second_cast_wins_game":true,"second_cast_requires_cast_from_hand":true,"countered_first_cast_counts":true,"copy_spell_does_not_count":true,"battle_model_scope":"approach_second_cast_win_v2"}'::jsonb,
  '{"category":"wincon","effect":"approach","timing":"main_phase"}'::jsonb,
  'curated',
  0.990,
  'active',
  'auto',
  1,
  '0838960b80a282fb4508532f7bae8c2b',
  'PG046 oracle-hash activation: Approach of the Second Sun uses the second-cast win model with cast-from-hand tracking. Runtime now counts a countered first cast, excludes copied spells from the cast ledger, gains 7 life only on the first-resolution otherwise branch, and does not gain life on the second-cast win branch.',
  'codex_pg046',
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
  reviewed_by = 'codex_pg046',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG046 disabled: legacy Approach rule lacked oracle_hash and battle_model_scope, and did not encode the second-cast win/countered-first-cast semantics.')
where normalized_name = 'approach of the second sun'
  and logical_rule_key = 'battle_rule_v1:c9594094630e58aa220dd4e82309f597';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg046',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG046 disabled: old reviewed Approach row lacked oracle_hash and is superseded by approach_second_cast_win_v2 with countered-first-cast tracking.')
where normalized_name = 'approach of the second sun'
  and logical_rule_key = 'battle_rule_v1:d89b90f224cfa72e048c8adef2f80185';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg046',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG046 disabled: generated Approach shadow is superseded by the oracle-backed approach_second_cast_win_v2 rule.')
where normalized_name = 'approach of the second sun'
  and logical_rule_key = 'battle_rule_v1:6e281d363c92040c064cda01b445b596';

do $$
declare
  exact_count integer;
  legacy_enabled_count integer;
  generated_review_only_count integer;
  trusted_missing_hash_count integer;
begin
  select count(*) into exact_count
  from card_battle_rules
  where normalized_name = 'approach of the second sun'
    and logical_rule_key = 'battle_rule_v1:ed74fb069b6c1d635392d907804a1d98'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = '0838960b80a282fb4508532f7bae8c2b'
    and effect_json->>'effect' = 'approach'
    and effect_json->>'battle_model_scope' = 'approach_second_cast_win_v2'
    and effect_json->>'countered_first_cast_counts' = 'true'
    and effect_json->>'copy_spell_does_not_count' = 'true';

  select count(*) into legacy_enabled_count
  from card_battle_rules
  where normalized_name = 'approach of the second sun'
    and logical_rule_key in (
      'battle_rule_v1:c9594094630e58aa220dd4e82309f597',
      'battle_rule_v1:d89b90f224cfa72e048c8adef2f80185',
      'battle_rule_v1:6e281d363c92040c064cda01b445b596'
    )
    and review_status in ('active', 'verified')
    and execution_status = 'auto';

  select count(*) into generated_review_only_count
  from card_battle_rules
  where normalized_name = 'approach of the second sun'
    and logical_rule_key = 'battle_rule_v1:6e281d363c92040c064cda01b445b596'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name = 'approach of the second sun'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if exact_count <> 1
     or legacy_enabled_count <> 0
     or generated_review_only_count <> 0
     or trusted_missing_hash_count <> 0 then
    raise exception 'PG046 postcondition failed: exact=%, legacy=%, generated_review=%, missing_hash=%',
      exact_count, legacy_enabled_count, generated_review_only_count, trusted_missing_hash_count;
  end if;
end $$;

commit;
