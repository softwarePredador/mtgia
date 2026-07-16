-- MUTATING. Requires explicit PostgreSQL approval for this execution.
BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF to_regclass(
    'manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715'
  ) IS NOT NULL THEN
    RAISE EXCEPTION 'PG871 abort: audit snapshot already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715 AS
SELECT cft.*
FROM public.cards c
JOIN public.card_function_tags cft ON cft.card_id = c.id
WHERE (
    lower(c.name) = 'bloodstained mire'
    AND md5(coalesce(c.oracle_text, '')) = 'c2b1d722530ed12d78dbc0993c3392fe'
    AND cft.tag = 'ramp'
    AND cft.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
  ) OR (
    lower(c.name) = 'lotus petal'
    AND md5(coalesce(c.oracle_text, '')) = 'a5b9069217908acfd75c5704b414b035'
    AND cft.tag IN ('sacrifice', 'sacrifice_outlet')
    AND cft.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
  );

DO $$
DECLARE
  v_rows bigint;
  v_cards bigint;
BEGIN
  SELECT count(*), count(DISTINCT card_id)
  INTO v_rows, v_cards
  FROM manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715;

  IF v_rows <> 5 OR v_cards <> 2 THEN
    RAISE EXCEPTION 'PG871 abort: snapshot rows=% cards=%', v_rows, v_cards;
  END IF;
END $$;

DELETE FROM public.card_function_tags current
USING manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715 snapshot
WHERE current.card_id = snapshot.card_id
  AND current.tag = snapshot.tag
  AND current.source = snapshot.source;

DO $$
DECLARE
  v_remaining bigint;
BEGIN
  SELECT count(*)
  INTO v_remaining
  FROM public.card_function_tags current
  JOIN manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715 snapshot
    ON snapshot.card_id = current.card_id
   AND snapshot.tag = current.tag
   AND snapshot.source = current.source;

  IF v_remaining <> 0 THEN
    RAISE EXCEPTION 'PG871 abort: % target rows remain', v_remaining;
  END IF;
END $$;

COMMIT;
