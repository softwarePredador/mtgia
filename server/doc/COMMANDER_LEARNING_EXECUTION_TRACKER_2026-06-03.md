# Commander Learning Execution Tracker - 2026-06-03

## Objetivo
Concentrar em um unico lugar as atividades restantes de App, Backend e Hermes para o fluxo de decks aprendidos, marcando o que ja foi concluido, o que eu consigo executar e o que depende do usuario/ambiente externo.

## Status Atual
- Backend publico esta validado com `/ai/commander-learning`.
- PG tem `commander_learned_decks` com Lorehold `learned_deck:82` ativo.
- App tem atalho condicional `Usar deck aprendido do comandante` na tela de gerar deck, exibido apenas para comandantes com deck aprendido ativo.
- Hermes ja tem export/sync recorrente, mas a politica correta e: aprender
  automaticamente e sincronizar para PG somente com gate Commander estrito.

## Atividades Que Eu Consigo Executar

| Status | Area | Atividade | Criterio de conclusao |
|---|---|---|---|
| Concluido | Backend | Criar `GET /ai/commander-learning` sem `commander` para listar comandantes com deck aprendido ativo | Endpoint retorna lista com `commander`, `deck_name`, `source_ref`, `last_synced_at`, `legal_status` |
| Concluido | Backend | Melhorar contrato de `/ai/commander-learning` | Payload inclui `win_conditions`, `role_summary`, `source_confidence`, `last_synced_at` |
| Concluido | Backend | Documentar API dedicada | Doc `COMMANDER_LEARNING_API_2026-06-03.md` criado com request, response, campos, exemplo e `available=false` |
| Concluido | Backend | Reduzir duplicacao entre `commander-reference` e `commander-learning` | Helper comum `commander_reference_helpers.dart` ja em uso sem alterar contrato publico |
| Concluido | Backend | Ampliar testes do endpoint dedicado | Testes cobrem contrato, prioridade de deck ativo e gate de importacao Commander aprendido |
| Concluido | App | Melhorar UX do botao de deck aprendido | Botao explica origem, score e legalidade antes do clique |
| Concluido | App | Mostrar origem/score/legalidade no preview | Preview exibe `Hermes`, `learned_deck:82`, score, legalidade e confianca |
| Concluido | App | Usar listagem para mostrar botao apenas quando houver deck aprendido | Tela consulta disponibilidade e evita botao inutil para comandantes sem deck ativo |
| Concluido | App | Adicionar teste widget do clique no botao | Mock confirma clique e preview com origem/score/legalidade |
| Concluido | App | Adicionar teste widget do save do deck aprendido completo | Mock confirma save payload com commander + main deck; runtime focado valida 5 comandantes |
| Concluido | Hermes | Criar script exportador JSON a partir do SQLite Hermes | `server/bin/export_hermes_learned_deck.py` gera payload aceito por `bin/commander_learned_deck.dart` |
| Concluido | Hermes | Criar wrapper de sync Hermes -> PG | `server/bin/sync_hermes_learned_deck.sh` exporta, faz dry-run estrito e aplica sob `--apply` |
| Concluido | Hermes | Preparar cron/manual job documentado | `auto_sync_learned_decks.py` roda dry-run estrito por default; apply exige `--apply` ou `HERMES_AUTO_SYNC_APPLY=1` |

## Atividades Que Dependem Do Usuario Ou Ambiente Externo

| Status | Area | Atividade | Por que depende de voce |
|---|---|---|---|
| Pendente | App | Teste visual real em device/simulador | Precisa confirmar UX visual/interacao em ambiente real; posso tentar localmente se voce autorizar tempo e possiveis bloqueios de simulator |
| Pendente | Operacao | Deploy manual via EasyPanel se deploy automatico falhar | Nao tenho SSH valido no host publico/EasyPanel; consigo validar `/health` quando o deploy ocorrer |
| Concluido | Produto | Decidir se o botao deve aparecer sempre ou so apos detectar disponibilidade | Implementado como condicional: mostrar so quando houver deck ativo |
| Concluido | Produto | Decidir se cron Hermes deve aplicar automaticamente ou exigir revisao manual | Politica aplicada: aprender automaticamente, publicar no PG apenas com gate Commander 100/99+1 e apply explicito |

## Ordem Recomendada
1. Rodar `auto_sync_learned_decks.py` em dry-run e revisar o resumo.
2. Aplicar `--apply` somente para learned decks com 100 cartas, 1 commander e 99 main.
3. Para comandante novo, validar no app/simulador se o botao aparece e o preview salva deck legal.
4. Manter Hermes gerando tasks de melhoria, mas produto muda somente no `master`.

## Como Marcar Concluido
Atualizar a coluna `Status` para `Concluido` e adicionar uma nota curta com commit, comando de validacao ou evidencia publica.

Exemplo:
```text
Concluido - commit abc123 - `flutter test ...` passou - endpoint publico validado HTTP 200
```

## Evidencias Ja Existentes
- Commit `4cf90e57`: backend expõe deck aprendido via `commander-reference`.
- Commit `9daff606`: app tem atalho inicial para deck aprendido.
- Commit `06bb644e`: rotina idempotente `commander_learned_deck.dart` criada.
- Commit `a763f15b`: endpoint dedicado `/ai/commander-learning` criado.
- Commit `0f0a40d2`: runtime focado no simulator prova disponibilidade para 5 comandantes.
- Auditoria `HERMES_APP_LEARNING_SYNC_AUDIT_2026-06-04.md`: gate Commander 100/99+1 e sync dry-run por default.
- Endpoint dedicado validado publicamente com Lorehold: 100 cartas, 99 main, legalidade valida, 0 Mox premium.
- Verificacao local desta rodada: `dart analyze` focado backend/app sem issues; `dart test test/commander_learned_deck_support_test.dart` passou; `flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart` passou.
