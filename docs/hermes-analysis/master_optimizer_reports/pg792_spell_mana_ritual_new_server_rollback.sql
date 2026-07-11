BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('battle hymn', 'channel the suns', 'inner fire', 'songs of the damned')
   OR normalized_name LIKE 'battle hymn // %'
   OR normalized_name LIKE 'channel the suns // %'
   OR normalized_name LIKE 'inner fire // %'
   OR normalized_name LIKE 'songs of the damned // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg792_spell_mana_ritual_20260711_225729;

COMMIT;
