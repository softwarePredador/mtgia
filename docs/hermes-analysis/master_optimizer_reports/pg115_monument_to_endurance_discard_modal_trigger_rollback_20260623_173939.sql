BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'monument to endurance';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg115_monument_to_endurance_discard_modal_trigger_20260623_1739;

COMMIT;
