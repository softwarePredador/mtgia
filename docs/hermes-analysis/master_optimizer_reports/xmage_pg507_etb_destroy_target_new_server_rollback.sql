BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('angel of despair', 'dark hatchling')
   OR normalized_name LIKE 'angel of despair // %'
   OR normalized_name LIKE 'dark hatchling // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg507_xmage_pg507_etb_destroy_target_new_20260705_130246;

COMMIT;
