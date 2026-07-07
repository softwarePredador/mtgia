BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('breath weapon', 'fiery cannonade')
   OR normalized_name LIKE 'breath weapon // %'
   OR normalized_name LIKE 'fiery cannonade // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg647_damage_excluded_subtype_new_server_20260707_230507;

COMMIT;
