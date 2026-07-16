\set ON_ERROR_STOP on

BEGIN;

SELECT id
FROM public.decks
WHERE id = '8c22deb9-80bd-489f-8e87-1344eabac698'
FOR UPDATE;

SELECT id
FROM public.deck_cards
WHERE id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
FOR UPDATE;

DO $$
DECLARE
  target_rows integer;
  target_quantity integer;
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
  WHERE deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698';

  IF target_rows <> 94 OR target_quantity <> 100
     OR EXISTS (
       SELECT 1 FROM public.deck_cards
       WHERE id = '63191ded-d282-415e-90e3-b75241cede69'
     )
     OR NOT EXISTS (
       SELECT 1 FROM public.deck_cards
       WHERE id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
         AND deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698'
         AND card_id = '73d87611-651a-4318-a0ae-5e83446dd762'
         AND quantity = 5
         AND is_commander IS FALSE
         AND condition = 'NM'
     ) THEN
    RAISE EXCEPTION 'PG870 current deck no longer matches the exact applied state';
  END IF;
END
$$;

DELETE FROM public.deck_cards
WHERE id IN (
  SELECT id
  FROM manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup
);

INSERT INTO public.deck_cards (id, deck_id, card_id, quantity, is_commander, condition)
SELECT id, deck_id, card_id, quantity, is_commander, condition
FROM manaloom_deploy_audit.pg870_goblins_illegal_card_repair_20260715_deck_cards_backup
ORDER BY id;

DO $$
DECLARE
  target_rows integer;
  target_quantity integer;
BEGIN
  SELECT count(*), coalesce(sum(quantity), 0)
    INTO target_rows, target_quantity
  FROM public.deck_cards
  WHERE deck_id = '8c22deb9-80bd-489f-8e87-1344eabac698';

  IF target_rows <> 95 OR target_quantity <> 100
     OR NOT EXISTS (
       SELECT 1 FROM public.deck_cards
       WHERE id = '63191ded-d282-415e-90e3-b75241cede69'
         AND card_id = '265d2a18-085f-419a-ab8e-0a56501f5e9f'
         AND quantity = 1
     )
     OR NOT EXISTS (
       SELECT 1 FROM public.deck_cards
       WHERE id = 'e0e61a93-7f8e-4d01-a3de-60ad8c49185c'
         AND card_id = '73d87611-651a-4318-a0ae-5e83446dd762'
         AND quantity = 4
     ) THEN
    RAISE EXCEPTION 'PG870 rollback did not restore the exact pre-state';
  END IF;
END
$$;

COMMIT;
