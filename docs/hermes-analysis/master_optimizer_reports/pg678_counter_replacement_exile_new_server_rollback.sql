BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('assert authority', 'deny existence', 'deny the divine', 'dissipate', 'faerie trickery', 'horribly awry', 'liquify', 'void shatter')
   OR normalized_name LIKE 'assert authority // %'
   OR normalized_name LIKE 'deny existence // %'
   OR normalized_name LIKE 'deny the divine // %'
   OR normalized_name LIKE 'dissipate // %'
   OR normalized_name LIKE 'faerie trickery // %'
   OR normalized_name LIKE 'horribly awry // %'
   OR normalized_name LIKE 'liquify // %'
   OR normalized_name LIKE 'void shatter // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg678_counter_replacement_exile_new_serv_20260708_235913;

COMMIT;
