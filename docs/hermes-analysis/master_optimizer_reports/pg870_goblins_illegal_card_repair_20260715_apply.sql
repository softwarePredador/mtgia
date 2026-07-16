\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

SELECT id
FROM public.decks
WHERE id = '8c22deb9-80bd-489f-8e87-1344eabac698'
FOR UPDATE;

SELECT id
FROM public.deck_cards
WHERE id IN (
  '63191ded-d282-415e-90e3-b75241cede69',
  'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
)
ORDER BY id
FOR UPDATE;

DO $$
DECLARE
  target_deck_id CONSTANT uuid := '8c22deb9-80bd-489f-8e87-1344eabac698';
  target_rows integer;
  target_quantity integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_manifest') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup') IS NOT NULL THEN
    RAISE EXCEPTION 'PG870 audit tables already exist; refuse to overwrite rollback evidence';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.decks
    WHERE id = target_deck_id
      AND user_id = '18df0188-9f27-4e20-84fe-a9fa2c39951c'
      AND name = 'goblins'
      AND lower(format) = 'commander'
      AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'PG870 target deck identity drifted';
  END IF;

  SELECT count(*), coalesce(sum(quantity), 0)
    INTO target_rows, target_quantity
  FROM public.deck_cards
  WHERE deck_id = target_deck_id;

  IF target_rows <> 95 OR target_quantity <> 100 THEN
    RAISE EXCEPTION 'PG870 expected 95 rows/100 cards, found % rows/% cards', target_rows, target_quantity;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    JOIN public.cards c ON c.id = dc.card_id
    WHERE dc.id = '63191ded-d282-415e-90e3-b75241cede69'
      AND dc.deck_id = target_deck_id
      AND dc.card_id = '265d2a18-085f-419a-ab8e-0a56501f5e9f'
      AND dc.quantity = 1
      AND dc.is_commander IS FALSE
      AND dc.condition = 'NM'
      AND c.name = 'Auntie Flint'
      AND EXISTS (
        SELECT 1 FROM public.card_legalities cl
        WHERE cl.card_id = c.id AND cl.format = 'commander' AND cl.status = 'not_legal'
      )
  ) THEN
    RAISE EXCEPTION 'PG870 Auntie Flint source row drifted';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    JOIN public.cards c ON c.id = dc.card_id
    WHERE dc.id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
      AND dc.deck_id = target_deck_id
      AND dc.card_id = '73d87611-651a-4318-a0ae-5e83446dd762'
      AND dc.quantity = 4
      AND dc.is_commander IS FALSE
      AND dc.condition = 'NM'
      AND c.name = 'Mountain // Mountain'
      AND c.color_identity <@ ARRAY['B', 'G', 'R']::text[]
      AND EXISTS (
        SELECT 1 FROM public.card_legalities cl
        WHERE cl.card_id = c.id AND cl.format = 'commander' AND cl.status = 'legal'
      )
  ) THEN
    RAISE EXCEPTION 'PG870 replacement Mountain source row drifted';
  END IF;
END
$$;

CREATE TABLE manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_manifest AS
SELECT
  d.id AS deck_id,
  d.user_id,
  d.name AS deck_name,
  d.format,
  95::integer AS original_rows,
  100::integer AS original_quantity,
  '63191ded-d282-415e-90e3-b75241cede69'::uuid AS removed_deck_card_id,
  'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'::uuid AS incremented_deck_card_id,
  current_timestamp AS applied_at
FROM public.decks d
WHERE d.id = '8c22deb9-80bd-489f-8e87-1344eabac698';

CREATE TABLE manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup AS
SELECT id, deck_id, card_id, quantity, is_commander, condition
FROM public.deck_cards
WHERE id IN (
  '63191ded-d282-415e-90e3-b75241cede69',
  'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
)
ORDER BY id;

DO $$
BEGIN
  IF (SELECT count(*) FROM manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_manifest) <> 1
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup) <> 2 THEN
    RAISE EXCEPTION 'PG870 rollback snapshot is incomplete';
  END IF;
END
$$;

DELETE FROM public.deck_cards
WHERE id = '63191ded-d282-415e-90e3-b75241cede69'
  AND deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698'
  AND card_id = '265d2a18-085f-419a-ab8e-0a56501f5e9f'
  AND quantity = 1
  AND is_commander IS FALSE;

UPDATE public.deck_cards
SET quantity = 5
WHERE id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
  AND deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698'
  AND card_id = '73d87611-651a-4318-a0ae-5e83446dd762'
  AND quantity = 4
  AND is_commander IS FALSE;

DO $$
DECLARE
  target_rows integer;
  target_quantity integer;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.deck_cards
    WHERE id = '63191ded-d282-415e-90e3-b75241cede69'
  ) THEN
    RAISE EXCEPTION 'PG870 illegal deck-card row was not removed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.deck_cards
    WHERE id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
      AND deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698'
      AND card_id = '73d87611-651a-4318-a0ae-5e83446dd762'
      AND quantity = 5
      AND is_commander IS FALSE
      AND condition = 'NM'
  ) THEN
    RAISE EXCEPTION 'PG870 Mountain increment did not reach its exact target state';
  END IF;

  SELECT count(*), coalesce(sum(quantity), 0)
    INTO target_rows, target_quantity
  FROM public.deck_cards
  WHERE deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698';

  IF target_rows <> 94 OR target_quantity <> 100 THEN
    RAISE EXCEPTION 'PG870 post-state expected 94 rows/100 cards, found % rows/% cards', target_rows, target_quantity;
  END IF;
END
$$;

COMMIT;
