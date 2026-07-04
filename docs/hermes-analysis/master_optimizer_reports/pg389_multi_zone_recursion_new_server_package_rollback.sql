BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('badlands revival', 'pull through the weft')
   OR normalized_name LIKE 'badlands revival // %'
   OR normalized_name LIKE 'pull through the weft // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg389_multi_zone_recursion_new_server_20260704_pg389_mul;

COMMIT;
