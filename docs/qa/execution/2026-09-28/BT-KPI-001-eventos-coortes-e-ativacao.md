# Receipt — BT-KPI-001: eventos, coortes, ativação e guardrails, parte do servidor — 2026-09-28

- Tarefa: `BT-KPI-001`, parte do servidor, feita pela Frente B (deck e trocas) da coordenação
  do MVP na branch `deck/rodada2-2026-09-24`, sobre `96d840968` (LC-P0-05).
- Decisão do dono aplicada: D-47. Ativação é o primeiro deck criado ou importado em até 24 h
  do cadastro; retenção é a volta na segunda semana; há guardrails de custo de IA e de taxa de
  erro; nenhuma decklist vai para analytics; a política de privacidade é atualizada quando a
  telemetria entrar.
- Aceite do backlog: "Métricas contam usuários/loops de valor, não apenas eventos; nenhum
  decklist/UGC em analytics."
- Ponto de partida, pela medição de 2026-09-22 (`docs/flows/_p0/privacidade-telemetria.md`):
  - o painel somava eventos e dividia por cadastros, e o teste
    `commercial_metrics_service_test.dart:8-18` consagrava a soma;
  - o coletor aceitava `metadata` livre e `deck_id` de outra pessoa;
  - o app emitia 4 eventos que o servidor recusava;
  - o servidor aceitava 3 nomes que ninguém emitia.
- Nada tocou a produção: sem SSH, sem banco live, sem deploy. A migration `073` está só no
  código. Os testes de banco rodaram num PostgreSQL 17 descartável da frente (`LC_ALL=C`, só em
  `127.0.0.1`, sem socket Unix), criado do zero por `server/database_setup.sql` e
  `server/bin/migrate.dart` do worktree (`migrations=65 latest=073`), parado e apagado no fim.
- Só servidor. O app não mudou: a raia do app está bloqueada até a sessão do gate commitar as
  recapturas.

## O que mudou

1. **Catálogo único `activation_events_v1`** (`server/lib/analytics/activation_event_catalog.dart`).
   - Tem os 12 eventos que o app emite hoje, na ordem do funil. Os 4 do onboarding que o
     servidor recusava entraram (achado 13).
   - Os 3 nomes que o app deixou de emitir em agosto (`base_choice_generate`,
     `base_choice_import` e `deck_optimized`) saíram. As linhas antigas ficam na tabela.
   - Cada evento declara as origens aceitas (o ponto do app que emite) e se leva `deck_id`.
     Só `optimize_preview_received` e `deck_rebuild_created` levam.
   - Cada evento declara também o esquema do `metadata`. Um valor só pode ser enumerado
     fechado, inteiro com faixa, booleano ou objeto com o mesmo tipo de esquema. Não existe
     campo de texto livre.
2. **Coletor `POST /users/me/activation-events`.** Grava só o que passa pelo catálogo.
   - 400 sem linha gravada, com `error_code` e `field`:
     - evento fora do catálogo ou aposentado;
     - campo fora do esquema, como decklist ou nome de deck;
     - texto fora da lista fechada, tipo errado ou valor fora da faixa;
     - origem ou formato fora da lista;
     - chave de idempotência inválida.
   - 404 `deck_not_found` sem linha: `deck_id` de outra pessoa ou de deck na lixeira.
   - O app atual ainda manda três campos que o servidor não guarda: o nome livre do arquétipo,
     o ID do deck de origem do rebuild e o ID da nota do pós-jogo. Eles saem antes de gravar e
     voltam na resposta em `dropped_fields`.
   - A chave de idempotência do `trackOnce` carrega o ID do usuário. Ela vira só o hash
     SHA-256 em `dedupe_key`, e a mesma chave do mesmo usuário grava uma vez só: a repetição
     responde 200 com `duplicate: true`, e o app guarda o recibo.
   - O 500 não devolve mais o texto da exceção.
3. **Migration 073 (`activation_events_dedupe`).**
   - Cria a coluna `activation_funnel_events.dedupe_key`, com um CHECK que só aceita 64
     caracteres hexadecimais, e o índice único parcial `(user_id, dedupe_key)`.
   - O baseline (`database_setup.sql`) acompanha.
   - Rollback padrão: o down tira o índice, o CHECK e a coluna.
   - A 073 não cria tabela nem chave para `users`, então fica fora da regra do laço dos
     gatilhos de conta ativa (a partir da 070, só para migration que cria chave para `users`).
4. **Métricas do `GET /health/commercial`** (`server/lib/analytics/activation_kpi.dart` e
   `server/lib/commercial_metrics_service.dart`).
   - O funil antigo (`activation_funnel`, eventos divididos por cadastros) e a soma
     `countAiActivationEvents` saíram.
   - Entrou a seção `activation` (`activation_kpi_v1`), com `definition`, `totals` e uma
     linha por coorte (semana UTC do cadastro). Cada linha tem os cadastros, as contas
     excluídas, a ativação em 24 h, a volta na segunda semana, os loops de valor e o funil do
     catálogo. Tudo conta usuários distintos.
   - Entrou a seção `guardrails` (versão 1).
   - O `GET /health/dashboard` carrega o mesmo retrato, de 30 dias.
5. **Privacidade.**
   - O inventário de retenção classifica `dedupe_key` como `omit_hash`: não sai na exportação.
   - A finalidade da tabela passa a citar o catálogo.
   - A lacuna registra que as linhas antigas podem ter, no metadado, a chave com o ID do
     usuário, IDs de deck e de nota e o arquétipo livre.
6. **Contrato de API.** As linhas do coletor, do `GET /health/commercial` e do
   `GET /health/dashboard` foram reescritas, e o guarda do contrato fixa os pontos novos.

## Definições (D-47, `activation_kpi_v1`)

| Métrica | Definição | Denominador |
| --- | --- | --- |
| Coorte | Semana UTC do cadastro (segunda-feira), só com cadastros da janela pedida (`days`, de 1 a 90) | — |
| Ativação | Primeiro deck criado ou importado em até 24 h do cadastro, lido da tabela `decks`. O deck que depois foi para a lixeira conta; o purgado some | Cadastros com as 24 h completas |
| Volta na segunda semana | Pelo menos uma ação registrada no servidor entre o 7º e o 14º dia depois do cadastro (fim aberto) | Cadastros com os 14 dias completos |
| Loops de valor | Montou deck; anotou partida (nota do pós-jogo); ajustou deck (mudança no ledger, menos ir para a lixeira e voltar); usou IA (ação de IA concluída) | Cadastros da coorte |
| Funil | Usuários distintos da coorte que emitiram cada evento do catálogo | Cadastros da coorte |
| Conta excluída | Sai de todas as contagens e aparece só em `deleted_accounts`, porque a exclusão apaga os dados dela | — |

Taxa sem denominador é `null`, não zero.

As ações que contam como volta são as linhas criadas pelo usuário em: `decks`,
`deck_change_events`, `post_game_notes`, `user_binder_items`, `activation_funnel_events`,
`ai_logs` (só ação de IA concluída, nunca reserva), `ai_generate_requests`,
`interactive_battle_sessions` e `shared_deck_reports`. Só contam colunas de criação, porque
`updated_at` pode mudar por processo do servidor.

**Guardrails v1:**

| Guardrail | Medida na janela | Aviso | Crítico | Amostra mínima |
| --- | --- | --- | --- | --- |
| `ai_provider_error_rate` | Falhas do provedor de IA ÷ chamadas (sem as linhas de cota) | 20% | 50% | 5 chamadas |
| `ai_actions_per_ai_user_30d` | Ações de IA concluídas por usuário que usou IA, levadas a 30 dias | 60 (50% do teto de 120) | 96 (80% do teto) | 1 usuário |
| `generate_failure_rate` | Pedidos do Generate que falharam ÷ terminados | 20% | 50% | 5 pedidos |

As taxas de erro usam os limites do alerta operacional de provedor de IA
(`operational_alerts.dart`, versão 2). O custo é medido contra o teto da beta gratuita.
Abaixo da amostra mínima, o estado é `insufficient_data`; o estado geral é o pior entre os
que têm veredito.

## Política de telemetria (servidor)

- **O que entra:**
  - o nome do evento, do catálogo;
  - a origem no app;
  - o formato;
  - o `deck_id` de um deck do próprio usuário, em dois eventos;
  - enumerados, inteiros com faixa e booleanos;
  - o hash da chave de idempotência.
- **O que nunca entra:** decklist, carta, nome ou descrição de deck, prompt, texto de nota,
  arquétipo livre, e-mail, nome de usuário ou ID de outra entidade. O servidor recusa ou
  descarta antes de gravar.
- **O que o painel mostra:** só contagens, taxas, semanas e os nomes fixos do catálogo.
  Nenhum ID de usuário, deck ou carta sai, e nenhum metadado de evento.
- **Acesso:** o painel é só de operação (chave de ops ou JWT de admin). A exportação da conta
  leva os eventos da pessoa sem o hash, e a exclusão da conta apaga os eventos.
- **Prazo de guarda:** não decidido (D-69; entra no job de limpeza depois do advogado).
- **Política pública:** não muda agora. A D-47 manda atualizá-la quando a telemetria entrar,
  o que sobe a versão de Privacidade e pede o reaceite do `BT-LEGAL-ACCEPT-001`.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/activation_events_db_live_test.dart` | PostgreSQL descartável | 5/5 |
| `server/test/activation_kpi_db_live_test.dart` | PostgreSQL descartável | 4/4 |
| Todos os testes de banco do servidor (24 arquivos, todas as chaves `RUN_*_DB_TESTS`) | PostgreSQL descartável | 139 verdes e 1 falha anterior, fora desta tarefa (`interactive_battle_store_live_test.dart:657`, 42601) |
| `activation_event_catalog_test.dart`, `activation_events_contract_test.dart`, `activation_events_migration_test.dart`, `commercial_metrics_service_test.dart`, `api_contracts_data_map_guard_test.dart`, `privacy_data_inventory_test.dart`, `privacy_export_allowlist_test.dart`, as travas da última migration e a suíte de foco | unitário, com o manifesto regenerado, dentro da trava, antes do commit | 133/133 (20 arquivos) |

O teste de banco das métricas monta uma coorte de sete cadastros numa semana de 9 semanas atrás
e compara a linha dessa semana antes e depois de semear. Assim, os dados de outros testes no
mesmo banco não mudam o resultado.

| Cadastro | O que tem | Ativa? | Volta? |
| --- | --- | --- | --- |
| u1 | Deck em 2 h, nota no 8º dia, três eventos `core_flow_started` | sim | sim |
| u2 | Deck em 30 h, ajuste no 6º dia, ação no 14º dia exato | não | não |
| u3 | Sem deck; evento em 13 dias e 23h59 | não | sim |
| u4 | Conta excluída, com deck e evento | fora | fora |
| u5 | Deck em 23h59, mandado para a lixeira no 9º dia | sim | sim (a lixeira não conta como ajuste) |
| u6 | Sem deck; ação de IA concluída no 10º dia | não | sim |
| u7 | Só uma reserva de IA que falhou, no 9º dia | não | não |

- Contagens: 6 cadastros, 1 conta excluída, 2 ativados (taxa 0,3333) e 4 voltas (0,6667).
- Loops: deck 3, nota 1, ajuste 1, IA 1.
- Funil: `core_flow_started` com 2 usuários, não 4 eventos.
- Um cadastro recente não entra na taxa de ativação nem na de volta.
- Os guardrails somam exatamente o que foi semeado.
- O retrato inteiro do painel não tem as marcas de conteúdo semeadas (nome e descrição de
  deck, nota, prompt e metadado antigo com nome de deck), nem os IDs de usuário e de deck.

## Mutações

São 28 mutações e 37 execuções, com 0 sobreviventes:

- 26 no código, com 35 execuções (`~/.manaloom/coordenacao/deck/mutations.py kpi01`);
- 2 no schema da 073 (`draft/schema_mutants_073.py`).

Cada mutação de código foi aplicada no worktree, os testes indicados rodaram, e o arquivo
foi restaurado e conferido por hash. Cada mutação de schema subiu o banco descartável de uma
cópia com a 073 mutada e rodou o teste de banco da rota com o código sem mutação. Cada
execução listada tinha de falhar, e falhou.

| Mutação | O que muda | Derrubada por |
| --- | --- | --- |
| K1 | metadado aceita chave fora do esquema | unitário e banco |
| K2 | enumerado aceita texto livre | unitário e banco |
| K3 | campo descartado vai para o banco | unitário e banco |
| K4 | chave de idempotência gravada crua | unitário e banco |
| K5 | `deck_id` num evento que não leva deck | unitário |
| K6 | origem livre | unitário |
| K7 | inteiro fora da faixa | unitário |
| K8 | um evento do app some do catálogo | unitário e paridade com o app |
| K9 | sem conferir o dono do deck | banco |
| K10 | deck na lixeira aceito | banco |
| K11 | sem deduplicação | paridade da rota e banco |
| K12 | metadado cru gravado | banco |
| K13 | funil conta eventos | unitário e banco |
| K14 | ativação em 48 h | unitário e banco |
| K15 | volta a partir do 6º dia | unitário e banco |
| K16 | volta inclui o 14º dia | unitário e banco |
| K17 | conta excluída entra na coorte | banco |
| K18 | funil com conta excluída | banco |
| K19 | coorte recente entra como madura | banco |
| K20 | lixeira conta como ajuste de deck | banco |
| K21 | reserva de IA que falhou conta como volta | banco |
| K22 | crítico só acima do limite | unitário |
| K23 | erro de IA conta as linhas de cota | banco |
| K24 | ação de IA que falhou conta como custo | banco |
| K25 | pedido pendente do Generate conta como terminado | banco |
| K26 | taxa sem denominador vira zero | unitário |
| S1 | CHECK da 073 aceita a chave crua | banco |
| S2 | índice da deduplicação sem unicidade | banco |

## O que fica de fora

- **Raia do app**, bloqueada até as recapturas do gate:
  - parar de mandar o arquétipo livre e os IDs internos (`source_deck_id` e
    `post_game_note_id`);
  - não descartar em silêncio a recusa do servidor (`BT-KPI-002`);
  - talvez um evento de abertura do app, que mediria a volta de quem só usa o contador de
    vida.
- **Política de privacidade pública** atualizada quando a telemetria entrar (D-47), com o
  reaceite.
- **Prazo de retenção de analytics** (D-69, depois do advogado) e a correção governada das
  linhas antigas com IDs e texto livre no metadado. É escrita em produção.
- **Agregado que sobrevive à exclusão da conta.** Hoje a conta excluída sai da coorte.
- **Baseline** medida depois da primeira coorte, antes de fixar meta.
- **Coorte por lote de convite** (`BT-AUTH-006`, em outra branch). Hoje a coorte é a semana do
  cadastro.
