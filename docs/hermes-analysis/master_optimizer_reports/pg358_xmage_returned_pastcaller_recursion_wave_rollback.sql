BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('returned pastcaller')
   OR normalized_name LIKE 'returned pastcaller // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg358_xmage_returned_pastcaller_recursion_wave_20260702_;

COMMIT;
