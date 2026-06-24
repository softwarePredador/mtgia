BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('carrion feeder', 'icatian moneychanger', 'warden of the grove', 'wildborn preserver');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg126_add_counters_creature_runtime_restore_20260624_000;

COMMIT;
