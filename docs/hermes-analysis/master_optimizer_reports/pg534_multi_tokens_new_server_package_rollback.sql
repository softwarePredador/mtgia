BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bestial menace', 'forbidden friendship', 'mascot exhibition')
   OR normalized_name LIKE 'bestial menace // %'
   OR normalized_name LIKE 'forbidden friendship // %'
   OR normalized_name LIKE 'mascot exhibition // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg534_multi_tokens_new_server_20260705_223815;

COMMIT;
