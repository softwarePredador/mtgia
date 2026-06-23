\pset pager off
\echo 'PG042 Valakut Awakening battle-rule precheck'

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
  where id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
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
where card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
   or normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
  ) as card_rows,
  count(distinct oracle_id) filter (
    where id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
  ) as distinct_oracle_ids,
  count(*) filter (
    where id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
      and md5(coalesce(oracle_text, '')) = '22b42fcc181b7aed71f78b2e1e51e887'
  ) as expected_oracle_hash_rows
from cards;

select
  count(*) filter (
    where normalized_name = 'valakut awakening // valakut stoneforge'
      and logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
  ) as exact_full_executable_with_hash_rows,
  count(*) filter (
    where normalized_name = 'valakut awakening'
      and logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
  ) as exact_alias_executable_with_hash_rows,
  count(*) filter (
    where normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows,
  count(*) filter (
    where normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
      and logical_rule_key in (
        'battle_rule_v1:88dd44afe6b8d12389094384c46eb0d4',
        'battle_rule_v1:abc2aab4f282840b48f5cc1d23c71457'
      )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_enabled_rows,
  count(*) filter (
    where normalized_name = 'valakut awakening // valakut stoneforge'
      and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
      and review_status = 'needs_review'
      and execution_status = 'review_only'
  ) as generated_review_only_shadow_rows
from card_battle_rules;
