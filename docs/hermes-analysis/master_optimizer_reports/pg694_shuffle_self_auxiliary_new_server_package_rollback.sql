BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('beacon of destruction', 'blue sun''s zenith')
   OR normalized_name LIKE 'beacon of destruction // %'
   OR normalized_name LIKE 'blue sun''s zenith // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg694_shuffle_self_auxiliary_new_server_20260709_060255;

COMMIT;
