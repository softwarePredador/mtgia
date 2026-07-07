BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gnarlwood dryad', 'moldgraf scavenger')
   OR normalized_name LIKE 'gnarlwood dryad // %'
   OR normalized_name LIKE 'moldgraf scavenger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg636_delirium_threshold_boost_new_serve_20260707_201340;

COMMIT;
