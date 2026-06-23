\pset pager off
\echo 'PG049 deck 6 L2 hash-only batch postcheck'

with target_cards(name) as (
  values
    ('Crawlspace'),
    ('Ghostly Prison'),
    ('Valakut Awakening // Valakut Stoneforge')
)
select
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  cbr.notes,
  cbr.reviewed_by,
  cbr.reviewed_at,
  cbr.updated_at
from cards c
join target_cards t on t.name = c.name
join card_battle_rules cbr on cbr.card_id = c.id
order by c.name, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

select
  count(*) filter (
    where logical_rule_key = 'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and oracle_hash = '57fcd38030641ceb36bbcf1a6dcbc6c8'
      and effect_json->>'effect' = 'attack_limit'
  ) as crawlspace_hashed_rows,
  count(*) filter (
    where logical_rule_key = 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and oracle_hash = '5725b39ca4bb7c5e8e4bebf0d246be13'
      and effect_json->>'effect' = 'attack_tax'
  ) as ghostly_prison_hashed_rows,
  count(*) filter (
    where logical_rule_key in (
      'battle_rule_v1:245b8d2627720fadfd7a30464d07605a',
      'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
    )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
      and effect_json->>'effect' = 'hand_filter'
  ) as valakut_hashed_rows,
  count(*) filter (
    where logical_rule_key in (
      'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591',
      'battle_rule_v1:99151859bece89ba3ead032e05b1f65a',
      'battle_rule_v1:245b8d2627720fadfd7a30464d07605a',
      'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
    )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as target_trusted_missing_hash_rows,
  count(*) filter (
    where normalized_name = 'valakut awakening // valakut stoneforge'
      and logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as valakut_generated_review_only_shadow_rows
from card_battle_rules;
