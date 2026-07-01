BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bloodtallow candle', 'cabal trainee', 'child of thorns', 'elven lyre', 'nim replica', 'phyrexian defiler', 'phyrexian denouncer', 'seal of strength', 'shield mate')
   OR normalized_name LIKE 'bloodtallow candle // %'
   OR normalized_name LIKE 'cabal trainee // %'
   OR normalized_name LIKE 'child of thorns // %'
   OR normalized_name LIKE 'elven lyre // %'
   OR normalized_name LIKE 'nim replica // %'
   OR normalized_name LIKE 'phyrexian defiler // %'
   OR normalized_name LIKE 'phyrexian denouncer // %'
   OR normalized_name LIKE 'seal of strength // %'
   OR normalized_name LIKE 'shield mate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg316_xmage_permanent_activated_target_boost_source_sacr;

COMMIT;
