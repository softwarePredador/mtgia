\set ON_ERROR_STOP on

DO $$
DECLARE
  target_deck_id CONSTANT uuid := '8c22deb9-80bd-489f-8e87-1344eabac698';
  target_rows integer;
  target_quantity integer;
  commander_identity text[];
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_manifest') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup') IS NULL THEN
    RAISE EXCEPTION 'PG870 rollback evidence is missing';
  END IF;

  IF (SELECT count(*) FROM manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_manifest) <> 1
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup) <> 2 THEN
    RAISE EXCEPTION 'PG870 rollback evidence has unexpected cardinality';
  END IF;

  SELECT count(*), coalesce(sum(quantity), 0)
    INTO target_rows, target_quantity
  FROM public.deck_cards
  WHERE deck_id = target_deck_id;

  IF target_rows <> 94 OR target_quantity <> 100 THEN
    RAISE EXCEPTION 'PG870 expected 94 rows/100 cards, found % rows/% cards', target_rows, target_quantity;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.deck_cards
    WHERE id = '63191ded-d282-415e-90e3-b75241cede69'
       OR (deck_id = target_deck_id AND card_id = '265d2a18-085f-419a-ab8e-0a56501f5e9f')
  ) THEN
    RAISE EXCEPTION 'PG870 Auntie Flint remains in the target deck';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    JOIN public.cards c ON c.id = dc.card_id
    WHERE dc.id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
      AND dc.deck_id = target_deck_id
      AND dc.quantity = 5
      AND dc.is_commander IS FALSE
      AND dc.condition = 'NM'
      AND c.name = 'Mountain // Mountain'
      AND EXISTS (
        SELECT 1 FROM public.card_legalities cl
        WHERE cl.card_id = c.id AND cl.format = 'commander' AND cl.status = 'legal'
      )
  ) THEN
    RAISE EXCEPTION 'PG870 legal Mountain replacement is missing or drifted';
  END IF;

  SELECT c.color_identity
    INTO commander_identity
  FROM public.deck_cards dc
  JOIN public.cards c ON c.id = dc.card_id
  WHERE dc.deck_id = target_deck_id
    AND dc.is_commander IS TRUE
    AND dc.quantity = 1
    AND c.name = 'Auntie Ool, Cursewretch';

  IF commander_identity IS NULL THEN
    RAISE EXCEPTION 'PG870 commander is missing';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    JOIN public.cards c ON c.id = dc.card_id
    WHERE dc.deck_id = target_deck_id
      AND NOT (c.color_identity <@ commander_identity)
  ) THEN
    RAISE EXCEPTION 'PG870 target deck still contains an off-color card';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.deck_cards dc
    LEFT JOIN public.card_legalities cl
      ON cl.card_id = dc.card_id
     AND cl.format = 'commander'
    WHERE dc.deck_id = target_deck_id
      AND coalesce(cl.status, 'missing') <> 'legal'
  ) THEN
    RAISE EXCEPTION 'PG870 target deck still contains a non-legal Commander card';
  END IF;
END
$$;

SELECT
  d.id AS deck_id,
  d.name,
  count(dc.*) AS deck_rows,
  sum(dc.quantity) AS deck_quantity,
  count(*) FILTER (WHERE dc.is_commander) AS commander_rows,
  count(*) FILTER (WHERE cl.status <> 'legal' OR cl.status IS NULL) AS non_legal_rows
FROM public.decks d
JOIN public.deck_cards dc ON dc.deck_id = d.id
LEFT JOIN public.card_legalities cl
  ON cl.card_id = dc.card_id
 AND cl.format = 'commander'
WHERE d.id = '8c22deb9-80bd-489f-8e87-1344eabac698'
GROUP BY d.id, d.name;
