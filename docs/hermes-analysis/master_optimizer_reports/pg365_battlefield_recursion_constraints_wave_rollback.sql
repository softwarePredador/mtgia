BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('othelm, sigardian outcast', 'ramosian revivalist', 'rise to glory', 'squirming emergence')
   OR normalized_name LIKE 'othelm, sigardian outcast // %'
   OR normalized_name LIKE 'ramosian revivalist // %'
   OR normalized_name LIKE 'rise to glory // %'
   OR normalized_name LIKE 'squirming emergence // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg365_battlefield_recursion_constraints_wave_20260702_08;

COMMIT;
