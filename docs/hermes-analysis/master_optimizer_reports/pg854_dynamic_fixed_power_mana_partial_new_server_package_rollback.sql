BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cradle clearcutter', 'marwyn, the nurturer', 'rainveil rejuvenator', 'topiary lecturer')
   OR normalized_name LIKE 'cradle clearcutter // %'
   OR normalized_name LIKE 'marwyn, the nurturer // %'
   OR normalized_name LIKE 'rainveil rejuvenator // %'
   OR normalized_name LIKE 'topiary lecturer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg854_dynamic_fixed_power_mana_partial_n_20260713_005518;

COMMIT;
