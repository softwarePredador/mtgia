BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goblin offensive', 'secure the wastes')
   OR normalized_name LIKE 'goblin offensive // %'
   OR normalized_name LIKE 'secure the wastes // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg521_x_create_tokens_new_server_p_20260705_180221;

COMMIT;
