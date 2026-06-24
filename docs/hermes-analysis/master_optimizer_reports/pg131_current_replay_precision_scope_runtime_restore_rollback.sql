BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('wan shi tong, librarian', 'hullbreaker horror', 'teferi, time raveler');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg131_current_replay_precision_scope_runtime_restore_202;

COMMIT;
