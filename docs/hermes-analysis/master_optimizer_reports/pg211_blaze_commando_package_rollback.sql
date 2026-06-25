BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blaze commando')
   OR normalized_name LIKE 'blaze commando // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg211_blaze_commando_20260625_083109;

COMMIT;
