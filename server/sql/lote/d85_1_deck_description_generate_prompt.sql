-- D-85, correção 1: limpa de `decks.description` o prompt do Generate que o app
-- antigo gravava ali (`deck_generate_screen` salvava `description = prompt`).
-- Recomendação 5 da frente de deck (DCK-P0-04, D-29): limpar "a descrição igual ao
-- prompt salvo do Generate". Só entra a descrição que é igual, sem espaço nas
-- pontas, a um prompt salvo do mesmo dono:
--   - `ai_generate_jobs.result->>'prompt'` (resposta guardada do Generate assíncrono);
--   - `ai_generate_requests.prompt` (pedido durável da 069, enquanto o prompt existe).
-- Descrição que não bate com prompt salvo fica como está: não há como saber se era
-- prompt. A descrição vira NULL, como a do deck que o Generate novo materializa.
-- A revisão do deck e o ledger da 067 não mudam: é correção governada, não mudança
-- do dono, e o ledger só registra o que as rotas mudam.
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- com a contagem antes e depois no receipt e a palavra do dono na hora, pelo wrapper
-- de escrita e com as duas aprovações canônicas no processo chamador:
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d85_1_deck_description_generate_prompt.sql
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases antes, acao e depois).
-- Uma transação só: qualquer erro desfaz tudo. Idempotente: a segunda rodada não
-- acha alvo e não muda nada.

\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';

DO $d85_1_pre$
BEGIN
  IF to_regclass('public.ai_generate_requests') IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM public.schema_migrations WHERE version = '069'
     ) THEN
    RAISE EXCEPTION
      'd85_1 recusado: a migration 069 (ai_generate_requests) ainda não foi aplicada';
  END IF;
END;
$d85_1_pre$;

-- Nenhuma descrição muda entre a contagem e a limpeza.
LOCK TABLE public.decks IN SHARE ROW EXCLUSIVE MODE;

CREATE TEMP VIEW d85_1_alvo AS
SELECT deck.id
FROM public.decks deck
WHERE NULLIF(btrim(deck.description), '') IS NOT NULL
  AND (
    EXISTS (
      SELECT 1
      FROM public.ai_generate_jobs job
      WHERE job.user_id = deck.user_id
        AND jsonb_typeof(job.result) = 'object'
        AND btrim(job.result ->> 'prompt') = btrim(deck.description)
    )
    OR EXISTS (
      SELECT 1
      FROM public.ai_generate_requests request
      WHERE request.user_id = deck.user_id
        AND request.prompt IS NOT NULL
        AND btrim(request.prompt) = btrim(deck.description)
    )
  );

SELECT 'antes' AS fase, 'decks_com_descricao' AS objeto, COUNT(*)::text AS quantidade
FROM public.decks
WHERE NULLIF(btrim(description), '') IS NOT NULL;

SELECT 'antes' AS fase, 'descricao_igual_a_prompt_salvo' AS objeto,
       COUNT(*)::text AS quantidade
FROM d85_1_alvo;

WITH limpos AS (
  UPDATE public.decks deck
  SET description = NULL
  WHERE deck.id IN (SELECT id FROM d85_1_alvo)
  RETURNING deck.id
)
SELECT 'acao' AS fase, 'descricoes_limpas' AS objeto, COUNT(*)::text AS quantidade
FROM limpos;

SELECT 'depois' AS fase, 'decks_com_descricao' AS objeto, COUNT(*)::text AS quantidade
FROM public.decks
WHERE NULLIF(btrim(description), '') IS NOT NULL;

SELECT 'depois' AS fase, 'descricao_igual_a_prompt_salvo' AS objeto,
       COUNT(*)::text AS quantidade
FROM d85_1_alvo;

DO $d85_1_pos$
BEGIN
  IF EXISTS (SELECT 1 FROM d85_1_alvo) THEN
    RAISE EXCEPTION 'd85_1: ainda há descrição igual a prompt salvo depois da limpeza';
  END IF;
END;
$d85_1_pos$;

DROP VIEW d85_1_alvo;

COMMIT;
