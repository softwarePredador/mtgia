BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aven trooper', 'burning-fist minotaur', 'canyon drake', 'carrion howler', 'cutthroat contender', 'fleshgrafter', 'frenetic ogre', 'grimclaw bats', 'krosan archer', 'noose constrictor', 'pardic swordsmith', 'putrid leech', 'ravenous bloodseeker', 'stalking bloodsucker', 'wall of blood')
   OR normalized_name LIKE 'aven trooper // %'
   OR normalized_name LIKE 'burning-fist minotaur // %'
   OR normalized_name LIKE 'canyon drake // %'
   OR normalized_name LIKE 'carrion howler // %'
   OR normalized_name LIKE 'cutthroat contender // %'
   OR normalized_name LIKE 'fleshgrafter // %'
   OR normalized_name LIKE 'frenetic ogre // %'
   OR normalized_name LIKE 'grimclaw bats // %'
   OR normalized_name LIKE 'krosan archer // %'
   OR normalized_name LIKE 'noose constrictor // %'
   OR normalized_name LIKE 'pardic swordsmith // %'
   OR normalized_name LIKE 'putrid leech // %'
   OR normalized_name LIKE 'ravenous bloodseeker // %'
   OR normalized_name LIKE 'stalking bloodsucker // %'
   OR normalized_name LIKE 'wall of blood // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg721_activated_self_boost_costs_new_ser_20260710_210547;

COMMIT;
