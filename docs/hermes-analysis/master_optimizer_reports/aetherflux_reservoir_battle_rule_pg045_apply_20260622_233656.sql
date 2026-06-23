\pset pager off
\echo 'PG045 Aetherflux Reservoir battle-rule apply'

begin;

create schema if not exists manaloom_deploy_audit;

do $$
begin
  if to_regclass('manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656') is not null then
    raise exception 'Backup table manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656 already exists';
  end if;
end $$;

create table manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656 as
select *
from card_battle_rules
where card_id = '4c1b213e-a694-49f4-9882-e774950dac55'
   or normalized_name = 'aetherflux reservoir';

do $$
declare
  expected_card_rows integer;
  expected_hash_rows integer;
begin
  select count(*) into expected_card_rows
  from cards
  where id = '4c1b213e-a694-49f4-9882-e774950dac55';

  select count(*) into expected_hash_rows
  from cards
  where id = '4c1b213e-a694-49f4-9882-e774950dac55'
    and md5(coalesce(oracle_text, '')) = 'ea5327899fb66a2d583e80e8ca12d9b2'
    and oracle_text = 'Whenever you cast a spell, you gain 1 life for each spell you''ve cast this turn.
Pay 50 life: This artifact deals 50 damage to any target.';

  if expected_card_rows <> 1 or expected_hash_rows <> 1 then
    raise exception 'Aetherflux Reservoir card/hash precondition failed: card_rows=%, hash_rows=%',
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
  'aetherflux reservoir',
  'battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5',
  '4c1b213e-a694-49f4-9882-e774950dac55',
  'Aetherflux Reservoir',
  '{"cmc":4.0,"effect":"aetherflux_reservoir","artifact":true,"spell_cast_lifegain":true,"life_gain_equal_spells_cast_this_turn":true,"activation_life_cost":50,"activation_damage":50,"activation_target":"any_target","activation_execution_status":"annotation_only","battle_model_scope":"spell_cast_lifegain_pay_50_damage_annotation_v1"}'::jsonb,
  '{"category":"wincon","effect":"aetherflux_reservoir","subtype":"spell_chain_lifegain_finisher","activation":"pay_50_life_deal_50_annotation_only","timing":"artifact_permanent"}'::jsonb,
  'curated',
  0.950,
  'active',
  'auto',
  1,
  'ea5327899fb66a2d583e80e8ca12d9b2',
  'PG045 oracle-hash activation: Aetherflux Reservoir has an executable spell-cast lifegain trigger. The Pay 50 life, deal 50 damage activated ability is recorded as annotation_only until a dedicated life-payment activated-wincon executor exists.',
  'codex_pg045',
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
  reviewed_by = 'codex_pg045',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG045 disabled: legacy curated Aetherflux Reservoir row lacked oracle_hash and battle_model_scope, and collapsed the card into generic finisher.')
where normalized_name = 'aetherflux reservoir'
  and logical_rule_key = 'battle_rule_v1:3895145eecb0a2ac9b7805febd67ea54';

update card_battle_rules
set
  review_status = 'deprecated',
  execution_status = 'disabled',
  reviewed_by = 'codex_pg045',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG045 disabled: generated Aetherflux Reservoir shadow is superseded by the oracle-backed spell_cast_lifegain_pay_50_damage_annotation_v1 rule.')
where normalized_name = 'aetherflux reservoir'
  and logical_rule_key = 'battle_rule_v1:53d7252f111b777ddf7ff42a275c4a38';

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
  where normalized_name = 'aetherflux reservoir'
    and logical_rule_key = 'battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5'
    and review_status = 'active'
    and execution_status = 'auto'
    and oracle_hash = 'ea5327899fb66a2d583e80e8ca12d9b2'
    and effect_json->>'effect' = 'aetherflux_reservoir'
    and effect_json->>'battle_model_scope' = 'spell_cast_lifegain_pay_50_damage_annotation_v1'
    and effect_json->>'activation_execution_status' = 'annotation_only';

  select count(*) into legacy_enabled_count
  from card_battle_rules
  where normalized_name = 'aetherflux reservoir'
    and logical_rule_key = 'battle_rule_v1:3895145eecb0a2ac9b7805febd67ea54'
    and review_status in ('active', 'verified')
    and execution_status = 'auto';

  select count(*) into generated_review_only_count
  from card_battle_rules
  where normalized_name = 'aetherflux reservoir'
    and logical_rule_key = 'battle_rule_v1:53d7252f111b777ddf7ff42a275c4a38'
    and (review_status = 'needs_review' or execution_status = 'review_only');

  select count(*) into generic_without_scope_count
  from card_battle_rules
  where normalized_name = 'aetherflux reservoir'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and effect_json->>'effect' = 'finisher'
    and nullif(effect_json->>'battle_model_scope', '') is null;

  select count(*) into trusted_missing_hash_count
  from card_battle_rules
  where normalized_name = 'aetherflux reservoir'
    and review_status in ('active', 'verified')
    and execution_status = 'auto'
    and nullif(oracle_hash, '') is null;

  if exact_count <> 1
     or legacy_enabled_count <> 0
     or generated_review_only_count <> 0
     or generic_without_scope_count <> 0
     or trusted_missing_hash_count <> 0 then
    raise exception 'PG045 postcondition failed: exact=%, legacy=%, generated_review=%, generic_without_scope=%, missing_hash=%',
      exact_count, legacy_enabled_count, generated_review_only_count, generic_without_scope_count, trusted_missing_hash_count;
  end if;
end $$;

commit;
