BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('all that glitters', 'ancestral mask', 'blackblade reforged', 'blessing of the nephilim', 'civic saber', 'empyrial armor', 'empyrial plate', 'glaive of the guildpact', 'golem-skin gauntlets', 'granite grip', 'helm of the gods', 'kagemaro''s clutch', 'manaforce mace', 'nightmare lash', 'pennon blade', 'quag sickness', 'ravager''s mace')
   OR normalized_name LIKE 'all that glitters // %'
   OR normalized_name LIKE 'ancestral mask // %'
   OR normalized_name LIKE 'blackblade reforged // %'
   OR normalized_name LIKE 'blessing of the nephilim // %'
   OR normalized_name LIKE 'civic saber // %'
   OR normalized_name LIKE 'empyrial armor // %'
   OR normalized_name LIKE 'empyrial plate // %'
   OR normalized_name LIKE 'glaive of the guildpact // %'
   OR normalized_name LIKE 'golem-skin gauntlets // %'
   OR normalized_name LIKE 'granite grip // %'
   OR normalized_name LIKE 'helm of the gods // %'
   OR normalized_name LIKE 'kagemaro''s clutch // %'
   OR normalized_name LIKE 'manaforce mace // %'
   OR normalized_name LIKE 'nightmare lash // %'
   OR normalized_name LIKE 'pennon blade // %'
   OR normalized_name LIKE 'quag sickness // %'
   OR normalized_name LIKE 'ravager''s mace // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg802_dynamic_attachment_static_pt_new_s_20260712_025740;

COMMIT;
