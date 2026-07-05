BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('geistcatcher''s rig', 'goretusk firebeast', 'unsparing boltcaster', 'viashino pyromancer', 'whiptail moloch')
   OR normalized_name LIKE 'geistcatcher''s rig // %'
   OR normalized_name LIKE 'goretusk firebeast // %'
   OR normalized_name LIKE 'unsparing boltcaster // %'
   OR normalized_name LIKE 'viashino pyromancer // %'
   OR normalized_name LIKE 'whiptail moloch // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg509_xmage_pg509_etb_fixed_damage_targe_20260705_134357;

COMMIT;
