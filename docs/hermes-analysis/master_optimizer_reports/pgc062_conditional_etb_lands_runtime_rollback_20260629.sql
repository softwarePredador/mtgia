BEGIN;

DELETE FROM public.card_battle_rules
WHERE logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
  AND normalized_name IN ('clifftop retreat', 'inspiring vantage', 'sundown pass');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc062_conditional_etb_lands_runtime_20260629;

COMMIT;
