BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg248_deck606_land_shadow_cleanup_20260628 AS
WITH target_cards(card_name) AS (
  VALUES
    ('Boros Garrison'),
    ('Boseiju, Who Shelters All'),
    ('Command Beacon'),
    ('Eiganjo, Seat of the Empire'),
    ('Furycalm Snarl'),
    ('Reliquary Tower'),
    ('Valakut, the Molten Pinnacle')
)
SELECT r.*
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
);

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
updated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'rejected',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG248 2026-06-28: rejected generated land shadow for deck 606 L1 cleanup. Current trusted runtime remains curated land-only. Utility clauses are not promoted by this package and require separate oracle-specific executor if needed.'
    )
  FROM target_cards t
  JOIN public.cards c
    ON lower(c.name) = lower(t.card_name)
  WHERE r.card_id = c.id
    AND r.source = 'generated'
    AND r.review_status = 'needs_review'
    AND r.execution_status = 'review_only'
    AND r.logical_rule_key IN (
      'battle_rule_v1:55c2bc99b653af8c05e99108f1c45b5d',
      'battle_rule_v1:2be7a9b6c891893428bd34f4866a48a8',
      'battle_rule_v1:33d0f77ed0b6806a7128dbd3d865b167'
    )
  RETURNING r.normalized_name, r.logical_rule_key
)
SELECT count(*) AS rejected_shadow_rows FROM updated;

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
updated AS (
  UPDATE public.card_battle_rules r
  SET
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG248 2026-06-28: deck 606 L1 land gate accepted as generic land-only runtime. This is not a utility-land executor for ETB tapped, bounce, uncounterable mana, channel damage, commander-zone recursion, max hand size, or Valakut damage.'
    )
  FROM target_cards t
  JOIN public.cards c
    ON lower(c.name) = lower(t.card_name)
  WHERE r.card_id = c.id
    AND r.source = 'curated'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND r.effect_json ->> 'effect' = 'land'
  RETURNING r.normalized_name, r.logical_rule_key
)
SELECT count(*) AS annotated_trusted_land_rows FROM updated;

COMMIT;
