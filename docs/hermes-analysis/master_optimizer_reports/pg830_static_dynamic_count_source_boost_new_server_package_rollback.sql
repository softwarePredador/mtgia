BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('benalish honor guard', 'champion of the flame', 'copperhoof vorrac', 'earth servant', 'goblin gaveleer', 'graceblade artisan', 'grim strider', 'kavu scout', 'loxodon punisher', 'mogg squad', 'nim lasher', 'nim shrieker', 'rabid wombat', 'radiant, archangel', 'scourge of geier reach', 'uril, the miststalker', 'wayfaring giant', 'yavimaya enchantress')
   OR normalized_name LIKE 'benalish honor guard // %'
   OR normalized_name LIKE 'champion of the flame // %'
   OR normalized_name LIKE 'copperhoof vorrac // %'
   OR normalized_name LIKE 'earth servant // %'
   OR normalized_name LIKE 'goblin gaveleer // %'
   OR normalized_name LIKE 'graceblade artisan // %'
   OR normalized_name LIKE 'grim strider // %'
   OR normalized_name LIKE 'kavu scout // %'
   OR normalized_name LIKE 'loxodon punisher // %'
   OR normalized_name LIKE 'mogg squad // %'
   OR normalized_name LIKE 'nim lasher // %'
   OR normalized_name LIKE 'nim shrieker // %'
   OR normalized_name LIKE 'rabid wombat // %'
   OR normalized_name LIKE 'radiant, archangel // %'
   OR normalized_name LIKE 'scourge of geier reach // %'
   OR normalized_name LIKE 'uril, the miststalker // %'
   OR normalized_name LIKE 'wayfaring giant // %'
   OR normalized_name LIKE 'yavimaya enchantress // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg830_static_dynamic_count_source_boost_20260712_122413;

COMMIT;
