BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('accursed horde', 'air marshal', 'beacon behemoth', 'bloodthorn taunter', 'hotfoot gnome', 'jawbone skulkin', 'kelsinko ranger', 'krosan groundshaker', 'might weaver', 'mosstodon', 'rage weaver', 'rakeclaw gargantuan', 'sky weaver', 'sootstoke kindler', 'spearbreaker behemoth', 'whalebone glider')
   OR normalized_name LIKE 'accursed horde // %'
   OR normalized_name LIKE 'air marshal // %'
   OR normalized_name LIKE 'beacon behemoth // %'
   OR normalized_name LIKE 'bloodthorn taunter // %'
   OR normalized_name LIKE 'hotfoot gnome // %'
   OR normalized_name LIKE 'jawbone skulkin // %'
   OR normalized_name LIKE 'kelsinko ranger // %'
   OR normalized_name LIKE 'krosan groundshaker // %'
   OR normalized_name LIKE 'might weaver // %'
   OR normalized_name LIKE 'mosstodon // %'
   OR normalized_name LIKE 'rage weaver // %'
   OR normalized_name LIKE 'rakeclaw gargantuan // %'
   OR normalized_name LIKE 'sky weaver // %'
   OR normalized_name LIKE 'sootstoke kindler // %'
   OR normalized_name LIKE 'spearbreaker behemoth // %'
   OR normalized_name LIKE 'whalebone glider // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg378_xmage_target_keyword_constraints_wave_20260704_020;

COMMIT;
