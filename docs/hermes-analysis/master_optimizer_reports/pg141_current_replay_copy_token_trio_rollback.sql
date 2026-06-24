BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('flash photography', 'astral dragon', 'clone legion')
   OR normalized_name LIKE 'flash photography // %'
   OR normalized_name LIKE 'astral dragon // %'
   OR normalized_name LIKE 'clone legion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg141_current_replay_copy_token_trio_20260624_035857;

COMMIT;
