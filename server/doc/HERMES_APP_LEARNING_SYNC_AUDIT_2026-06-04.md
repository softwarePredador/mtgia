# Hermes/App Learning Sync Audit - 2026-06-04

## Veredito

**PASS_WITH_GATES.** A ligacao Hermes -> backend -> app esta funcional, mas o loop
nao deve publicar decks aprendidos automaticamente sem gate Commander estrito.

O app nao acessa Hermes/SQLite diretamente. A fonte runtime do app e o backend
publico, via `GET /ai/commander-learning`, lendo a tabela PG
`commander_learned_decks`.

## Fluxo Real

1. App/backend criam eventos de aprendizado em `deck_learning_events`.
2. `pull_learning_events.py` puxa eventos do PG para o SQLite Hermes.
3. Hermes analisa/promove learned decks no workspace de conhecimento.
4. `export_hermes_learned_deck.py` materializa JSON de um deck promovido.
5. `commander_learned_deck.dart` aplica esse JSON em `commander_learned_decks`.
6. App consulta `/ai/commander-learning` e mostra `Usar deck aprendido do comandante`.

## Correcoes Aplicadas

- `deck_learning_events.card_count` agora usa quantidade real das cartas, nao
  quantidade de linhas.
- `event_data` passou a registrar `cards_quantity_total`, `commander_quantity`
  e `main_quantity`.
- Decks salvos com payload baseado em `card_id` agora resolvem nomes em `cards`
  antes de gravar evento de aprendizado.
- `commander_card_usage` nao registra o proprio comandante nem duplicatas como
  hot cards.
- Hot cards carregados para prompt precisam resolver em `cards` e nao incluem o
  comandante.
- Prompt de hot cards deixou de afirmar que toda carta foi "validada"; agora
  orienta uso apenas quando legal, on-color e estruturalmente adequado.
- Importador `commander_learned_deck.dart` ganhou gate Commander 100/99+1.
- `--apply` sempre e estrito; `--dry-run --strict` tambem falha em payload
  invalido.
- `auto_promote_learned_decks.py` exige, por padrao, 100 cartas parseadas, 1
  comandante e 99 main.
- `auto_sync_learned_decks.py` agora e dry-run estrito por padrao. Para mutar PG,
  usar `--apply` ou `HERMES_AUTO_SYNC_APPLY=1`.
- `sync_hermes_learned_deck.sh` usa `HERMES_KNOWLEDGE_DB` opcional e dry-run
  estrito.

## Politica Operacional

- Pode rodar automaticamente:
  - pull de eventos para Hermes;
  - analises de conhecimento;
  - auto-promote local no SQLite com gate 100/99+1.
- Nao deve rodar automaticamente sem revisao:
  - apply para PG de `commander_learned_decks`;
  - ativacao de deck aprendido para um comandante novo sem scorecard/runtime
    focado.

## Comandos De Validacao

```bash
cd server
dart analyze lib/ai/deck_learning_event_support.dart lib/ai/commander_learned_deck_support.dart routes/decks/index.dart bin/commander_learned_deck.dart test/commander_learned_deck_support_test.dart test/deck_learning_event_support_test.dart
dart test test/commander_learned_deck_support_test.dart test/deck_learning_event_support_test.dart -r expanded
```

```bash
python3 -m py_compile \
  server/bin/auto_promote_learned_decks.py \
  server/bin/auto_sync_learned_decks.py \
  server/bin/export_hermes_learned_deck.py \
  server/bin/pull_learning_events.py
```

## Estado Final

O ciclo e autoaprendivel para melhorar sinais e prompts, mas a publicacao para o
app fica gated. Isso e intencional: aprender sempre, publicar somente quando
valido.
