BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goblin wizardry')
   OR normalized_name LIKE 'goblin wizardry // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg545_token_prowess_new_server_pg545_tok_20260706_030802;

COMMIT;
