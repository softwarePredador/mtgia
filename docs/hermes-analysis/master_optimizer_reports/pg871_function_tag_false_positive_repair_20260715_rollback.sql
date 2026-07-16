-- MUTATING. Requires explicit PostgreSQL approval for this execution.
BEGIN;

LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;

DO $$
DECLARE
  v_snapshot_rows bigint;
  v_conflicts bigint;
BEGIN
  IF to_regclass(
    'manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715'
  ) IS NULL THEN
    RAISE EXCEPTION 'PG871 rollback abort: audit snapshot is missing';
  END IF;

  SELECT count(*)
  INTO v_snapshot_rows
  FROM manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715;

  SELECT count(*)
  INTO v_conflicts
  FROM public.card_function_tags current
  JOIN manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715 snapshot
    ON snapshot.card_id = current.card_id
   AND snapshot.tag = current.tag
   AND snapshot.source = current.source;

  IF v_snapshot_rows <> 5 OR v_conflicts <> 0 THEN
    RAISE EXCEPTION
      'PG871 rollback abort: snapshot=% conflicts=%',
      v_snapshot_rows, v_conflicts;
  END IF;
END $$;

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715;

DO $$
DECLARE
  v_restored bigint;
BEGIN
  SELECT count(*)
  INTO v_restored
  FROM public.card_function_tags current
  JOIN manaloom_deploy_audit.pg871_function_tag_false_positive_repair_20260715 snapshot
    ON snapshot.card_id = current.card_id
   AND snapshot.tag = current.tag
   AND snapshot.source = current.source;

  IF v_restored <> 5 THEN
    RAISE EXCEPTION 'PG871 rollback abort: restored=%', v_restored;
  END IF;
END $$;

COMMIT;
