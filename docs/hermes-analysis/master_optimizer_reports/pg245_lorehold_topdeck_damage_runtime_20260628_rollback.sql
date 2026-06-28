BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('twinflame tyrant', 'verge rangers')
   OR normalized_name LIKE 'twinflame tyrant // %'
   OR normalized_name LIKE 'verge rangers // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg245_lorehold_topdeck_damage_runtime_20260628_015359;

COMMIT;
