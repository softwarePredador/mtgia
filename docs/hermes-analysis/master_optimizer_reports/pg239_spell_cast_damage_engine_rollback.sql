BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('longshot, rebel bowman', 'guttersnipe', 'coruscation mage', 'fiery inscription', 'vivi ornitier')
   OR normalized_name LIKE 'longshot, rebel bowman // %'
   OR normalized_name LIKE 'guttersnipe // %'
   OR normalized_name LIKE 'coruscation mage // %'
   OR normalized_name LIKE 'fiery inscription // %'
   OR normalized_name LIKE 'vivi ornitier // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg239_spell_cast_damage_engine_20260626_101944;

COMMIT;
