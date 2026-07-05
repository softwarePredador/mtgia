BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cower in fear', 'hell swarm', 'hysterical blindness', 'infest', 'languish', 'magnify', 'marsh gas', 'nausea', 'rollick of abandon', 'shrivel')
   OR normalized_name LIKE 'cower in fear // %'
   OR normalized_name LIKE 'hell swarm // %'
   OR normalized_name LIKE 'hysterical blindness // %'
   OR normalized_name LIKE 'infest // %'
   OR normalized_name LIKE 'languish // %'
   OR normalized_name LIKE 'magnify // %'
   OR normalized_name LIKE 'marsh gas // %'
   OR normalized_name LIKE 'nausea // %'
   OR normalized_name LIKE 'rollick of abandon // %'
   OR normalized_name LIKE 'shrivel // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg526_boost_all_new_server_20260705_194024;

COMMIT;
