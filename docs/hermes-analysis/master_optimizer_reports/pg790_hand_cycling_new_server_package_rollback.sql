BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('angel of the god-pharaoh', 'barkhide mauler', 'desert cerodon', 'granitic titan', 'hundroog', 'imposing vantasaur', 'jungle weaver', 'keeneye aven', 'lava serpent', 'lurching rotbeast', 'macetail hystrodon', 'moaning wall', 'pendrell drake', 'primoc escapee', 'rampaging hippo', 'ridge rannet', 'sandbar merfolk', 'sandbar serpent', 'shimmering barrier', 'shimmerscale drake', 'striped riverwinder', 'wasteland scorpion', 'winged shepherd', 'yoked plowbeast')
   OR normalized_name LIKE 'angel of the god-pharaoh // %'
   OR normalized_name LIKE 'barkhide mauler // %'
   OR normalized_name LIKE 'desert cerodon // %'
   OR normalized_name LIKE 'granitic titan // %'
   OR normalized_name LIKE 'hundroog // %'
   OR normalized_name LIKE 'imposing vantasaur // %'
   OR normalized_name LIKE 'jungle weaver // %'
   OR normalized_name LIKE 'keeneye aven // %'
   OR normalized_name LIKE 'lava serpent // %'
   OR normalized_name LIKE 'lurching rotbeast // %'
   OR normalized_name LIKE 'macetail hystrodon // %'
   OR normalized_name LIKE 'moaning wall // %'
   OR normalized_name LIKE 'pendrell drake // %'
   OR normalized_name LIKE 'primoc escapee // %'
   OR normalized_name LIKE 'rampaging hippo // %'
   OR normalized_name LIKE 'ridge rannet // %'
   OR normalized_name LIKE 'sandbar merfolk // %'
   OR normalized_name LIKE 'sandbar serpent // %'
   OR normalized_name LIKE 'shimmering barrier // %'
   OR normalized_name LIKE 'shimmerscale drake // %'
   OR normalized_name LIKE 'striped riverwinder // %'
   OR normalized_name LIKE 'wasteland scorpion // %'
   OR normalized_name LIKE 'winged shepherd // %'
   OR normalized_name LIKE 'yoked plowbeast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg790_hand_cycling_new_server_pg790_hand_20260711_215437;

COMMIT;
