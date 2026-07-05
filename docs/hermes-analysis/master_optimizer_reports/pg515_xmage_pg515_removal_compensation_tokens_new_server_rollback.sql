BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('afterlife', 'angelic ascension', 'beast within', 'bovine intervention', 'harsh annotation', 'reduce to memory', 'secure the scene')
   OR normalized_name LIKE 'afterlife // %'
   OR normalized_name LIKE 'angelic ascension // %'
   OR normalized_name LIKE 'beast within // %'
   OR normalized_name LIKE 'bovine intervention // %'
   OR normalized_name LIKE 'harsh annotation // %'
   OR normalized_name LIKE 'reduce to memory // %'
   OR normalized_name LIKE 'secure the scene // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg515_xmage_pg515_removal_compensation_t_20260705_155001;

COMMIT;
