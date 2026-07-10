BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('talisman of hierarchy', 'talisman of unity')
   OR normalized_name LIKE 'talisman of hierarchy // %'
   OR normalized_name LIKE 'talisman of unity // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg715_pain_talisman_new_server_20260710_190359;

COMMIT;
