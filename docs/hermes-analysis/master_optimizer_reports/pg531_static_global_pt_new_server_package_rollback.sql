BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('anaba spirit crafter', 'bad moon', 'blade sliver', 'bonesplitter sliver', 'dampening pulse', 'dread of night', 'earth surge', 'illness in the ranks', 'kaervek, the spiteful', 'might sliver', 'muscle sliver', 'night of souls'' betrayal', 'plated sliver', 'sinew sliver', 'stronghold taskmaster', 'urborg shambler', 'virulent plague', 'watcher sliver')
   OR normalized_name LIKE 'anaba spirit crafter // %'
   OR normalized_name LIKE 'bad moon // %'
   OR normalized_name LIKE 'blade sliver // %'
   OR normalized_name LIKE 'bonesplitter sliver // %'
   OR normalized_name LIKE 'dampening pulse // %'
   OR normalized_name LIKE 'dread of night // %'
   OR normalized_name LIKE 'earth surge // %'
   OR normalized_name LIKE 'illness in the ranks // %'
   OR normalized_name LIKE 'kaervek, the spiteful // %'
   OR normalized_name LIKE 'might sliver // %'
   OR normalized_name LIKE 'muscle sliver // %'
   OR normalized_name LIKE 'night of souls'' betrayal // %'
   OR normalized_name LIKE 'plated sliver // %'
   OR normalized_name LIKE 'sinew sliver // %'
   OR normalized_name LIKE 'stronghold taskmaster // %'
   OR normalized_name LIKE 'urborg shambler // %'
   OR normalized_name LIKE 'virulent plague // %'
   OR normalized_name LIKE 'watcher sliver // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg531_static_global_pt_new_server_20260705_212939;

COMMIT;
