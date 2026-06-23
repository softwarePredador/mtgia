\pset pager off
\echo 'PG048 Blind Obedience battle-rule precheck'

select
  id,
  oracle_id,
  name,
  mana_cost,
  cmc,
  type_line,
  oracle_text,
  md5(coalesce(oracle_text, '')) as oracle_hash
from cards
where id = '86112bb9-98f9-4615-8464-fbe770a5235f'
   or lower(name) = lower('Blind Obedience');

select
  published_at,
  comment
from card_rulings
where oracle_id::text = '5d998c09-7d89-4265-ada4-6d80cbf56dae'
order by published_at nulls last, id;

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
    where id = '86112bb9-98f9-4615-8464-fbe770a5235f'
  ) as card_rows,
  count(*) filter (
    where id = '86112bb9-98f9-4615-8464-fbe770a5235f'
      and md5(coalesce(oracle_text, '')) = '4e62bff316f784c1b468b9e53146d2aa'
      and oracle_text = E'Extort (Whenever you cast a spell, you may pay {W/B}. If you do, each opponent loses 1 life and you gain that much life.)\nArtifacts and creatures your opponents control enter tapped.'
  ) as oracle_hash_rows
from cards;

select
  count(*) filter (
    where normalized_name = 'blind obedience'
      and logical_rule_key = 'battle_rule_v1:40f23fcea3b7955bacd550a9090c6872'
  ) as target_rule_rows_before,
  count(*) filter (
    where normalized_name = 'blind obedience'
      and logical_rule_key = 'battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_trusted_enabled_rows,
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
