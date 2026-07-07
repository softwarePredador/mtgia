BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bounce off', 'cut the earthly bond', 'depart the realm', 'hoodwink', 'into thin air', 'wipe away')
   OR normalized_name LIKE 'bounce off // %'
   OR normalized_name LIKE 'cut the earthly bond // %'
   OR normalized_name LIKE 'depart the realm // %'
   OR normalized_name LIKE 'hoodwink // %'
   OR normalized_name LIKE 'into thin air // %'
   OR normalized_name LIKE 'wipe away // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg591_bounce_target_variants_new_server_20260707_035542;

COMMIT;
