BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akoum boulderfoot', 'blisterstick shaman', 'corrupt eunuchs', 'fire imp', 'flametongue kavu', 'goblin commando', 'skeleton archer', 'sparkmage apprentice')
   OR normalized_name LIKE 'akoum boulderfoot // %'
   OR normalized_name LIKE 'blisterstick shaman // %'
   OR normalized_name LIKE 'corrupt eunuchs // %'
   OR normalized_name LIKE 'fire imp // %'
   OR normalized_name LIKE 'flametongue kavu // %'
   OR normalized_name LIKE 'goblin commando // %'
   OR normalized_name LIKE 'skeleton archer // %'
   OR normalized_name LIKE 'sparkmage apprentice // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg302_xmage_creature_etb_damage_wave_20260701_114851;

COMMIT;
