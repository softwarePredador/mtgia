BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('servo exhibition', 'shadow summoning')
   OR normalized_name LIKE 'servo exhibition // %'
   OR normalized_name LIKE 'shadow summoning // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg535_fixed_tapped_tokens_new_server_pg5_20260705_230150;

COMMIT;
