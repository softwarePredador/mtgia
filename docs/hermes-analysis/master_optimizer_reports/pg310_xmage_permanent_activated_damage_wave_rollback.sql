BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aeolipile', 'aladdin''s ring', 'anaba shaman', 'barbarian lunatic', 'crackling triton', 'ember hauler', 'explosive apparatus', 'flamecast wheel', 'flamekin spitfire', 'frostling', 'granite shard', 'hatchet bully', 'lightning-core excavator', 'mogg fanatic', 'moonglove extract', 'rod of ruin', 'scalding cauldron', 'seal of fire', 'shock troops', 'silent dart', 'tower of calamities', 'valakut invoker', 'vial of dragonfire')
   OR normalized_name LIKE 'aeolipile // %'
   OR normalized_name LIKE 'aladdin''s ring // %'
   OR normalized_name LIKE 'anaba shaman // %'
   OR normalized_name LIKE 'barbarian lunatic // %'
   OR normalized_name LIKE 'crackling triton // %'
   OR normalized_name LIKE 'ember hauler // %'
   OR normalized_name LIKE 'explosive apparatus // %'
   OR normalized_name LIKE 'flamecast wheel // %'
   OR normalized_name LIKE 'flamekin spitfire // %'
   OR normalized_name LIKE 'frostling // %'
   OR normalized_name LIKE 'granite shard // %'
   OR normalized_name LIKE 'hatchet bully // %'
   OR normalized_name LIKE 'lightning-core excavator // %'
   OR normalized_name LIKE 'mogg fanatic // %'
   OR normalized_name LIKE 'moonglove extract // %'
   OR normalized_name LIKE 'rod of ruin // %'
   OR normalized_name LIKE 'scalding cauldron // %'
   OR normalized_name LIKE 'seal of fire // %'
   OR normalized_name LIKE 'shock troops // %'
   OR normalized_name LIKE 'silent dart // %'
   OR normalized_name LIKE 'tower of calamities // %'
   OR normalized_name LIKE 'valakut invoker // %'
   OR normalized_name LIKE 'vial of dragonfire // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg310_xmage_permanent_activated_damage_wave_20260701_141;

COMMIT;
