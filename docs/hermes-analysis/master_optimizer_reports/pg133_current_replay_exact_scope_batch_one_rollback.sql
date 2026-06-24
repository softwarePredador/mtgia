BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('into the flood maw', 'snap', 'walking ballista', 'everflowing chalice', 'manamorphose', 'tinder wall');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg133_current_replay_exact_scope_batch_one_20260624_0102;

COMMIT;
