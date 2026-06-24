BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('orcish bowmasters', 'deathrite shaman');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg132_current_replay_triggered_utility_runtime_restore_2;

COMMIT;
