\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  target_deck_id CONSTANT uuid := '8c22deb9-80bd-489f-8e87-1344eabac698';
  illegal_deck_card_id CONSTANT uuid := '63191ded-d282-415e-90e3-b75241cede69';
  mountain_deck_card_id CONSTANT uuid := 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c';
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
    WHERE dc.id = illegal_deck_card_id
      AND dc.deck_id = target_deck_id
      AND dc.card_id = '265d2a18-085f-419a-ab8e-0a56501f5e9f'
      AND dc.quantity = 1
      AND dc.is_commander IS FALSE
      AND dc.condition = 'NM'
      AND c.name = 'Auntie Flint'
      AND EXISTS (
        SELECT 1
        FROM public.card_legalities cl
        WHERE cl.card_id = c.id
          AND cl.format = 'commander'
          AND cl.status = 'not_legal'
      )
  ) THEN
    RAISE EXCEPTION 'PG870 Auntie Flint source row drifted';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    JOIN public.cards c ON c.id = dc.card_id
    WHERE dc.id = mountain_deck_card_id
      AND dc.deck_id = target_deck_id
      AND dc.card_id = '73d87611-651a-4318-a0ae-5e83446dd762'
      AND dc.quantity = 4
      AND dc.is_commander IS FALSE
      AND dc.condition = 'NM'
      AND c.name = 'Mountain // Mountain'
      AND c.color_identity <@ ARRAY['B', 'G', 'R']::text[]
      AND EXISTS (
        SELECT 1
        FROM public.card_legalities cl
        WHERE cl.card_id = c.id
          AND cl.format = 'commander'
          AND cl.status = 'legal'
      )
  ) THEN
    RAISE EXCEPTION 'PG870 replacement Mountain source row drifted';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    JOIN public.cards c ON c.id = dc.card_id
    WHERE dc.deck_id = target_deck_id
      AND dc.is_commander IS TRUE
      AND dc.quantity = 1
      AND c.id = 'dedf254c-2672-46e6-bc76-41d6645c5652'
      AND c.name = 'Auntie Ool, Cursewretch'
      AND c.color_identity @> ARRAY['B', 'G', 'R']::text[]
      AND c.color_identity <@ ARRAY['B', 'G', 'R']::text[]
      AND EXISTS (
        SELECT 1
        FROM public.card_legalities cl
        WHERE cl.card_id = c.id
          AND cl.format = 'commander'
          AND cl.status = 'legal'
      )
  ) THEN
    RAISE EXCEPTION 'PG870 commander identity or legality drifted';
  END IF;

  IF (
    SELECT count(*)
    FROM public.deck_cards dc
    JOIN public.card_legalities cl
      ON cl.card_id = dc.card_id
     AND cl.format = 'commander'
    WHERE dc.deck_id = target_deck_id
      AND cl.status <> 'legal'
  ) <> 1 THEN
    RAISE EXCEPTION 'PG870 expected exactly one non-legal Commander row';
  END IF;
END
$$;

SELECT
  d.id AS deck_id,
  d.name,
  count(dc.*) AS deck_rows,
  sum(dc.quantity) AS deck_quantity,
  count(*) FILTER (WHERE cl.status <> 'legal') AS non_legal_rows
FROM public.decks d
JOIN public.deck_cards dc ON dc.deck_id = d.id
LEFT JOIN public.card_legalities cl
  ON cl.card_id = dc.card_id
 AND cl.format = 'commander'
WHERE d.id = '8c22deb9-80bd-489f-8e87-1344eabac698'
GROUP BY d.id, d.name;

ROLLBACK;
