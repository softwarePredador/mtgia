BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goblin scouts')
   OR normalized_name LIKE 'goblin scouts // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg501_token_basic_landwalk_new_ser_20260705_105116;

COMMIT;
