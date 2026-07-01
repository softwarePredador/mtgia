BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('false mourning', 'reclaim', 'reinforcements', 'salvage')
   OR normalized_name LIKE 'false mourning // %'
   OR normalized_name LIKE 'reclaim // %'
   OR normalized_name LIKE 'reinforcements // %'
   OR normalized_name LIKE 'salvage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg334_xmage_graveyard_to_library_spell_wave_xmage_gravey;

COMMIT;
