BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brittle effigy', 'catapult master', 'devout chaplain', 'lawbringer', 'lieutenant kirtar', 'lightbringer', 'silverchase fox', 'soul snare', 'undead slayer')
   OR normalized_name LIKE 'brittle effigy // %'
   OR normalized_name LIKE 'catapult master // %'
   OR normalized_name LIKE 'devout chaplain // %'
   OR normalized_name LIKE 'lawbringer // %'
   OR normalized_name LIKE 'lieutenant kirtar // %'
   OR normalized_name LIKE 'lightbringer // %'
   OR normalized_name LIKE 'silverchase fox // %'
   OR normalized_name LIKE 'soul snare // %'
   OR normalized_name LIKE 'undead slayer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg809_activated_exile_target_new_server_20260712_060810;

COMMIT;
