-- READ ONLY. PG871 postcheck.
BEGIN TRANSACTION READ ONLY;

DO $$
DECLARE
  v_remaining bigint;
  v_snapshot_rows bigint;
  v_required_roles bigint;
BEGIN
  SELECT count(*)
  INTO v_remaining
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

  SELECT count(*)
  INTO v_snapshot_rows
  FROM manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715;

  SELECT count(*)
  INTO v_required_roles
  FROM public.cards c
  JOIN public.card_function_tags cft ON cft.card_id = c.id
  WHERE (lower(c.name) = 'bloodstained mire' AND cft.tag = 'land')
     OR (lower(c.name) = 'lotus petal' AND cft.tag IN ('ramp', 'mana_fixing'));

  IF v_remaining <> 0 OR v_snapshot_rows <> 5 OR v_required_roles < 4 THEN
    RAISE EXCEPTION
      'PG871 postcheck abort: remaining=% snapshot=% required_roles=%',
      v_remaining, v_snapshot_rows, v_required_roles;
  END IF;
END $$;

SELECT c.name, array_agg(DISTINCT cft.tag ORDER BY cft.tag) AS remaining_tags
FROM public.cards c
JOIN public.card_function_tags cft ON cft.card_id = c.id
WHERE lower(c.name) IN ('bloodstained mire', 'lotus petal')
GROUP BY c.name
ORDER BY c.name;

ROLLBACK;
