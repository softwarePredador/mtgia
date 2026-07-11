BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('shower of arrows')
   OR normalized_name LIKE 'shower of arrows // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg779_shower_of_arrows_destroy_scry_new_20260711_175339;

COMMIT;
