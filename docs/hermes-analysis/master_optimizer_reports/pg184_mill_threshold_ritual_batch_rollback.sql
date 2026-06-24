BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brain freeze', 'cabal ritual')
   OR normalized_name LIKE 'brain freeze // %'
   OR normalized_name LIKE 'cabal ritual // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg184_mill_threshold_ritual_batch_20260624_192504;

COMMIT;
