BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bloodline necromancer', 'quarry beetle', 'sharuum the hegemon')
   OR normalized_name LIKE 'bloodline necromancer // %'
   OR normalized_name LIKE 'quarry beetle // %'
   OR normalized_name LIKE 'sharuum the hegemon // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg409_etb_recursion_battlefield_new_server_etb_recursion;

COMMIT;
