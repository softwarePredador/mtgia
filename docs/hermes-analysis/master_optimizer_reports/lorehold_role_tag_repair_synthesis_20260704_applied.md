# Lorehold Role/Tag Repair Synthesis

- generated_at: `2026-07-04T21:16:36Z`
- deck_id: `607`
- status: `role_tag_repair_applied`
- postgres_writes: `false`
- source_db_mutated: `true`

## Summary

- targets: `5`
- blockers before: `0`
- eligible updates before: `5`
- updated count: `5`
- remaining updates: `0`
- remaining blockers: `0`

## Repairs

| Card | Before | After | Recommended Tags | Evidence |
| --- | --- | --- | --- | --- |
| Deflecting Swat | `draw` | `protection` | `protection,redirect_removal` | protection:redirect_removal |
| Emeria's Call // Emeria, Shattered Skyclave | `unknown` | `protection` | `protection,board_development,token_maker` | board_development:token_maker |
| Promise of Loyalty | `draw` | `board_wipe` | `board_wipe,protection,interaction` | interaction:vow_counter_each_player_sacrifice_rest |
| Redirect Lightning | `draw` | `protection` | `protection,redirect_removal,interaction` | protection:redirect_removal |
| Tragic Arrogance | `unknown` | `board_wipe` | `board_wipe,removal,interaction` | interaction:selective_nonland_sacrifice |

## Apply SQL

```sql
BEGIN;
UPDATE deck_cards
SET functional_tag = 'protection',
    functional_tags_json = '["protection","redirect_removal"]'
WHERE deck_id = 607
  AND card_name = 'Deflecting Swat'
  AND card_id = 'ae0d54e1-1471-4bb7-8b8d-09ef5b51b2ed';

UPDATE deck_cards
SET functional_tag = 'protection',
    functional_tags_json = '["protection","board_development","token_maker"]'
WHERE deck_id = 607
  AND card_name = 'Emeria''s Call // Emeria, Shattered Skyclave'
  AND card_id = '356b93e3-62db-44ec-9322-4e999eefc674';

UPDATE deck_cards
SET functional_tag = 'board_wipe',
    functional_tags_json = '["board_wipe","protection","interaction"]'
WHERE deck_id = 607
  AND card_name = 'Promise of Loyalty'
  AND card_id = '6a219f1a-0b0a-4628-9d60-b81f7dbcab5c';

UPDATE deck_cards
SET functional_tag = 'protection',
    functional_tags_json = '["protection","redirect_removal","interaction"]'
WHERE deck_id = 607
  AND card_name = 'Redirect Lightning'
  AND card_id = '558a8bda-ea1a-4c01-b3c2-186a2ad6478d';

UPDATE deck_cards
SET functional_tag = 'board_wipe',
    functional_tags_json = '["board_wipe","removal","interaction"]'
WHERE deck_id = 607
  AND card_name = 'Tragic Arrogance'
  AND card_id = 'abe21b14-7c49-4629-bbf2-8fce03d66d94';
COMMIT;
```

## Rollback SQL

```sql
BEGIN;
UPDATE deck_cards
SET functional_tag = 'draw',
    functional_tags_json = '["draw","protection","redirect_removal"]'
WHERE deck_id = 607
  AND card_name = 'Deflecting Swat'
  AND card_id = 'ae0d54e1-1471-4bb7-8b8d-09ef5b51b2ed';

UPDATE deck_cards
SET functional_tag = 'unknown',
    functional_tags_json = '["unknown"]'
WHERE deck_id = 607
  AND card_name = 'Emeria''s Call // Emeria, Shattered Skyclave'
  AND card_id = '356b93e3-62db-44ec-9322-4e999eefc674';

UPDATE deck_cards
SET functional_tag = 'draw',
    functional_tags_json = '["draw"]'
WHERE deck_id = 607
  AND card_name = 'Promise of Loyalty'
  AND card_id = '6a219f1a-0b0a-4628-9d60-b81f7dbcab5c';

UPDATE deck_cards
SET functional_tag = 'draw',
    functional_tags_json = '["draw"]'
WHERE deck_id = 607
  AND card_name = 'Redirect Lightning'
  AND card_id = '558a8bda-ea1a-4c01-b3c2-186a2ad6478d';

UPDATE deck_cards
SET functional_tag = 'unknown',
    functional_tags_json = '["unknown"]'
WHERE deck_id = 607
  AND card_name = 'Tragic Arrogance'
  AND card_id = 'abe21b14-7c49-4629-bbf2-8fce03d66d94';
COMMIT;
```

## Decision

- safe_to_use_for_same_lane_cuts: `true`
- reason: The five current watch cards now have explicit primary roles and ordered multi-tags aligned to active battle rules and Oracle text.
