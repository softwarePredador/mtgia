BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('archdruid''s charm', 'sink into stupor', 'ruthless technomancer', 'emperor of bones', 'disciple of freyalise', 'vibrance');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg134_current_replay_exact_scope_batch_two_20260624_0113;

COMMIT;
