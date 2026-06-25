BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deflecting palm')
   OR normalized_name LIKE 'deflecting palm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg201_deflecting_palm_20260625_032628;

COMMIT;
