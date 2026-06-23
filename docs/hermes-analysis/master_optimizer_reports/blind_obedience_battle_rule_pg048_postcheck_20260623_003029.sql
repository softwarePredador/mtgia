\pset pager off
\echo 'PG048 Blind Obedience battle-rule postcheck'

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
where card_id = '86112bb9-98f9-4615-8464-fbe770a5235f'
   or normalized_name = 'blind obedience'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where normalized_name = 'blind obedience'
      and logical_rule_key = 'battle_rule_v1:40f23fcea3b7955bacd550a9090c6872'
      and review_status = 'active'
      and execution_status = 'auto'
      and oracle_hash = '4e62bff316f784c1b468b9e53146d2aa'
      and effect_json->>'effect' = 'passive'
      and effect_json->>'battle_model_scope' = 'opponent_artifact_creature_enter_tapped_extort_annotation_v1'
      and effect_json->>'opponents_artifacts_creatures_enter_tapped' = 'true'
      and effect_json->>'extort_execution_status' = 'annotation_only'
  ) as oracle_hashed_blind_obedience_rows,
  count(*) filter (
    where normalized_name = 'blind obedience'
      and logical_rule_key in (
        'battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93',
        'battle_rule_v1:81701a2e0221de09cf7cf5ba202a3ef0'
      )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_or_shadow_enabled_rows,
  count(*) filter (
    where normalized_name = 'blind obedience'
      and logical_rule_key = 'battle_rule_v1:81701a2e0221de09cf7cf5ba202a3ef0'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name = 'blind obedience'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
