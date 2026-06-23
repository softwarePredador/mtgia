\pset pager off
\echo 'PG046 Approach of the Second Sun battle-rule postcheck'

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
where card_id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
   or normalized_name = 'approach of the second sun'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and logical_rule_key = 'battle_rule_v1:ed74fb069b6c1d635392d907804a1d98'
      and review_status = 'active'
      and execution_status = 'auto'
      and oracle_hash = '0838960b80a282fb4508532f7bae8c2b'
      and effect_json->>'effect' = 'approach'
      and effect_json->>'battle_model_scope' = 'approach_second_cast_win_v2'
      and effect_json->>'countered_first_cast_counts' = 'true'
      and effect_json->>'copy_spell_does_not_count' = 'true'
  ) as oracle_hashed_approach_second_cast_rows,
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and logical_rule_key in (
        'battle_rule_v1:c9594094630e58aa220dd4e82309f597',
        'battle_rule_v1:d89b90f224cfa72e048c8adef2f80185',
        'battle_rule_v1:6e281d363c92040c064cda01b445b596'
      )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_or_shadow_enabled_rows,
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and logical_rule_key = 'battle_rule_v1:6e281d363c92040c064cda01b445b596'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
