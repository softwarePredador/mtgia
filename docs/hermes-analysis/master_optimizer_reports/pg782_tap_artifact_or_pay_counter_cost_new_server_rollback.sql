BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('disruption protocol')
   OR normalized_name LIKE 'disruption protocol // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg782_pg782_tap_artifact_or_pay_counter_20260711_190137;

COMMIT;
