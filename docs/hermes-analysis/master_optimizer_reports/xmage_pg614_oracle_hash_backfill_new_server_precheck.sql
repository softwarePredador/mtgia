select
  count(*) as trusted_executable_rules_missing_oracle_hash,
  count(*) filter (where c.id is not null and c.oracle_text is not null) as rows_backfillable_from_cards_oracle_text
from card_battle_rules cbr
left join cards c on c.id = cbr.card_id
where cbr.execution_status = 'auto'
  and cbr.review_status in ('verified', 'active')
  and coalesce(cbr.oracle_hash, '') = '';

select
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.rule_version,
  cbr.source,
  md5(coalesce(c.oracle_text, '')) as computed_oracle_hash
from card_battle_rules cbr
join cards c on c.id = cbr.card_id
where cbr.execution_status = 'auto'
  and cbr.review_status in ('verified', 'active')
  and coalesce(cbr.oracle_hash, '') = ''
  and c.oracle_text is not null
order by cbr.normalized_name, cbr.logical_rule_key;
