BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('amulet of vigor', 'exploration', 'ghostly flicker', 'grasp of fate')
   OR normalized_name LIKE 'amulet of vigor // %'
   OR normalized_name LIKE 'exploration // %'
   OR normalized_name LIKE 'ghostly flicker // %'
   OR normalized_name LIKE 'grasp of fate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg599_runtime_closure_new_server_package_20260715_150619;

COMMIT;
