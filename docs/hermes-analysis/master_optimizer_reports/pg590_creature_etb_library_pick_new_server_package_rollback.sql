BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('augur of bolas', 'courageous outrider', 'eclipsed boggart', 'eclipsed elf', 'eclipsed flamekin', 'eclipsed kithkin', 'eclipsed merrow', 'sea gate oracle', 'skalla wolf', 'staunch crewmate', 'sumala woodshaper')
   OR normalized_name LIKE 'augur of bolas // %'
   OR normalized_name LIKE 'courageous outrider // %'
   OR normalized_name LIKE 'eclipsed boggart // %'
   OR normalized_name LIKE 'eclipsed elf // %'
   OR normalized_name LIKE 'eclipsed flamekin // %'
   OR normalized_name LIKE 'eclipsed kithkin // %'
   OR normalized_name LIKE 'eclipsed merrow // %'
   OR normalized_name LIKE 'sea gate oracle // %'
   OR normalized_name LIKE 'skalla wolf // %'
   OR normalized_name LIKE 'staunch crewmate // %'
   OR normalized_name LIKE 'sumala woodshaper // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg590_creature_etb_library_pick_new_serv_20260707_034004;

COMMIT;
