WITH target_cards(card_name) AS (
  VALUES
    ('Boros Garrison'),
    ('Boseiju, Who Shelters All'),
    ('Command Beacon'),
    ('Eiganjo, Seat of the Empire'),
    ('Furycalm Snarl'),
    ('Reliquary Tower'),
    ('Valakut, the Molten Pinnacle')
),
target_rows AS (
  SELECT
    c.name,
    c.type_line,
    c.oracle_text,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.effect_json,
    r.deck_role_json,
    r.notes
  FROM target_cards t
  JOIN public.cards c
    ON lower(c.name) = lower(t.card_name)
  JOIN public.card_battle_rules r
    ON r.card_id = c.id
  WHERE r.logical_rule_key IN (
    'battle_rule_v1:55c2bc99b653af8c05e99108f1c45b5d',
    'battle_rule_v1:2be7a9b6c891893428bd34f4866a48a8',
    'battle_rule_v1:33d0f77ed0b6806a7128dbd3d865b167',
    'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
  )
)
SELECT *
FROM target_rows
ORDER BY name, source, logical_rule_key;

WITH target_cards(card_name) AS (
  VALUES
    ('Boros Garrison'),
    ('Boseiju, Who Shelters All'),
    ('Command Beacon'),
    ('Eiganjo, Seat of the Empire'),
    ('Furycalm Snarl'),
    ('Reliquary Tower'),
    ('Valakut, the Molten Pinnacle')
),
target_rows AS (
  SELECT c.name, r.*
  FROM target_cards t
  JOIN public.cards c
    ON lower(c.name) = lower(t.card_name)
  JOIN public.card_battle_rules r
    ON r.card_id = c.id
)
SELECT
  count(DISTINCT name) AS target_cards,
  count(*) FILTER (
    WHERE source = 'generated'
      AND review_status = 'needs_review'
      AND execution_status = 'review_only'
  ) AS generated_review_only_rows,
  count(*) FILTER (
    WHERE source = 'curated'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND effect_json ->> 'effect' = 'land'
      AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
  ) AS trusted_land_rows
FROM target_rows;
