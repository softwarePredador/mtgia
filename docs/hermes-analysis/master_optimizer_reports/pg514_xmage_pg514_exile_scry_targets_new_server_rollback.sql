BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('devout decree', 'ray of ruin')
   OR normalized_name LIKE 'devout decree // %'
   OR normalized_name LIKE 'ray of ruin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg514_xmage_pg514_exile_scry_targets_new_20260705_152330;

COMMIT;
