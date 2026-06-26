BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('warleader''s call')
   OR normalized_name LIKE 'warleader''s call // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg218_warleaders_call_creature_etb_damage_20260625_12284;

COMMIT;
