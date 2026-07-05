BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ceremonious rejection', 'disdainful stroke', 'flashfreeze', 'frazzle', 'guttural response', 'hisoka''s defiance', 'minor misstep', 'mystic denial', 'neutralizing blast', 'nullify', 'spell snare', 'thoughtbind')
   OR normalized_name LIKE 'ceremonious rejection // %'
   OR normalized_name LIKE 'disdainful stroke // %'
   OR normalized_name LIKE 'flashfreeze // %'
   OR normalized_name LIKE 'frazzle // %'
   OR normalized_name LIKE 'guttural response // %'
   OR normalized_name LIKE 'hisoka''s defiance // %'
   OR normalized_name LIKE 'minor misstep // %'
   OR normalized_name LIKE 'mystic denial // %'
   OR normalized_name LIKE 'neutralizing blast // %'
   OR normalized_name LIKE 'nullify // %'
   OR normalized_name LIKE 'spell snare // %'
   OR normalized_name LIKE 'thoughtbind // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg488_counter_target_filters_new_server_20260705_065524;

COMMIT;
