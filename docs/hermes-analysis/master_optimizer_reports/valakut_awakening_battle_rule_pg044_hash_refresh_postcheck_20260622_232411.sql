\pset pager off
\echo 'PG044 Valakut Awakening hash refresh postcheck'

select
  normalized_name,
  card_name,
  logical_rule_key,
  effect_json,
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
where card_id = '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'
   or normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
order by normalized_name, logical_rule_key;

select
  count(*) filter (
    where normalized_name = 'valakut awakening // valakut stoneforge'
      and logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
      and review_status = 'active'
      and execution_status = 'auto'
      and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
  ) as exact_full_executable_with_hash_rows,
  count(*) filter (
    where normalized_name = 'valakut awakening'
      and logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
      and review_status = 'active'
      and execution_status = 'auto'
      and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
  ) as exact_alias_executable_with_hash_rows,
  count(*) filter (
    where normalized_name = 'valakut awakening // valakut stoneforge'
      and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name in ('valakut awakening', 'valakut awakening // valakut stoneforge')
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
