BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bloom tender', 'circle of dreams druid', 'ignoble hierarch', 'springleaf drum', 'noble hierarch', 'relic of legends', 'talisman of indulgence', 'moonsnare prototype')
   OR normalized_name LIKE 'bloom tender // %'
   OR normalized_name LIKE 'circle of dreams druid // %'
   OR normalized_name LIKE 'ignoble hierarch // %'
   OR normalized_name LIKE 'springleaf drum // %'
   OR normalized_name LIKE 'noble hierarch // %'
   OR normalized_name LIKE 'relic of legends // %'
   OR normalized_name LIKE 'talisman of indulgence // %'
   OR normalized_name LIKE 'moonsnare prototype // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg180_residual_mana_accelerants_20260624_140714;

COMMIT;
