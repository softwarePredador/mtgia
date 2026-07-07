BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deadly riposte', 'joust through', 'kiss of death', 'sorin''s vengeance', 'soul shred', 'soul spike', 'spinning darkness', 'stolen grain', 'taste of blood', 'vampiric touch')
   OR normalized_name LIKE 'deadly riposte // %'
   OR normalized_name LIKE 'joust through // %'
   OR normalized_name LIKE 'kiss of death // %'
   OR normalized_name LIKE 'sorin''s vengeance // %'
   OR normalized_name LIKE 'soul shred // %'
   OR normalized_name LIKE 'soul spike // %'
   OR normalized_name LIKE 'spinning darkness // %'
   OR normalized_name LIKE 'stolen grain // %'
   OR normalized_name LIKE 'taste of blood // %'
   OR normalized_name LIKE 'vampiric touch // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg607_damage_life_target_variants_new_se_20260707_095059;

COMMIT;
