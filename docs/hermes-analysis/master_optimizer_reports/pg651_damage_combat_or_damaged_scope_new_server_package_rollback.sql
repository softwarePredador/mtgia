BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('inflame', 'warpath')
   OR normalized_name LIKE 'inflame // %'
   OR normalized_name LIKE 'warpath // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg651_damage_combat_or_damaged_scope_new_20260707_234541;

COMMIT;
