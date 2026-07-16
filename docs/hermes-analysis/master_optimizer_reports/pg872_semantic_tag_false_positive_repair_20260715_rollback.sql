-- MUTATING. Requires explicit PostgreSQL approval for this execution.
BEGIN;

LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;

DO $$
DECLARE
  v_semantic bigint;
  v_function bigint;
BEGIN
  IF to_regclass(
    'manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715'
  ) IS NULL OR to_regclass(
    'manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715'
  ) IS NULL THEN
    RAISE EXCEPTION 'PG872 rollback abort: audit snapshot is missing';
  END IF;
  SELECT count(*) INTO v_semantic
  FROM manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715;
  SELECT count(*) INTO v_function
  FROM manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715;
  IF v_semantic <> 2 OR v_function <> 1 THEN
    RAISE EXCEPTION 'PG872 rollback abort: semantic=% function=%',
      v_semantic, v_function;
  END IF;
END $$;

DELETE FROM public.card_semantic_tags_v2 current
USING manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715 snapshot
WHERE current.card_id = snapshot.card_id
  AND current.source = snapshot.source;

INSERT INTO public.card_semantic_tags_v2 (
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine,
  payoff, enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
)
SELECT
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine,
  payoff, enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
FROM manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715;

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715;

COMMIT;
