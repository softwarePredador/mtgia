\pset pager off
\echo 'PG047 Archaeomancer''s Map battle-rule precheck'

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
where id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
   or lower(name) = lower('Archaeomancer''s Map');

select
  published_at,
  comment
from card_rulings
where oracle_id::text = 'ef833546-f755-4ac5-867a-3926984e68a0'
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
where card_id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
   or normalized_name = 'archaeomancer''s map'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
  ) as card_rows,
  count(*) filter (
    where id = '5c0a4d98-9abb-436b-8464-cbd6f2ce35b1'
      and md5(coalesce(oracle_text, '')) = '22b82ca6bbef42371227bc38a9a546b5'
      and oracle_text = E'When this artifact enters, search your library for up to two basic Plains cards, reveal them, put them into your hand, then shuffle.\nWhenever a land an opponent controls enters, if that player controls more lands than you, you may put a land card from your hand onto the battlefield.'
  ) as oracle_hash_rows
from cards;

select
  count(*) filter (
    where normalized_name = 'archaeomancer''s map'
      and logical_rule_key = 'battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e'
  ) as target_rule_rows_before,
  count(*) filter (
    where normalized_name = 'archaeomancer''s map'
      and logical_rule_key = 'battle_rule_v1:a2cbd7e64ee611d7284e4aa326e06d36'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_trusted_enabled_rows,
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
