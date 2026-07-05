BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('contract killing', 'crack open', 'grim bounty')
   OR normalized_name LIKE 'contract killing // %'
   OR normalized_name LIKE 'crack open // %'
   OR normalized_name LIKE 'grim bounty // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg533_destroy_treasure_new_server_20260705_221743;

COMMIT;
