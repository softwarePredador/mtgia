BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('desperate ritual')
   OR normalized_name LIKE 'desperate ritual // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg157_desperate_ritual_arcane_splice_20260624_084408;

COMMIT;
