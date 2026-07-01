BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cruel cut', 'lava, axe', 'mox emerald', 'mox jet', 'mox pearl', 'mox ruby', 'mox sapphire', 'smelt // herd // saw')
   OR normalized_name LIKE 'cruel cut // %'
   OR normalized_name LIKE 'lava, axe // %'
   OR normalized_name LIKE 'mox emerald // %'
   OR normalized_name LIKE 'mox jet // %'
   OR normalized_name LIKE 'mox pearl // %'
   OR normalized_name LIKE 'mox ruby // %'
   OR normalized_name LIKE 'mox sapphire // %'
   OR normalized_name LIKE 'smelt // herd // saw // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg285_xmage_all_scope_supported_residual_20260701_080240;

COMMIT;
