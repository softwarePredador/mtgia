BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abzan banner', 'azorius cluestone', 'boros cluestone', 'dimir cluestone', 'golgari cluestone', 'gruul cluestone', 'heart warden', 'izzet cluestone', 'jeskai banner', 'letter of acceptance', 'mardu banner', 'orzhov cluestone', 'rakdos cluestone', 'selesnya cluestone', 'simic cluestone', 'sultai banner', 'temur banner')
   OR normalized_name LIKE 'abzan banner // %'
   OR normalized_name LIKE 'azorius cluestone // %'
   OR normalized_name LIKE 'boros cluestone // %'
   OR normalized_name LIKE 'dimir cluestone // %'
   OR normalized_name LIKE 'golgari cluestone // %'
   OR normalized_name LIKE 'gruul cluestone // %'
   OR normalized_name LIKE 'heart warden // %'
   OR normalized_name LIKE 'izzet cluestone // %'
   OR normalized_name LIKE 'jeskai banner // %'
   OR normalized_name LIKE 'letter of acceptance // %'
   OR normalized_name LIKE 'mardu banner // %'
   OR normalized_name LIKE 'orzhov cluestone // %'
   OR normalized_name LIKE 'rakdos cluestone // %'
   OR normalized_name LIKE 'selesnya cluestone // %'
   OR normalized_name LIKE 'simic cluestone // %'
   OR normalized_name LIKE 'sultai banner // %'
   OR normalized_name LIKE 'temur banner // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg443_xmage_mana_source_activated_draw_new_server_202607;

COMMIT;
