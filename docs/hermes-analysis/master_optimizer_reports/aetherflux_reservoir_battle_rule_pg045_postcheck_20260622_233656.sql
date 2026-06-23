\pset pager off
\echo 'PG045 Aetherflux Reservoir battle-rule postcheck'

select
  normalized_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  updated_at
from card_battle_rules
where card_id = '4c1b213e-a694-49f4-9882-e774950dac55'
   or normalized_name = 'aetherflux reservoir'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where normalized_name = 'aetherflux reservoir'
      and logical_rule_key = 'battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5'
      and review_status = 'active'
      and execution_status = 'auto'
      and oracle_hash = 'ea5327899fb66a2d583e80e8ca12d9b2'
      and effect_json->>'effect' = 'aetherflux_reservoir'
      and effect_json->>'battle_model_scope' = 'spell_cast_lifegain_pay_50_damage_annotation_v1'
      and effect_json->>'activation_execution_status' = 'annotation_only'
  ) as oracle_hashed_aetherflux_lifegain_rows,
  count(*) filter (
    where normalized_name = 'aetherflux reservoir'
      and logical_rule_key in (
        'battle_rule_v1:3895145eecb0a2ac9b7805febd67ea54',
        'battle_rule_v1:53d7252f111b777ddf7ff42a275c4a38'
      )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_or_shadow_enabled_rows,
  count(*) filter (
    where normalized_name = 'aetherflux reservoir'
      and logical_rule_key = 'battle_rule_v1:53d7252f111b777ddf7ff42a275c4a38'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name = 'aetherflux reservoir'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and effect_json->>'effect' = 'finisher'
      and nullif(effect_json->>'battle_model_scope', '') is null
  ) as trusted_finisher_without_model_scope_rows,
  count(*) filter (
    where normalized_name = 'aetherflux reservoir'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
