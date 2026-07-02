BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('divergent equation', 'wildest dreams')
   OR normalized_name LIKE 'divergent equation // %'
   OR normalized_name LIKE 'wildest dreams // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg363_recursion_x_exile_self_wave_20260702_080905;

COMMIT;
