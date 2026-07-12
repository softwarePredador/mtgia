BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('sage of the maze')
   OR normalized_name LIKE 'sage of the maze // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg822_sage_gate_land_animation_new_serve_20260712_092035;

COMMIT;
