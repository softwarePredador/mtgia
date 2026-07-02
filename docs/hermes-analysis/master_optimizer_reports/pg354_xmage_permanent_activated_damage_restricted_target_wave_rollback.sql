BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('centaur archer', 'chandra''s magmutt', 'crossbow infantry', 'd''avenant archer', 'duergar assailant', 'elite archers', 'expendable troops', 'flamewave invoker', 'font of ire', 'goblin fireslinger', 'grapeshot catapult', 'heavy ballista', 'lady caleria', 'sacellum archers', 'scalding devil', 'soldier replica', 'telim''tor''s darts', 'tor wauki', 'viridian scout', 'volcanic rambler', 'vulshok replica', 'war-torch goblin')
   OR normalized_name LIKE 'centaur archer // %'
   OR normalized_name LIKE 'chandra''s magmutt // %'
   OR normalized_name LIKE 'crossbow infantry // %'
   OR normalized_name LIKE 'd''avenant archer // %'
   OR normalized_name LIKE 'duergar assailant // %'
   OR normalized_name LIKE 'elite archers // %'
   OR normalized_name LIKE 'expendable troops // %'
   OR normalized_name LIKE 'flamewave invoker // %'
   OR normalized_name LIKE 'font of ire // %'
   OR normalized_name LIKE 'goblin fireslinger // %'
   OR normalized_name LIKE 'grapeshot catapult // %'
   OR normalized_name LIKE 'heavy ballista // %'
   OR normalized_name LIKE 'lady caleria // %'
   OR normalized_name LIKE 'sacellum archers // %'
   OR normalized_name LIKE 'scalding devil // %'
   OR normalized_name LIKE 'soldier replica // %'
   OR normalized_name LIKE 'telim''tor''s darts // %'
   OR normalized_name LIKE 'tor wauki // %'
   OR normalized_name LIKE 'viridian scout // %'
   OR normalized_name LIKE 'volcanic rambler // %'
   OR normalized_name LIKE 'vulshok replica // %'
   OR normalized_name LIKE 'war-torch goblin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg354_xmage_permanent_activated_damage_restricted_target;

COMMIT;
