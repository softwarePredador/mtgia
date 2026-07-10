BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bog witch', 'bramble familiar // fetch quest', 'izzet keyrune', 'network terminal', 'skirge familiar', 'starting column')
   OR normalized_name LIKE 'bog witch // %'
   OR normalized_name LIKE 'bramble familiar // fetch quest // %'
   OR normalized_name LIKE 'izzet keyrune // %'
   OR normalized_name LIKE 'network terminal // %'
   OR normalized_name LIKE 'skirge familiar // %'
   OR normalized_name LIKE 'starting column // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg723_mana_source_discard_costs_new_serv_20260710_220014;

COMMIT;
