BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('culling the weak', 'infernal plunge')
   OR normalized_name LIKE 'culling the weak // %'
   OR normalized_name LIKE 'infernal plunge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg159_creature_sac_rituals_20260624_090942;

COMMIT;
