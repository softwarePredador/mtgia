BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('prodigal pyromancer', 'prodigal sorcerer', 'razorfin hunter', 'rootwater hunter', 'viashino fangtail', 'zuran spellcaster')
   OR normalized_name LIKE 'prodigal pyromancer // %'
   OR normalized_name LIKE 'prodigal sorcerer // %'
   OR normalized_name LIKE 'razorfin hunter // %'
   OR normalized_name LIKE 'rootwater hunter // %'
   OR normalized_name LIKE 'viashino fangtail // %'
   OR normalized_name LIKE 'zuran spellcaster // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg296_xmage_creature_tap_damage_wave_20260701_103016;

COMMIT;
