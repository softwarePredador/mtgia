BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('baneslayer angel', 'dragonstalker', 'elite inquisitor', 'grave bramble', 'kitsune riftwalker', 'midnight duelist', 'nath''s buffoon', 'shoreline raider')
   OR normalized_name LIKE 'baneslayer angel // %'
   OR normalized_name LIKE 'dragonstalker // %'
   OR normalized_name LIKE 'elite inquisitor // %'
   OR normalized_name LIKE 'grave bramble // %'
   OR normalized_name LIKE 'kitsune riftwalker // %'
   OR normalized_name LIKE 'midnight duelist // %'
   OR normalized_name LIKE 'nath''s buffoon // %'
   OR normalized_name LIKE 'shoreline raider // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg462_xmage_static_self_protection_subtypes_new_server_2;

COMMIT;
