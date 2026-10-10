-- D-85, correção 3: tira do metadado antigo de `activation_funnel_events` a chave
-- de idempotência (que carrega o UUID do usuário), os IDs de deck e de nota e o
-- arquétipo livre. Recomendação 15 da frente de KPI (BT-KPI-001): o coletor antigo
-- gravava o metadado como vinha; o coletor da 073 já descarta essas chaves
-- (`server/lib/analytics/activation_event_catalog.dart`: `idempotency_key` vira
-- `dedupe_key`; `archetype`, `source_deck_id` e
-- `recommendation_context.post_game_note_id` voltam em `dropped_fields`). O resto do
-- metadado fica como está. Linha nova nunca tem essas chaves, então a regra vale
-- para a tabela inteira.
--
-- Roda no lote de deploy, depois da 073 e da promoção (decisão do dono de
-- 2026-10-10, item 11), com a contagem antes e depois no receipt e a palavra do dono
-- na hora, pelo wrapper de escrita e com as duas aprovações canônicas no processo
-- chamador:
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d85_3_activation_event_legacy_metadata.sql
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases antes, acao e depois).
-- Uma transação só: qualquer erro desfaz tudo. Idempotente: a segunda rodada não
-- acha alvo e não muda nada.

\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';

DO $d85_3_pre$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.schema_migrations WHERE version = '073'
  ) THEN
    RAISE EXCEPTION
      'd85_3 recusado: a migration 073 (coletor com dedupe_key) ainda não foi aplicada';
  END IF;
END;
$d85_3_pre$;

-- Nenhum evento muda entre a contagem e a limpeza.
LOCK TABLE public.activation_funnel_events IN SHARE ROW EXCLUSIVE MODE;

CREATE TEMP VIEW d85_3_chaves AS
SELECT evento.id,
       evento.metadata ? 'idempotency_key' AS idempotency_key,
       evento.metadata ? 'archetype' AS archetype,
       evento.metadata ? 'source_deck_id' AS source_deck_id,
       evento.metadata ? 'post_game_note_id' AS post_game_note_id,
       COALESCE(
         jsonb_typeof(evento.metadata -> 'recommendation_context') = 'object'
         AND (evento.metadata -> 'recommendation_context') ? 'post_game_note_id',
         FALSE
       ) AS recommendation_context_post_game_note_id
FROM public.activation_funnel_events evento
WHERE jsonb_typeof(evento.metadata) = 'object';

CREATE TEMP VIEW d85_3_alvo AS
SELECT id
FROM d85_3_chaves
WHERE idempotency_key
   OR archetype
   OR source_deck_id
   OR post_game_note_id
   OR recommendation_context_post_game_note_id;

CREATE TEMP VIEW d85_3_contagem_por_chave AS
SELECT linha.objeto, linha.quantidade
FROM (
  SELECT COUNT(*) FILTER (WHERE idempotency_key) AS idempotency_key,
         COUNT(*) FILTER (WHERE archetype) AS archetype,
         COUNT(*) FILTER (WHERE source_deck_id) AS source_deck_id,
         COUNT(*) FILTER (WHERE post_game_note_id) AS post_game_note_id,
         COUNT(*) FILTER (WHERE recommendation_context_post_game_note_id)
           AS recommendation_context_post_game_note_id
  FROM d85_3_chaves
) contagem
CROSS JOIN LATERAL (
  VALUES
    (1, 'metadata.idempotency_key', contagem.idempotency_key),
    (2, 'metadata.archetype', contagem.archetype),
    (3, 'metadata.source_deck_id', contagem.source_deck_id),
    (4, 'metadata.post_game_note_id', contagem.post_game_note_id),
    (5, 'metadata.recommendation_context.post_game_note_id',
     contagem.recommendation_context_post_game_note_id)
) AS linha(ordem, objeto, quantidade)
ORDER BY linha.ordem;

SELECT 'antes' AS fase, 'eventos' AS objeto, COUNT(*)::text AS quantidade
FROM public.activation_funnel_events;

SELECT 'antes' AS fase, 'eventos_com_chave_antiga' AS objeto,
       COUNT(*)::text AS quantidade
FROM d85_3_alvo;

SELECT 'antes' AS fase, linha.objeto, linha.quantidade::text
FROM d85_3_contagem_por_chave AS linha;

WITH limpos AS (
  UPDATE public.activation_funnel_events evento
  SET metadata = (
    evento.metadata
      - 'idempotency_key'
      - 'archetype'
      - 'source_deck_id'
      - 'post_game_note_id'
  ) #- '{recommendation_context,post_game_note_id}'
  WHERE evento.id IN (SELECT id FROM d85_3_alvo)
  RETURNING evento.id
)
SELECT 'acao' AS fase, 'eventos_limpos' AS objeto, COUNT(*)::text AS quantidade
FROM limpos;

SELECT 'depois' AS fase, 'eventos' AS objeto, COUNT(*)::text AS quantidade
FROM public.activation_funnel_events;

SELECT 'depois' AS fase, 'eventos_com_chave_antiga' AS objeto,
       COUNT(*)::text AS quantidade
FROM d85_3_alvo;

SELECT 'depois' AS fase, linha.objeto, linha.quantidade::text
FROM d85_3_contagem_por_chave AS linha;

DO $d85_3_pos$
BEGIN
  IF EXISTS (SELECT 1 FROM d85_3_alvo) THEN
    RAISE EXCEPTION 'd85_3: ainda há evento com chave antiga depois da limpeza';
  END IF;
END;
$d85_3_pos$;

DROP VIEW d85_3_contagem_por_chave;
DROP VIEW d85_3_alvo;
DROP VIEW d85_3_chaves;

COMMIT;
