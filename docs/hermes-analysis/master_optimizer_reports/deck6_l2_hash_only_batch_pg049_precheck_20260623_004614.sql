\pset pager off
\echo 'PG049 deck 6 L2 hash-only batch precheck'

with target_cards(name) as (
  values
    ('Crawlspace'),
    ('Ghostly Prison'),
    ('Valakut Awakening // Valakut Stoneforge')
)
select
  c.id,
  c.oracle_id,
  c.name,
  c.mana_cost,
  c.cmc,
  c.type_line,
  c.layout,
  c.card_faces_json is not null as has_card_faces_json,
  md5(coalesce(c.oracle_text, '')) as oracle_hash,
  c.oracle_text
from cards c
join target_cards t on t.name = c.name
order by c.name;

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

with expected(card_name, card_id, expected_hash) as (
  values
    ('Crawlspace', 'b6c3ff3b-e172-4e40-b9b3-b5eb2f5f0e7b'::uuid, '57fcd38030641ceb36bbcf1a6dcbc6c8'),
    ('Ghostly Prison', '648e2ae9-e079-4a62-9b45-8fae846c81cd'::uuid, '5725b39ca4bb7c5e8e4bebf0d246be13'),
    ('Valakut Awakening // Valakut Stoneforge', '75a73cfc-e7a7-4280-9fac-f3b1810d26fd'::uuid, '22b42fcc181b7aed71f78b2e1e51e887')
)
select
  count(*) filter (
    where c.id = e.card_id and c.name = e.card_name
  ) as card_rows,
  count(*) filter (
    where c.id = e.card_id
      and c.name = e.card_name
      and md5(coalesce(c.oracle_text, '')) = e.expected_hash
  ) as oracle_hash_rows
from expected e
left join cards c on c.id = e.card_id;

select
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
      and review_status = 'needs_review'
      and execution_status = 'disabled'
  ) as valakut_generated_disabled_shadow_rows
from card_battle_rules;
