BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('centaur veteran', 'deepwood ghoul', 'marrow bats', 'mischievous poltergeist', 'sentry of the underworld', 'tunneler wurm')
   OR normalized_name LIKE 'centaur veteran // %'
   OR normalized_name LIKE 'deepwood ghoul // %'
   OR normalized_name LIKE 'marrow bats // %'
   OR normalized_name LIKE 'mischievous poltergeist // %'
   OR normalized_name LIKE 'sentry of the underworld // %'
   OR normalized_name LIKE 'tunneler wurm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg722_regenerate_costs_new_server_regene_20260710_212650;

COMMIT;
