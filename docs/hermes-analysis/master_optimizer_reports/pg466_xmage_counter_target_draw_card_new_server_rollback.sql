BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bone to ash', 'contradict', 'dismiss', 'exclude', 'halt order', 'scatter arc')
   OR normalized_name LIKE 'bone to ash // %'
   OR normalized_name LIKE 'contradict // %'
   OR normalized_name LIKE 'dismiss // %'
   OR normalized_name LIKE 'exclude // %'
   OR normalized_name LIKE 'halt order // %'
   OR normalized_name LIKE 'scatter arc // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg466_xmage_counter_target_draw_card_new_server_20260705;

COMMIT;
