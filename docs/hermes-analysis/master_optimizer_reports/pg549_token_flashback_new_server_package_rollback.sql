BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('army of the damned', 'beast attack', 'call of the herd', 'chatter of the squirrel', 'crush of wurms', 'elephant ambush', 'join the dance', 'lingering souls', 'moan of the unhallowed', 'reap the seagraf', 'roar of the wurm', 'shadowbeast sighting')
   OR normalized_name LIKE 'army of the damned // %'
   OR normalized_name LIKE 'beast attack // %'
   OR normalized_name LIKE 'call of the herd // %'
   OR normalized_name LIKE 'chatter of the squirrel // %'
   OR normalized_name LIKE 'crush of wurms // %'
   OR normalized_name LIKE 'elephant ambush // %'
   OR normalized_name LIKE 'join the dance // %'
   OR normalized_name LIKE 'lingering souls // %'
   OR normalized_name LIKE 'moan of the unhallowed // %'
   OR normalized_name LIKE 'reap the seagraf // %'
   OR normalized_name LIKE 'roar of the wurm // %'
   OR normalized_name LIKE 'shadowbeast sighting // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg549_token_flashback_new_server_token_f_20260706_041844;

COMMIT;
