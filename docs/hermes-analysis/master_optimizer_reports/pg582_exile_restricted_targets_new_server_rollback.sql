BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('complete disregard', 'exorcise', 'glare of heresy', 'gravkill', 'grotesque demise', 'oblivion strike', 'pillar of light', 'radiant purge', 'reaver ambush')
   OR normalized_name LIKE 'complete disregard // %'
   OR normalized_name LIKE 'exorcise // %'
   OR normalized_name LIKE 'glare of heresy // %'
   OR normalized_name LIKE 'gravkill // %'
   OR normalized_name LIKE 'grotesque demise // %'
   OR normalized_name LIKE 'oblivion strike // %'
   OR normalized_name LIKE 'pillar of light // %'
   OR normalized_name LIKE 'radiant purge // %'
   OR normalized_name LIKE 'reaver ambush // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg582_exile_restricted_targets_new_serve_20260707_001645;

COMMIT;
