BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ticket tortoise')
   OR normalized_name LIKE 'ticket tortoise // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg537_etb_treasure_condition_new_server_20260705_235035;

COMMIT;
