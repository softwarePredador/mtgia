\pset pager off
\echo 'PG048 Blind Obedience battle-rule apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029 as
select *
from card_battle_rules
where card_id = '86112bb9-98f9-4615-8464-fbe770a5235f'
   or normalized_name = 'blind obedience';

do $$
declare
  expected_card_rows integer;
  expected_hash_rows integer;
begin
  select count(*) into expected_card_rows
  from cards
  where id = '86112bb9-98f9-4615-8464-fbe770a5235f';

  select count(*) into expected_hash_rows
  from cards
  where id = '86112bb9-98f9-4615-8464-fbe770a5235f'
    and md5(coalesce(oracle_text, '')) = '4e62bff316f784c1b468b9e53146d2aa'
    and oracle_text = E'Extort (Whenever you cast a spell, you may pay {W/B}. If you do, each opponent loses 1 life and you gain that much life.)\nArtifacts and creatures your opponents control enter tapped.';

  if expected_card_rows <> 1 or expected_hash_rows <> 1 then
    raise exception 'Blind Obedience card/hash precondition failed: card_rows=%, hash_rows=%',
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
  'blind obedience',
  'battle_rule_v1:40f23fcea3b7955bacd550a9090c6872',
  '86112bb9-98f9-4615-8464-fbe770a5235f',
  'Blind Obedience',
  '{"cmc":2.0,"effect":"passive","opponents_artifacts_creatures_enter_tapped":true,"extort":true,"extort_payment":"{W/B}","extort_execution_status":"annotation_only","battle_model_scope":"opponent_artifact_creature_enter_tapped_extort_annotation_v1"}'::jsonb,
  '{"category":"stax","effect":"opponent_artifact_creature_enter_tapped","subtype":"extort_annotation"}'::jsonb,
  'curated',
  0.940,
  'active',
  'auto',
  1,
  '4e62bff316f784c1b468b9e53146d2aa',
  'PG048 oracle-backed static model: artifacts and creatures opponents control enter tapped is executable for normal permanent entry paths. Extort is preserved as annotation_only until optional hybrid-mana spell-cast payment triggers are implemented.',
  'codex_pg048',
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
  reviewed_by = 'codex_pg048',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG048 disabled: legacy passive row lacked oracle_hash and did not encode Blind Obedience static enter-tapped scope or extort annotation.')
where normalized_name = 'blind obedience'
  and logical_rule_key = 'battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg048',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG048 disabled: generated draw_engine shadow is not supported by Blind Obedience oracle text.')
where normalized_name = 'blind obedience'
  and logical_rule_key = 'battle_rule_v1:81701a2e0221de09cf7cf5ba202a3ef0';

do $$
declare
  exact_count integer;
  legacy_enabled_count integer;
  generated_review_only_count integer;
  trusted_missing_hash_count integer;
begin
  select count(*) into exact_count
  from card_battle_rules
  where normalized_name = 'blind obedience'
    and logical_rule_key = 'battle_rule_v1:40f23fcea3b7955bacd550a9090c6872'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = '4e62bff316f784c1b468b9e53146d2aa'
    and effect_json->>'effect' = 'passive'
    and effect_json->>'battle_model_scope' = 'opponent_artifact_creature_enter_tapped_extort_annotation_v1'
    and effect_json->>'opponents_artifacts_creatures_enter_tapped' = 'true'
    and effect_json->>'extort_execution_status' = 'annotation_only';

  select count(*) into legacy_enabled_count
  from card_battle_rules
  where normalized_name = 'blind obedience'
    and logical_rule_key in (
      'battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93',
      'battle_rule_v1:81701a2e0221de09cf7cf5ba202a3ef0'
    )
    and review_status in ('active', 'verified')
    and execution_status = 'auto';

  select count(*) into generated_review_only_count
  from card_battle_rules
  where normalized_name = 'blind obedience'
    and logical_rule_key = 'battle_rule_v1:81701a2e0221de09cf7cf5ba202a3ef0'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name = 'blind obedience'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if exact_count <> 1
     or legacy_enabled_count <> 0
     or generated_review_only_count <> 0
     or trusted_missing_hash_count <> 0 then
    raise exception 'PG048 postcondition failed: exact=%, legacy=%, generated_review=%, missing_hash=%',
      exact_count, legacy_enabled_count, generated_review_only_count, trusted_missing_hash_count;
  end if;
end $$;

commit;
