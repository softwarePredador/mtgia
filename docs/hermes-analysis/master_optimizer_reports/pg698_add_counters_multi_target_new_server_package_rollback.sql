BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gird for battle', 'leo''s guidance', 'reap what is sown')
   OR normalized_name LIKE 'gird for battle // %'
   OR normalized_name LIKE 'leo''s guidance // %'
   OR normalized_name LIKE 'reap what is sown // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg698_add_counters_multi_target_new_serv_20260709_071744;

COMMIT;
