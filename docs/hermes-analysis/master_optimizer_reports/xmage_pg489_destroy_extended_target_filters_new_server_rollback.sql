BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cast down', 'chill to the bone', 'eyeblight''s ending', 'goblin digging team', 'human frailty', 'power word kill', 'puncturing light', 'rend flesh', 'rend spirit', 'searing light', 'terashi''s verdict', 'tunnel', 'urgent exorcism', 'victim of night', 'walk the plank')
   OR normalized_name LIKE 'cast down // %'
   OR normalized_name LIKE 'chill to the bone // %'
   OR normalized_name LIKE 'eyeblight''s ending // %'
   OR normalized_name LIKE 'goblin digging team // %'
   OR normalized_name LIKE 'human frailty // %'
   OR normalized_name LIKE 'power word kill // %'
   OR normalized_name LIKE 'puncturing light // %'
   OR normalized_name LIKE 'rend flesh // %'
   OR normalized_name LIKE 'rend spirit // %'
   OR normalized_name LIKE 'searing light // %'
   OR normalized_name LIKE 'terashi''s verdict // %'
   OR normalized_name LIKE 'tunnel // %'
   OR normalized_name LIKE 'urgent exorcism // %'
   OR normalized_name LIKE 'victim of night // %'
   OR normalized_name LIKE 'walk the plank // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg489_destroy_extended_target_filters_ne_20260705_071656;

COMMIT;
