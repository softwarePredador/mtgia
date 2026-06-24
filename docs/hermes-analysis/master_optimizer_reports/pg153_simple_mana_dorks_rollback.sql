BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('birds of paradise', 'llanowar elves', 'elvish mystic', 'avacyn''s pilgrim', 'fyndhorn elves')
   OR normalized_name LIKE 'birds of paradise // %'
   OR normalized_name LIKE 'llanowar elves // %'
   OR normalized_name LIKE 'elvish mystic // %'
   OR normalized_name LIKE 'avacyn''s pilgrim // %'
   OR normalized_name LIKE 'fyndhorn elves // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg153_simple_mana_dorks_20260624_081116;

COMMIT;
