\pset pager off
\echo 'PG046 Approach of the Second Sun battle-rule precheck'

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
where id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
   or name = 'Approach of the Second Sun';

select
  published_at,
  comment
from card_rulings
where oracle_id = 'e4125377-34c0-4b54-bdf8-4e88f5d24565'
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
where card_id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
   or normalized_name = 'approach of the second sun'
order by created_at nulls last, normalized_name, logical_rule_key;

select
  count(*) filter (
    where id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
  ) as card_rows,
  count(*) filter (
    where id = '3730958e-18ee-4dde-bd62-46a18b24bf11'
      and md5(coalesce(oracle_text, '')) = '0838960b80a282fb4508532f7bae8c2b'
      and oracle_text = 'If this spell was cast from your hand and you''ve cast another spell named Approach of the Second Sun this game, you win the game. Otherwise, put Approach of the Second Sun into its owner''s library seventh from the top and you gain 7 life.'
  ) as oracle_hash_rows
from cards;

select
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and logical_rule_key = 'battle_rule_v1:ed74fb069b6c1d635392d907804a1d98'
  ) as target_rule_rows_before,
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and logical_rule_key in (
        'battle_rule_v1:c9594094630e58aa220dd4e82309f597',
        'battle_rule_v1:d89b90f224cfa72e048c8adef2f80185'
      )
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
  ) as legacy_trusted_enabled_rows,
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and logical_rule_key = 'battle_rule_v1:6e281d363c92040c064cda01b445b596'
      and (review_status = 'needs_review' or execution_status = 'review_only')
  ) as generated_review_only_shadow_rows,
  count(*) filter (
    where normalized_name = 'approach of the second sun'
      and review_status in ('active', 'verified')
      and execution_status = 'auto'
      and nullif(oracle_hash, '') is null
  ) as trusted_executable_without_oracle_hash_rows
from card_battle_rules;
