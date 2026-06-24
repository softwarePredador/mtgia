BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('sink into stupor')
   OR normalized_name LIKE 'sink into stupor // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg135_sink_into_stupor_mdfc_shadow_cleanup_20260624_0122;

COMMIT;
