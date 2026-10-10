-- D-85, correção 2: apaga os relatórios públicos órfãos de decks já apagados.
-- Recomendação 10 da frente de deck (DCK-P0-06): relatórios com `deck_id` nulo e
-- `is_public` verdadeiro, de decks apagados antes da lixeira (a chave de
-- `shared_deck_reports.deck_id` é ON DELETE SET NULL). Desde `5850540d7` eles não são
-- servidos, mas são cópias sem finalidade. O órfão privado fica fora do que foi
-- aprovado: só é contado, para o dono decidir.
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- com a contagem antes e depois no receipt e a palavra do dono na hora, pelo wrapper
-- de escrita e com as duas aprovações canônicas no processo chamador:
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d85_2_orphan_public_deck_reports.sql
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases antes, acao e depois).
-- Uma transação só: qualquer erro desfaz tudo. Idempotente: a segunda rodada não
-- acha alvo e não muda nada.

\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';

DO $d85_2_pre$
BEGIN
  IF to_regclass('public.shared_deck_reports') IS NULL THEN
    RAISE EXCEPTION 'd85_2 recusado: a tabela shared_deck_reports não existe';
  END IF;
END;
$d85_2_pre$;

-- Nenhum relatório muda entre a contagem e a exclusão.
LOCK TABLE public.shared_deck_reports IN SHARE ROW EXCLUSIVE MODE;

SELECT 'antes' AS fase, 'relatorios' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports;

SELECT 'antes' AS fase, 'orfaos_publicos' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND is_public;

SELECT 'antes' AS fase, 'orfaos_privados_fora_do_escopo' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND NOT is_public;

WITH apagados AS (
  DELETE FROM public.shared_deck_reports
  WHERE deck_id IS NULL AND is_public
  RETURNING id
)
SELECT 'acao' AS fase, 'orfaos_publicos_apagados' AS objeto,
       COUNT(*)::text AS quantidade
FROM apagados;

SELECT 'depois' AS fase, 'relatorios' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports;

SELECT 'depois' AS fase, 'orfaos_publicos' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND is_public;

SELECT 'depois' AS fase, 'orfaos_privados_fora_do_escopo' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND NOT is_public;

DO $d85_2_pos$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.shared_deck_reports WHERE deck_id IS NULL AND is_public
  ) THEN
    RAISE EXCEPTION 'd85_2: ainda há relatório público órfão depois da exclusão';
  END IF;
END;
$d85_2_pos$;

COMMIT;
