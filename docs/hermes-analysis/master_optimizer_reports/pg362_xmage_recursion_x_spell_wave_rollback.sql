BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('back in town', 'death denied', 'stir the grave')
   OR normalized_name LIKE 'back in town // %'
   OR normalized_name LIKE 'death denied // %'
   OR normalized_name LIKE 'stir the grave // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg362_xmage_recursion_x_spell_wave_20260702_075031;

COMMIT;
