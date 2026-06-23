\pset pager off
\echo 'PG043 Wheel of Fortune battle-rule precheck'

with target_card as (
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
  where id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
)
select * from target_card;

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
  created_at,
  updated_at
from card_battle_rules
where card_id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
   or normalized_name = 'wheel of fortune'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
  ) as card_rows,
  count(distinct oracle_id) filter (
    where id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
  ) as distinct_oracle_ids,
  count(*) filter (
    where id = '534bdccc-25ac-4776-a986-4a8e943cbaa4'
      and md5(coalesce(oracle_text, '')) = 'c37cd579d8132efac0c2118608f6f001'
      and oracle_text = 'Each player discards their hand, then draws seven cards.'
  ) as expected_oracle_hash_rows
from cards;

select
  count(*) filter (
    where normalized_name = 'wheel of fortune'
      and logical_rule_key = 'battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and oracle_hash = 'c37cd579d8132efac0c2118608f6f001'
  ) as oracle_hashed_multiplayer_wheel_rows,
  count(*) filter (
    where normalized_name = 'wheel of fortune'
      and logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as legacy_curated_executable_without_hash_rows,
  count(*) filter (
    where normalized_name = 'wheel of fortune'
      and logical_rule_key = 'battle_rule_v1:3bd7f7866ce30619d4d92b4e9e7b520e'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name = 'wheel of fortune'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and effect_json->>'effect' = 'draw_cards'
      and nullif(effect_json->>'battle_model_scope', '') is null
  ) as trusted_draw_without_model_scope_rows,
  count(*) filter (
    where normalized_name = 'wheel of fortune'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
