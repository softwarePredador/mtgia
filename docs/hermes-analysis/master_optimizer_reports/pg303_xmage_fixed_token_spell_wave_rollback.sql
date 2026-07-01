BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('allied reinforcements', 'call of the conclave', 'captain''s call', 'dragon fodder', 'elemental summoning', 'flurry of horns', 'goblin rally', 'hive stirrings', 'hop to it', 'hordeling outburst', 'icatian town', 'inkling summoning', 'join the ranks', 'krenko''s command', 'mass production', 'master''s call', 'midnight haunting', 'raise the alarm', 'ral''s reinforcements', 'release the dogs', 'revel of the fallen god', 'spectral procession', 'spirit summoning', 'spore swarm', 'sprout', 'take up arms', 'talrand''s invocation')
   OR normalized_name LIKE 'allied reinforcements // %'
   OR normalized_name LIKE 'call of the conclave // %'
   OR normalized_name LIKE 'captain''s call // %'
   OR normalized_name LIKE 'dragon fodder // %'
   OR normalized_name LIKE 'elemental summoning // %'
   OR normalized_name LIKE 'flurry of horns // %'
   OR normalized_name LIKE 'goblin rally // %'
   OR normalized_name LIKE 'hive stirrings // %'
   OR normalized_name LIKE 'hop to it // %'
   OR normalized_name LIKE 'hordeling outburst // %'
   OR normalized_name LIKE 'icatian town // %'
   OR normalized_name LIKE 'inkling summoning // %'
   OR normalized_name LIKE 'join the ranks // %'
   OR normalized_name LIKE 'krenko''s command // %'
   OR normalized_name LIKE 'mass production // %'
   OR normalized_name LIKE 'master''s call // %'
   OR normalized_name LIKE 'midnight haunting // %'
   OR normalized_name LIKE 'raise the alarm // %'
   OR normalized_name LIKE 'ral''s reinforcements // %'
   OR normalized_name LIKE 'release the dogs // %'
   OR normalized_name LIKE 'revel of the fallen god // %'
   OR normalized_name LIKE 'spectral procession // %'
   OR normalized_name LIKE 'spirit summoning // %'
   OR normalized_name LIKE 'spore swarm // %'
   OR normalized_name LIKE 'sprout // %'
   OR normalized_name LIKE 'take up arms // %'
   OR normalized_name LIKE 'talrand''s invocation // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg303_xmage_fixed_token_spell_wave_20260701_121234;

COMMIT;
