BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('galvanic bombardment', 'ire of kaminari', 'kindle', 'scrapyard salvo')
   OR normalized_name LIKE 'galvanic bombardment // %'
   OR normalized_name LIKE 'ire of kaminari // %'
   OR normalized_name LIKE 'kindle // %'
   OR normalized_name LIKE 'scrapyard salvo // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg401_dynamic_graveyard_damage_new_server_20260704_11040;

COMMIT;
