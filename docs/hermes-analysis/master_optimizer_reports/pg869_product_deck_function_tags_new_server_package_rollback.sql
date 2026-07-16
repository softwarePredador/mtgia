-- MUTATING. Do not run without explicit PostgreSQL approval for this execution.
BEGIN;

LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;

DO $$
DECLARE
  v_snapshot_rows bigint;
  v_rows bigint;
  v_cards bigint;
  v_names bigint;
  v_mismatches bigint;
BEGIN
  IF to_regclass(
    'manaloom_deploy_audit.pg869_product_deck_function_tags_20260715'
  ) IS NULL THEN
    RAISE EXCEPTION 'PG869 rollback abort: audit snapshot is missing';
  END IF;

  SELECT count(*)
  INTO v_snapshot_rows
  FROM manaloom_deploy_audit.pg869_product_deck_function_tags_20260715;

  SELECT
    count(*),
    count(DISTINCT card_id),
    count(DISTINCT lower(card_name)),
    count(*) FILTER (
      WHERE confidence <> 0.95
         OR evidence <> 'Oracle family reviewed against current product-deck role coverage; runtime classifier and focused regression matrix validated 2026-07-15.'
    )
  INTO v_rows, v_cards, v_names, v_mismatches
  FROM public.card_function_tags
  WHERE source = 'curated_product_deck_families_20260715';

  IF v_snapshot_rows <> 0
     OR v_rows <> 46
     OR v_cards <> 35
     OR v_names <> 26
     OR v_mismatches <> 0 THEN
    RAISE EXCEPTION
      'PG869 rollback abort: snapshot=% rows=% cards=% names=% mismatches=%',
      v_snapshot_rows,
      v_rows,
      v_cards,
      v_names,
      v_mismatches;
  END IF;
END $$;

DELETE FROM public.card_function_tags
WHERE source = 'curated_product_deck_families_20260715';

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg869_product_deck_function_tags_20260715
ON CONFLICT (card_id, tag, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = EXCLUDED.updated_at;

COMMIT;
