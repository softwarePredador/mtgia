BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cyclops electromancer', 'lotleth giant', 'ossuary rats', 'warfire javelineer')
   OR normalized_name LIKE 'cyclops electromancer // %'
   OR normalized_name LIKE 'lotleth giant // %'
   OR normalized_name LIKE 'ossuary rats // %'
   OR normalized_name LIKE 'warfire javelineer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg470_xmage_creature_etb_dynamic_graveyard_damage_new_se;

COMMIT;
