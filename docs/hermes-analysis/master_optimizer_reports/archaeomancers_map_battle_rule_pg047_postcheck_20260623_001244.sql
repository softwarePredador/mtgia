\pset pager off
\echo 'PG047 Archaeomancer''s Map battle-rule postcheck'

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
where card_id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
   or normalized_name = 'archaeomancer''s map'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where normalized_name = 'archaeomancer''s map'
      and logical_rule_key = 'battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e'
      and review_status = 'active'
      and execution_status = 'auto'
      and oracle_hash = '22b82ca6bbef42371227bc38a9a546b5'
      and effect_json->>'effect' = 'ramp_engine'
      and effect_json->>'battle_model_scope' = 'basic_plains_etb_plus_opponent_land_catchup_v2'
      and effect_json->>'etb_tutor_target' = 'basic_plains'
      and effect_json->>'trigger_condition' = 'opponent_controls_more_lands_than_you'
      and effect_json->>'trigger_rechecks_on_resolution' = 'true'
  ) as oracle_hashed_archaeomancers_map_rows,
  count(*) filter (
    where normalized_name = 'archaeomancer''s map'
      and logical_rule_key in (
        'battle_rule_v1:a2cbd7e64ee611d7284e4aa326e06d36',
        'battle_rule_v1:d8dfc058ea5870cde290c3d57dc34849',
        'battle_rule_v1:f1fec28b4adc813d6a8a0a5722c288cd'
      )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_or_shadow_enabled_rows,
  count(*) filter (
    where normalized_name = 'archaeomancer''s map'
      and logical_rule_key in (
        'battle_rule_v1:d8dfc058ea5870cde290c3d57dc34849',
        'battle_rule_v1:f1fec28b4adc813d6a8a0a5722c288cd'
      )
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name = 'archaeomancer''s map'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
