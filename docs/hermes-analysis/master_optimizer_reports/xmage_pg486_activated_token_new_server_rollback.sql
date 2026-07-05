BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boris devilboon', 'centaur glade', 'centaur''s herald', 'dragon roost', 'envoy of okinec ahau', 'jade mage', 'nuisance engine', 'renowned weaver', 'sliver queen', 'whirlermaker')
   OR normalized_name LIKE 'boris devilboon // %'
   OR normalized_name LIKE 'centaur glade // %'
   OR normalized_name LIKE 'centaur''s herald // %'
   OR normalized_name LIKE 'dragon roost // %'
   OR normalized_name LIKE 'envoy of okinec ahau // %'
   OR normalized_name LIKE 'jade mage // %'
   OR normalized_name LIKE 'nuisance engine // %'
   OR normalized_name LIKE 'renowned weaver // %'
   OR normalized_name LIKE 'sliver queen // %'
   OR normalized_name LIKE 'whirlermaker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg486_activated_token_new_server_20260705_061820;

COMMIT;
