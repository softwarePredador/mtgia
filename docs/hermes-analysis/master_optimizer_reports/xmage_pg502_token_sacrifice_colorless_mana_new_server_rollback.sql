BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dread drone', 'emrakul''s hatcher', 'kozilek''s predator', 'nest invader', 'skittering invasion')
   OR normalized_name LIKE 'dread drone // %'
   OR normalized_name LIKE 'emrakul''s hatcher // %'
   OR normalized_name LIKE 'kozilek''s predator // %'
   OR normalized_name LIKE 'nest invader // %'
   OR normalized_name LIKE 'skittering invasion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg502_xmage_token_sacrifice_colorless_ma_20260705_111909;

COMMIT;
