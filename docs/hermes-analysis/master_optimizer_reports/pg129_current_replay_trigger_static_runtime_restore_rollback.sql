BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('faerie mastermind', 'vexing bauble', 'nezahal, primal tide');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg129_current_replay_trigger_static_runtime_restore_2026;

COMMIT;
