BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('lotho, corrupt shirriff', 'prized statue')
   OR normalized_name LIKE 'lotho, corrupt shirriff // %'
   OR normalized_name LIKE 'prized statue // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg139_current_replay_batch_two_lotho_prized_statue_20260;

COMMIT;
