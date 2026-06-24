BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('invoke calamity')
   OR normalized_name LIKE 'invoke calamity // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg191_invoke_calamity_free_cast_20260624_215739;

COMMIT;
