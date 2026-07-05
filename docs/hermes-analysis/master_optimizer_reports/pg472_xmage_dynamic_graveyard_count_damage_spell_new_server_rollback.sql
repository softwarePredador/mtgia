BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('galvanic bombardment', 'ire of kaminari', 'kindle', 'scrapyard salvo')
   OR normalized_name LIKE 'galvanic bombardment // %'
   OR normalized_name LIKE 'ire of kaminari // %'
   OR normalized_name LIKE 'kindle // %'
   OR normalized_name LIKE 'scrapyard salvo // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg472_xmage_dynamic_graveyard_count_damage_spell_new_ser;

COMMIT;
