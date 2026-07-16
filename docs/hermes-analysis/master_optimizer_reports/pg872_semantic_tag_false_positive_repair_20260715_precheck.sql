-- READ ONLY. PG872 semantic-v2 convergence after deterministic classifier repair.
BEGIN TRANSACTION READ ONLY;

DO $$
DECLARE
  v_semantic_rows bigint;
  v_enabler_rows bigint;
  v_hash_mismatches bigint;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (
      WHERE (lower(c.name) = 'bloodstained mire'
             AND md5(coalesce(c.oracle_text, '')) <> 'c2b1d722530ed12d78dbc0993c3392fe')
         OR (lower(c.name) = 'lotus petal'
             AND md5(coalesce(c.oracle_text, '')) <> 'a5b9069217908acfd75c5704b414b035')
    )
  INTO v_semantic_rows, v_hash_mismatches
  FROM public.cards c
  JOIN public.card_semantic_tags_v2 s ON s.card_id = c.id
  WHERE lower(c.name) IN ('bloodstained mire', 'lotus petal')
    AND s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18';

  SELECT count(*)
  INTO v_enabler_rows
  FROM public.cards c
  JOIN public.card_function_tags f ON f.card_id = c.id
  WHERE lower(c.name) = 'bloodstained mire'
    AND f.tag = 'enabler'
    AND f.source = 'deterministic_semantic_v2';

  IF v_semantic_rows <> 2 OR v_enabler_rows <> 1 OR v_hash_mismatches <> 0 THEN
    RAISE EXCEPTION
      'PG872 precheck abort: semantic=% enabler=% hash_mismatches=%',
      v_semantic_rows, v_enabler_rows, v_hash_mismatches;
  END IF;
END $$;

SELECT c.name, s.tags, s.enabler, s.role_confidence, s.explanation_reason
FROM public.cards c
JOIN public.card_semantic_tags_v2 s ON s.card_id = c.id
WHERE lower(c.name) IN ('bloodstained mire', 'lotus petal')
  AND s.source = 'deterministic_semantic_v2'
ORDER BY c.name;

ROLLBACK;
