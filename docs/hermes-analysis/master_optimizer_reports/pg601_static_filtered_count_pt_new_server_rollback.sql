BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('drove of elves', 'faerie swarm', 'horde of boggarts', 'keldon warlord', 'kithkin rabble', 'maraxus of keld', 'matca rioters', 'plague rats', 'regal bunnicorn', 'territorial maro')
   OR normalized_name LIKE 'drove of elves // %'
   OR normalized_name LIKE 'faerie swarm // %'
   OR normalized_name LIKE 'horde of boggarts // %'
   OR normalized_name LIKE 'keldon warlord // %'
   OR normalized_name LIKE 'kithkin rabble // %'
   OR normalized_name LIKE 'maraxus of keld // %'
   OR normalized_name LIKE 'matca rioters // %'
   OR normalized_name LIKE 'plague rats // %'
   OR normalized_name LIKE 'regal bunnicorn // %'
   OR normalized_name LIKE 'territorial maro // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg601_static_filtered_count_pt_new_serve_20260707_072729;

COMMIT;
