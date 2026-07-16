-- READ ONLY. PG871 precheck for five deterministic false-positive tags.
BEGIN TRANSACTION READ ONLY;

DO $$
DECLARE
  v_cards bigint;
  v_rows bigint;
  v_hash_mismatches bigint;
BEGIN
  SELECT
    count(DISTINCT c.id),
    count(*),
    count(*) FILTER (
      WHERE (lower(c.name) = 'bloodstained mire'
             AND md5(coalesce(c.oracle_text, '')) <> 'c2b1d722530ed12d78dbc0993c3392fe')
         OR (lower(c.name) = 'lotus petal'
             AND md5(coalesce(c.oracle_text, '')) <> 'a5b9069217908acfd75c5704b414b035')
    )
  INTO v_cards, v_rows, v_hash_mismatches
  FROM public.cards c
  JOIN public.card_function_tags cft ON cft.card_id = c.id
  WHERE (
      lower(c.name) = 'bloodstained mire'
      AND cft.tag = 'ramp'
      AND cft.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
    ) OR (
      lower(c.name) = 'lotus petal'
      AND cft.tag IN ('sacrifice', 'sacrifice_outlet')
      AND cft.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
    );

  IF v_cards <> 2 OR v_rows <> 5 OR v_hash_mismatches <> 0 THEN
    RAISE EXCEPTION
      'PG871 precheck abort: cards=% rows=% hash_mismatches=%',
      v_cards, v_rows, v_hash_mismatches;
  END IF;
END $$;

SELECT c.name, cft.tag, cft.source, cft.confidence, cft.evidence
FROM public.cards c
JOIN public.card_function_tags cft ON cft.card_id = c.id
WHERE (
    lower(c.name) = 'bloodstained mire'
    AND cft.tag = 'ramp'
    AND cft.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
  ) OR (
    lower(c.name) = 'lotus petal'
    AND cft.tag IN ('sacrifice', 'sacrifice_outlet')
    AND cft.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
  )
ORDER BY c.name, cft.tag, cft.source;

ROLLBACK;
