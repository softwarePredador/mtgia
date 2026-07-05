BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bala ged scorpion', 'dakmor lancer', 'fleshpulper giant', 'marshdrinker giant', 'myconid spore tender', 'ravenous baboons', 'rock soldiers', 'rustspore ram', 'serpent assassin', 'setessan starbreaker', 'slayer of the wicked')
   OR normalized_name LIKE 'bala ged scorpion // %'
   OR normalized_name LIKE 'dakmor lancer // %'
   OR normalized_name LIKE 'fleshpulper giant // %'
   OR normalized_name LIKE 'marshdrinker giant // %'
   OR normalized_name LIKE 'myconid spore tender // %'
   OR normalized_name LIKE 'ravenous baboons // %'
   OR normalized_name LIKE 'rock soldiers // %'
   OR normalized_name LIKE 'rustspore ram // %'
   OR normalized_name LIKE 'serpent assassin // %'
   OR normalized_name LIKE 'setessan starbreaker // %'
   OR normalized_name LIKE 'slayer of the wicked // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg493_etb_destroy_target_vocabulary_new_20260705_082234;

COMMIT;
