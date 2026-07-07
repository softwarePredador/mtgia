BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('earthblighter', 'keldon arsonist', 'krark-clan engineers', 'sandstone deadfall')
   OR normalized_name LIKE 'earthblighter // %'
   OR normalized_name LIKE 'keldon arsonist // %'
   OR normalized_name LIKE 'krark-clan engineers // %'
   OR normalized_name LIKE 'sandstone deadfall // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg629_activated_destroy_multi_sacrifice_20260707_180019;

COMMIT;
