BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abzan devotee', 'jeskai devotee', 'sultai devotee', 'temur devotee')
   OR normalized_name LIKE 'abzan devotee // %'
   OR normalized_name LIKE 'jeskai devotee // %'
   OR normalized_name LIKE 'sultai devotee // %'
   OR normalized_name LIKE 'temur devotee // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg594_limited_times_color_choice_mana_ne_20260707_045626;

COMMIT;
