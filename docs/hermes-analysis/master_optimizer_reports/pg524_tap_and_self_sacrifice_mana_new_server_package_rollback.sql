BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('eye of ramos', 'heart of ramos', 'horn of ramos', 'skull of ramos', 'tooth of ramos')
   OR normalized_name LIKE 'eye of ramos // %'
   OR normalized_name LIKE 'heart of ramos // %'
   OR normalized_name LIKE 'horn of ramos // %'
   OR normalized_name LIKE 'skull of ramos // %'
   OR normalized_name LIKE 'tooth of ramos // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg524_tap_and_self_sacrifice_mana_20260705_190617;

COMMIT;
